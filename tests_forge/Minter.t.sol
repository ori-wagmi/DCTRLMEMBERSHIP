// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "@erc6551/ERC6551Registry.sol";
import "@erc6551/lib/ERC6551AccountLib.sol";
import "contracts/FobNFT.sol";
import "contracts/MembershipNFT.sol";
import "contracts/Minter.sol";

contract MinterTest is Test {
    address registry;
    address accountImpl;
    bytes32 salt;
    MembershipNFT membership;
    FobNFT fob;
    Minter minter;
    
    address multisig;
    address admin;
    address testAddress;

    address alanah;
    address benny;
    address jayden;
    string memberName = "Alanah";

    function setUp() public {
        // Fork Mainnet
        vm.createSelectFork(vm.envString("RPC_NODE_URL"));

        // Canonical ERC-6551 Registry on Mainnet
        registry = vm.envAddress("REGISTRY_6551");

        // Default AccountV3Upgradeable Implementation on Mainnet
        accountImpl = vm.envAddress("ACCOUNT_6551");

        salt = 0;
        
        // EOAs/Signers
        multisig = vm.addr(1);
        admin = vm.addr(2);
        alanah = vm.addr(3);
        benny = vm.addr(4);

        // Fund
        vm.deal(multisig, 10 ether);
        // EOA Admin
        vm.deal(admin, 10 ether);
        vm.deal(alanah, 10 ether);
        vm.deal(benny, 10 ether);

        // Admin is deployer.
        vm.startPrank(admin);

        // Contracts
        // Multisig assigned DEFAULT_ADMIN_ROLE in constructors.
        // Minter is entrypoint for membership, fob.
        membership = new MembershipNFT(multisig);
        fob = new FobNFT(multisig);
        minter = new Minter(
            address(registry),
            address(accountImpl),
            address(membership),
            address(fob),
            multisig,
            admin,
            salt
        );
        testAddress = address(this);

        console.log("Minter: ", address(minter));
        console.log("");

        vm.stopPrank();
        setUpRoles();
    }

    //@dev Bestow AccessControl Roles to admin & Minter contract, except Transferer
    function setUpRoles() public {
        vm.startPrank(multisig);
        membership.grantRole(membership.MINTER_ROLE(), address(minter));
        membership.grantRole(membership.MINTER_ROLE(), admin);
        //membership.grantRole(membership.TRANSFER_ROLE(), admin);
        membership.grantRole(membership.MANAGER_ROLE(), admin);
        fob.grantRole(fob.MINTER_ROLE(), admin);
        fob.grantRole(fob.MINTER_ROLE(), address(minter));
        fob.grantRole(fob.BURNER_ROLE(), admin);
        fob.grantRole(fob.BURNER_ROLE(), address(minter));
        vm.stopPrank();
    }

    function testMembershipIssue() public {
        vm.startPrank(testAddress);

        // Issue Membership NFT
        minter.issueMembership(alanah, memberName);
        assertEq(1, membership.balanceOf(alanah));

        // Check membership metadata is correct
        (uint256 creationDate, string memory name, MembershipNFT.roles role) = membership.idToMetadata(1);

        assertEq(name, memberName);
        assertEq(creationDate, block.timestamp);
        assertEq(uint(role), uint(MembershipNFT.roles.Visitor));

        console.log("Role was: %d", uint(role));
        vm.stopPrank();
    }

    function testMembershipName() public {
        testMembershipIssue();
        uint targetId = 1;

        // Check namehash corresponds to ID
        assertEq(targetId, membership.nameToId(keccak256(abi.encode(memberName))));

        (uint256 createDate, string memory metaName, MembershipNFT.roles role) = membership.idToMetadata(1);
        
        // Check retrieved metadata name is equal to namehash
        assertEq(keccak256(abi.encode(metaName)), keccak256(abi.encode(memberName)));

        // Check creation date agrees with this block.
        assertEq(createDate, block.timestamp);

        console.log("ID %d Name: %s", targetId, metaName );
        console.log("ID %d Created: %d", targetId, createDate);
        console.log("");
    }

    function testMembershipAddtionalFields() public {
        testMembershipIssue();

        // Has Manager Role
        vm.prank(admin);

        // Set field2 value for tokenId 1
        string memory field2Test = "field 2 test";
        membership.setField2(1, field2Test);

        // Check for defaults elsewhere
        assertFalse(membership.checkFieldInit(1, 1));
        assertTrue(membership.checkFieldInit(1, 2));
        assertFalse(membership.checkFieldInit(1, 3));

        // Get it back as tuple and isolate.
        (uint _field0, uint _field1, string memory _field2, string memory _field3, bytes32 _field4, bytes32 _field5, address _field6, address _field7 ) = membership.idToAdditionalFields(1);

        //Check string field value output.
        assertEq(field2Test, _field2);

        //Log the token URI data for validation.
        console.log(membership.tokenURI(1));
    }

    function testMembershipTransfer() public {
        testMembershipIssue();

        // Attempt standard transfer Membership ID 1 as normal owner
        vm.startPrank(alanah);
        assertEq(0, membership.balanceOf(benny));
        // Expect failure, lack Transferer Role
        vm.expectRevert();
        // Transfer Membership ID 1
        membership.transferFrom(alanah, benny, 1);
        assertEq(0, membership.balanceOf(benny));
        vm.stopPrank();

        // Attempt transfer as admin, expect only Multisig to be able to clawback NFTs
        vm.startPrank(admin);
        assertEq(0, membership.balanceOf(benny));
        // Expect failure, lacks Transferer Role
        vm.expectRevert();
        membership.transferFrom(alanah, benny, 1);
        assertEq(0, membership.balanceOf(benny));
        vm.stopPrank();

        // Attempt transfer again as approved spender
        vm.prank(alanah);
        membership.approve(admin, 1);
    
        assertEq(0, membership.balanceOf(benny));
        vm.prank(admin);
        // Expect failure, lacks Transferer Role
        vm.expectRevert();
        membership.transferFrom(alanah, benny, 1);
        assertEq(0, membership.balanceOf(benny));

        // Attempt as multisig, sole Transferer
        vm.prank(multisig);
        membership.transferFrom(alanah, benny, 1);
        assertEq(1, membership.balanceOf(benny));
    }

    function testFobIssue() public {
        // Prepare Membership NFT
        testMembershipIssue();
        uint tokenId = membership.nameToId(keccak256(abi.encode(memberName)));
        console.log("Fob Number issued: ", tokenId);

        // Frontend handles Fob ID selection.
        address membershipTBA = calculateTBA(1);
        uint fobDuesMonthly = minter.fobDaily() * 30; 
        console.log("TBA for ID 1:", membershipTBA);
        console.log("");

        vm.startPrank(admin);

        vm.expectEmit();
        emit FobNFT.Mint(membershipTBA, tokenId);

        minter.issueFob{value: fobDuesMonthly}(membershipTBA, tokenId, 30);

        // Check timestamp
        uint expiry = fob.idToExpiration(1);
        assertEq(expiry, block.timestamp + 30 days);
        console.log("Fob 1's Expiry: ", expiry);
        console.log("");

        vm.stopPrank();
    }

    function testFobReissue() public {
        // Setup issuance
        testFobIssue();

        address membershipTBA = calculateTBA(1);
        uint fobsDue60Days = minter.fobDaily() * 60;
        uint expiry = fob.idToExpiration(1);

        // NB: Assuming 30 day months...
        assertEq(expiry, (block.timestamp + 30 days));
        console.log("TBA for ID 1:", membershipTBA);
        console.log("");

        // Scenario 1: Expired
        // Elapse time ~one block after expiry
        vm.warp(expiry + 12 seconds);
        vm.startPrank(admin);

        vm.expectEmit();
        emit FobNFT.Burn(1);
        vm.expectEmit();
        emit FobNFT.Mint(membershipTBA, 1);

        // Reissue for 6 months
        minter.burnAndMintFob{value: fobsDue60Days}(membershipTBA, 1, 60);

        // Check expiration equals reissue time + 6 months
        assertEq(fob.idToExpiration(1), block.timestamp + (60 days));

        vm.expectEmit();
        emit FobNFT.Burn(1);
        vm.expectEmit();
        emit FobNFT.Mint(membershipTBA, 1);

        // Scenario 2: Accidental Reissue to same TBA
        minter.burnAndMintFob{value: minter.fobDaily()}(membershipTBA, 1, 1);
        
        // Check expiration increased by 1 month
        // NB: Replaces current expiry.
        assertEq(fob.idToExpiration(1), block.timestamp + 1 days);
        vm.stopPrank();
    }

    function testFobExtend() public {
         // Setup issuance
        testFobIssue();
        uint fobFee = minter.fobDaily();
        uint expiry = fob.idToExpiration(1);
        // Elapse time ~one block til expiry
        vm.warp(expiry - 12 seconds);

        vm.startPrank(admin);
        // Extend Fob 1 for 30 days
        minter.extendFob{value: fobFee}(1, 1);

        //Ensure expiry increased 1 days
        assertEq(expiry + 1 days, fob.idToExpiration(1));

        vm.stopPrank();
    }

    function testFobBurn() public {
        testFobIssue();
        
        address membershipTBA = calculateTBA(1);
        assertEq(1, fob.balanceOf(membershipTBA));

        vm.startPrank(admin);
        fob.burn(1);

        assertEq(0, fob.balanceOf(membershipTBA));

        vm.stopPrank();
    }

    /** Utilities 
     *  Set visiblity to public to print.
     */
    function testAccountsRoles() internal view {
        console.log("***** Accounts ******");
        console.log("This contract: ", testAddress);
        console.log("Multisig: ", multisig);
        console.log("admin: ", admin);
        console.log("alanah: ", alanah);
        console.log("benny: ", benny);
        console.log("");

        console.log("***** Roles ******");
        console.log("Membership MINTER_ROLE: ");
        console.logBytes32(membership.MINTER_ROLE());
        console.log("Membership TRANSFER_ROLE: ");
        console.logBytes32(membership.TRANSFER_ROLE());
        console.log("Membership MANAGER_ROLE: ");
        console.logBytes32(membership.MANAGER_ROLE());
        console.log("Fob MINTER_ROLE: ");
        console.logBytes32(fob.MINTER_ROLE());
        console.log("Fob BURNER_ROLE: ");
        console.logBytes32(fob.BURNER_ROLE());
        console.log("");
    }

    function calculateTBA(uint tokenId) public view returns(address) {
        // Calculate TBA
        uint256 chainId = vm.envUint("CHAIN_ID");
        address membershipTBA = ERC6551AccountLib.computeAddress(
            address(registry), // registry, 
            address(accountImpl), // _implementation,
            salt, // _salt,
            chainId, // chainId,
            address(membership), // tokenContract,
            tokenId // tokenId
        );

        return(membershipTBA);
    }

    fallback() external {} 
}