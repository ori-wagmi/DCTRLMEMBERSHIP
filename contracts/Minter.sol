// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @dev Minter can mint or lookup ID for namehash.
interface IMembershipNFT {
    function mint(address to, string calldata name) external;
    function nameToId(bytes32 name) external returns (uint256);
}
/// @dev Minter can issue, reissue or extend.
interface IFobNFT is IERC721 {
    function reissue(address to, uint256 fobNumber, uint256 months) external;
    function issue(address to, uint256 fobNumber, uint256 months) external;
    function extend(uint256 fobNumber, uint256 months) external;
}

/// @title Minter
/// @author Ori Wagmi (ori-wagmi)
/// @notice Minter contract interface for Membership & Fob NFTs
contract Minter {
    IMembershipNFT public membershipNFT;
    IFobNFT public fobNFT;
    //@var Monthly fee for Fob access.
    uint256 public fobMonthly = .1 ether;
    //@var Multisig
    address public paymentReceiver; 
    address public admin;

    /// @dev Initialize with interface and Admin addresses.
    /// @param _membershipNFT (address)
    /// @param _fobNFT (address)
    /// @param _paymentReceiver (address)
    /// @param _admin (address)
    constructor (address _membershipNFT, address _fobNFT, address _paymentReceiver, address _admin) {
        membershipNFT = IMembershipNFT(_membershipNFT);
        fobNFT = IFobNFT(_fobNFT);
        paymentReceiver = _paymentReceiver;
        admin = _admin;
    }

    /// @notice Issue a Membership NFT with name to an address.
    /// @dev Cannot issue to Admin, no namehash collision.
    /// @param to (address)
    /// @param name (string)
    function issueMembership(address to, string calldata name) external {
        require(membershipNFT.nameToId(keccak256(abi.encode(name))) == 0, "name exists");
        membershipNFT.mint(to, name);
    }

    /// @dev Must send monthly fee exact. Dues to Multisig.
    /// @param to (address)
    /// @param fobNumber (uint256)
    /// @param months (uint256)
    function issueFob(address to, uint256 fobNumber, uint256 months) external payable {
        require(msg.value == (fobMonthly * months), "wrong amount");
        payable(paymentReceiver).transfer(msg.value);
        fobNFT.issue(to, fobNumber, months);
    }

    /// @notice Reissue a given Fob by token ID to an address.
    /// @dev Must be called by owner or admin, monthly fee exact. Dues to Multisig.
    /// @param to (address)
    /// @param fobNumber (uint256)
    /// @param months (uint256)
    function reissueFob(address to, uint256 fobNumber, uint256 months) external payable {
        require(msg.sender == admin || msg.sender == fobNFT.ownerOf(fobNumber), "not owner");
        require(msg.value == (fobMonthly * months), "wrong amount");
        payable(paymentReceiver).transfer(msg.value);
        fobNFT.reissue(to, fobNumber, months);
    }

    /// @notice Extend the expiry time for a given token ID.
    /// @dev Monthly fee exact for extension period. Dues to Multisig.
    /// @param fobNumber (uint256)
    /// @param months (uint256)
    function extendFob(uint256 fobNumber, uint256 months) external payable {
        require(msg.value == (fobMonthly * months), "wrong amount");
        payable(paymentReceiver).transfer(msg.value);
        fobNFT.extend(fobNumber, months);
    }

    /** Admin functions */
    /// @notice Handoff to new admin address.
    /// @dev Sender must already be admin.
    /// @param _admin (address)
    function setAdmin(address _admin) external {
        require(msg.sender == admin, "not admin");
        admin = _admin;
    }

    /// @notice Set new receiver of member dues.
    /// @dev Sender must be admin.
    /// @param _paymentReceiver (address)
    function setPaymentReceiver(address _paymentReceiver) external {
        require(msg.sender == admin, "not admin");
        paymentReceiver = _paymentReceiver;
    }

    /// @notice Set new monthly due rate.
    /// @dev Sender must be admin.
    /// @param _fobMonthly (uint256)
    function setFobMonthly(uint256 _fobMonthly) external {
        require(msg.sender == admin, "not admin");
        fobMonthly = _fobMonthly;
    }

    /// @notice Set new membership NFT contract.
    /// @dev Sender must be admin.
    /// @param _membershipNFT (address)
    function setMembershipNFT(address _membershipNFT) external {
        require(msg.sender == admin, "not admin");
        membershipNFT = IMembershipNFT(_membershipNFT);
    }

    /// @notice Set new fob NFT contract
    /// @dev Sender must be admin.
    /// @param _fobNFT (address)
    function setFobNFT(address _fobNFT) external {
        require(msg.sender == admin, "not admin");
        fobNFT = IFobNFT(_fobNFT);
    }
}