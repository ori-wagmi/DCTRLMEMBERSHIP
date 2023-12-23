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
            address(membership),
            address(fob),
            multisig,
            admin
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
        fob.grantRole(fob.MINTER_ROLE(), admin);
        fob.grantRole(fob.MINTER_ROLE(), address(minter));
        fob.grantRole(fob.BURNER_ROLE(), admin);
        fob.grantRole(fob.BURNER_ROLE(), address(minter));
        vm.stopPrank();
    }

    function testMembershipIssue() public {
        vm.startPrank(testAddress);

        minter.issueMembership(alanah, memberName);
        assertEq(1, membership.balanceOf(alanah));

        vm.stopPrank();
    }

    function testMembershipName() public {
        testMembershipIssue();
        uint targetId = 1;

        // Check namehash corresponds to ID
        assertEq(targetId, membership.nameToId(keccak256(abi.encode(memberName))));

        (uint256 createDate, string memory metaName) = membership.idToMetadata(1);
        
        // Check retrieved metadata name is equal to namehash
        assertEq(keccak256(abi.encode(metaName)), keccak256(abi.encode(memberName)));

        // Check creation date agrees with this block.
        assertEq(createDate, block.timestamp);

        console.log("ID %d Name: %s", targetId, metaName );
        console.log("ID %d Created: %d", targetId, createDate);
        console.log("");
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
        uint fobDuesAnnual = minter.fobMonthly() * 12; 
        console.log("TBA for ID 1:", membershipTBA);
        console.log("");

        vm.startPrank(admin);

        vm.expectEmit();
        emit FobNFT.Mint(membershipTBA, tokenId);

        minter.issueFob{value: fobDuesAnnual}(membershipTBA, tokenId, 12);

        // Check timestamp
        uint expiry = fob.idToExpiration(1);
        assertNotEq(expiry, 0);
        console.log("Fob 1's Expiry: ", expiry);
        console.log("");

        vm.stopPrank();
    }

    function testFobReissue() public {
        // Setup issuance
        testFobIssue();

        address membershipTBA = calculateTBA(1);
        uint fobDuesHalfYear = minter.fobMonthly() * 6;
        uint expiry = fob.idToExpiration(1);

        // NB: Assuming 30 day months...
        assertEq(expiry, (block.timestamp + 30 days * 12));
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
        minter.reissueFob{value: fobDuesHalfYear}(membershipTBA, 1, 6);

        // Check expiration equals reissue time + 6 months
        assertEq(fob.idToExpiration(1), block.timestamp + (30 days * 6));

        vm.expectEmit();
        emit FobNFT.Burn(1);
        vm.expectEmit();
        emit FobNFT.Mint(membershipTBA, 1);

        // Scenario 2: Accidental Reissue to same TBA
        minter.reissueFob{value: fobDuesHalfYear/6}(membershipTBA, 1, 1);
        
        // Check expiration increased by 1 month
        // NB: Replaces current expiry.
        assertEq(fob.idToExpiration(1), block.timestamp + 30 days);
        vm.stopPrank();
    }

    function testFobExtend() public {
         // Setup issuance
        testFobIssue();
        uint fobFee = minter.fobMonthly();
        uint expiry = fob.idToExpiration(1);
        // Elapse time ~one block til expiry
        vm.warp(expiry - 12 seconds);

        vm.startPrank(admin);
        // Extend Fob 1 for one month
        minter.extendFob{value: fobFee}(1, 1);

        //Ensure expiry increased by 30 days
        assertEq(expiry + 30 days, fob.idToExpiration(1));

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

    /** Utilities */
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
            0, // _salt,
            chainId, // chainId,
            address(membership), // tokenContract,
            tokenId // tokenId
        );

        return(membershipTBA);
    }

    fallback() external {} 
}