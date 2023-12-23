// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @dev Only mint or lookup ID for name hash.
interface IMembershipNFT {
    function mint(address to, string calldata name) external;
    function nameToId(bytes32 name) external returns (uint256);
}
/// @dev Only issue, reissue or extend.
interface IFobNFT is IERC721 {
    function issue(address to, uint256 fobNumber) external;
    function reissue(address to, uint256 fobNumber) external;
    function extend(uint256 fobNumber) external;
}

/// @title Minter
/// @author Ori Wagmi (ori-wagmi)
/// @notice Minter contract interface for Membership & Fob NFTs
contract Minter {
    IMembershipNFT public membershipNFT;
    IFobNFT public fobNFT;

    // @var Monthly fee for Fob access, whole units.
    uint256 public fobMonthly = 1 ether;
    address public multisig;

    /// @dev Initialize with interface and Admin addresses.
    /// @param _membershipNFT (address)
    /// @param _fobNFT (address)
    /// @param _multisig (address)
    constructor (address _membershipNFT, address _fobNFT, address _multisig) {
        membershipNFT = IMembershipNFT(_membershipNFT);
        fobNFT = IFobNFT(_fobNFT);
        multisig = _multisig;
    }

    /// @notice Issue a Membership NFT with name to an address.
    /// @dev Cannot issue to Admin, no name hash collision.
    /// @param to (address)
    /// @param name (string)
    function issueMembership(address to, string calldata name) external {
        require(to != multisig, "is multisig");
        require(membershipNFT.nameToId(keccak256(abi.encode(name))) == 0, "name exists");
        membershipNFT.mint(to, name);
    }

    /// @notice Mints a Membership NFT with name to the Admin account.
    /// @dev Must not be a name hash collision.
    /// @param name (string)
    function issueMembershipCustodian(string calldata name) external {
        require(membershipNFT.nameToId(keccak256(abi.encode(name))) == 0, "name exists");
        membershipNFT.mint(multisig, name);
    }

    /// @dev Must send monthly fee exact. Transfer payment to Admin.
    /// @param to (address)
    /// @param fobNumber (uint256)
    function issueFob(address to, uint256 fobNumber) external payable {
        require(msg.value == fobMonthly, "wrong amount");
        payable(multisig).transfer(msg.value);
        fobNFT.issue(to, fobNumber);
    }

    /// @notice Reissue a given Fob by token ID to an address.
    /// @dev Must be called by owner or the admin. Must send monthly fee exact. Transfer payment to Admin.
    /// @param to (address)
    /// @param fobNumber (uint256)
    function reissueFob(address to, uint256 fobNumber) external payable {
        require(msg.sender == multisig || msg.sender == fobNFT.ownerOf(fobNumber), "not owner");
        require(msg.value == fobMonthly, "wrong amount");
        payable(multisig).transfer(msg.value);
        fobNFT.reissue(to, fobNumber);
    }

    /// @notice Extend the expiry time for a given token ID.
    /// @dev Must send monthly fee exact. Transfer payment to Admin.
    /// @param fobNumber (uint256)
    function extendFob(uint256 fobNumber) external payable {
        require(msg.value == fobMonthly, "wrong amount");
        payable(multisig).transfer(msg.value);
        fobNFT.extend(fobNumber);
    }
}