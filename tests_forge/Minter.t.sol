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
    address roleMemberAdmin;
    address roleHaver;
    address testAddress;

    address alanah;
    address benny;
    address jayden;
    string memberName = "Alanah";

    function setUp() public {
        //Fork Mainnet
        vm.createSelectFork(vm.envString("RPC_URL_MAINNET"));

        //Canonical ERC-6551 Registry on Mainnet
        registry = 0x000000006551c19487814612e58FE06813775758;

        //Default AccountV3Upgradeable Implementation on Mainnet
        accountImpl = 0x41C8f39463A868d3A88af00cd0fe7102F30E44eC;
        
        //EOAs/Signers
        multisig = roleMemberAdmin = vm.addr(1);
        roleHaver = vm.addr(2);
        alanah = vm.addr(3);
        benny = vm.addr(4);

        //Fund
        vm.deal(multisig, 10 ether);
        vm.deal(roleHaver, 10 ether); //EOA Admin
        vm.deal(alanah, 10 ether);
        vm.deal(benny, 10 ether);

        //@dev Multisig/Admin is deployer.
        vm.startPrank(roleMemberAdmin);

        //@dev Multisig assigned DEFAULT_ADMIN_ROLE in constructors.
        //@dev Minter is entrypoint for membership, fob.
        //Contracts
        membership = new MembershipNFT(multisig);
        fob = new FobNFT(multisig);
        minter = new Minter(
            address(membership),
            address(fob),
            multisig
        );
        testAddress = address(this);

        console.log("Minter: ", address(minter));
        console.log("");

        setUpRoles();
        vm.stopPrank();
    }

    //@dev Grant necessary AccessControl Roles
    function setUpRoles() public {
        membership.grantRole(membership.MINTER_ROLE(), address(minter));
        membership.grantRole(membership.MINTER_ROLE(), roleHaver);
        membership.grantRole(membership.TRANSFER_ROLE(), roleHaver);
        fob.grantRole(fob.MINTER_ROLE(), roleHaver);
        fob.grantRole(fob.MINTER_ROLE(), address(minter));
        fob.grantRole(fob.BURNER_ROLE(), roleHaver);
        fob.grantRole(fob.BURNER_ROLE(), address(minter));
    }

    function testAccountsRoles() public view {
        console.log("***** Accounts ******");
        console.log("This contract: ", testAddress);
        console.log("Multisig/MemberAdmin: ", multisig);
        console.log("roleHaver: ", roleHaver);
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

    function testMembershipIssue() public {
        vm.startPrank(testAddress);

        minter.issueMembership(alanah, memberName);
        assertEq(1, membership.balanceOf(alanah));

        vm.stopPrank();
    }

    function testMembershipIssueCustody() public {
        vm.startPrank(roleMemberAdmin);

        assertEq(0, membership.balanceOf(multisig));
        minter.issueMembershipCustodian("Benny");
        assertEq(1, membership.balanceOf(multisig));

        vm.stopPrank();
    }

    function testMembershipName() public {
        testMembershipIssue();

        assertEq(0, membership.nameToId(keccak256(abi.encode(memberName))));

        (uint256 createDate, string memory metaName) = membership.idToMetadata(0);
        console.log("ID 0 Name: ", metaName );
        console.log("ID 0 Created: ", createDate);
        console.log("");
    }
    function testMembershipTransfer() public {
        testMembershipIssue();

        // @dev Attempt standard transfer Membership ID 0 as normal owner
        vm.startPrank(alanah);
        assertEq(0, membership.balanceOf(benny));
        // @dev Lacks Transferer Role
        vm.expectRevert();
        membership.transferFrom(alanah, benny, 0);
        assertEq(0, membership.balanceOf(benny));
        vm.stopPrank();

        // Attempt transfer as multisig
        vm.startPrank(multisig);
        assertEq(0, membership.balanceOf(benny));
        // @dev Lacks Transferer Role
        vm.expectRevert();
        membership.transferFrom(alanah, benny, 0);
        assertEq(0, membership.balanceOf(benny));
        vm.stopPrank();

        // Attempt transfer again as roleHaver
        // Requires approval.
        vm.prank(alanah);
        membership.approve(roleHaver, 0);
    
        assertEq(0, membership.balanceOf(benny));
        // @dev Has Transferer Role
        vm.prank(roleHaver);
        membership.transferFrom(alanah, benny, 0);
        assertEq(1, membership.balanceOf(benny));
    }

    function testFobIssue() public {
        //Prepare Membership NFT
        testMembershipIssue();
        uint tokenId = membership.nameToId(keccak256(abi.encode(memberName)));

        //@todo Does frontend handle selecting fob tokenID (fobNumber)?
        address membershipTBA = calculateTBA(0);
        uint fobFee = minter.fobMonthly();
        console.log("TBA for ID 0:", membershipTBA);
        console.log("");

        vm.startPrank(roleHaver);

        vm.expectEmit();
        emit FobNFT.Mint(membershipTBA, tokenId);

        minter.issueFob{value: fobFee}(membershipTBA, tokenId);

        //check timestamp
        uint expiry = fob.idToExpiration(0);
        assertNotEq(expiry, 0);
        //console.log("Expiry timestamp: ", expiry);

        vm.stopPrank();
    }

    function testFobReissue() public {
        //Setup issuance
        testFobIssue();

        address membershipTBA = calculateTBA(0);
        uint fobFee = minter.fobMonthly();
        uint expiry = fob.idToExpiration(0);
        console.log("TBA for ID 0:", membershipTBA);
        console.log("");

        //Scenario 1: Expired
        //Elapse time ~one block after expiry
        vm.warp(expiry + 13 seconds);
        vm.startPrank(multisig);

        vm.expectEmit();
        emit FobNFT.Burn(0);
        vm.expectEmit();
        emit FobNFT.Mint(membershipTBA, 0);

        //Reissue with fee
        minter.reissueFob{value: fobFee}(membershipTBA, 0);

        assertGt(fob.idToExpiration(0), expiry + 13);

        vm.expectEmit();
        emit FobNFT.Burn(0);
        vm.expectEmit();
        emit FobNFT.Mint(membershipTBA, 0);

        //Scenario 2: Accidental Reissue
        minter.reissueFob{value: fobFee}(membershipTBA, 0);
        
        vm.stopPrank();
    }

    function testFobExtend() public {
         //Setup issuance
        testFobIssue();
        uint fobFee = minter.fobMonthly();
        uint expiry = fob.idToExpiration(0);
        //Elapse time ~one block til expiry
        vm.warp(expiry - 13 seconds);

        vm.startPrank(roleHaver);
        minter.extendFob{value: fobFee}(0);
        assertLt(expiry, fob.idToExpiration(0));

        vm.stopPrank();
    }

    function testFobBurn() public {
        testFobIssue();
        
        address membershipTBA = calculateTBA(0);
        assertEq(1, fob.balanceOf(membershipTBA));

        vm.startPrank(roleHaver);
        fob.burn(0);

        assertEq(0, fob.balanceOf(membershipTBA));

        vm.stopPrank();
    }

    function calculateTBA(uint tokenId) public view returns(address) {
        // Calculate TBA
        address membershipTBA = ERC6551AccountLib.computeAddress(
            address(registry), //registry, 
            address(accountImpl), //_implementation,
            0, //_salt,
            1, //chainId,
            address(membership), //tokenContract,
            tokenId //tokenId
        );

        return(membershipTBA);
    }

    fallback() external {} 
}