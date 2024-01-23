// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @dev Minter can mint or lookup ID for namehash.
interface IMembershipNFT {
    function mint(address to, string calldata name) external;
    function nameToId(bytes32 name) external view returns (uint256);
}

/// @dev Minter can issue, reissue, or extend.
interface IFobNFT is IERC721 {
    function reissue(address to, uint256 fobNumber, uint256 numDays) external;
    function issue(address to, uint256 fobNumber, uint256 numDays) external;
    function extend(uint256 fobNumber, uint256 numDays) external;
    function burn(uint256 fobNumber) external;
    function idToExpiration(uint256 tokenId) external view returns (uint256);
}

/// @dev Minter can create and query ERC6551 TokenBound accounts.
interface IRegistry {
    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address account);

    function account(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external view returns (address account);
}

/// @title Minter
/// @notice Minter contract interface for Membership & Fob NFTs
contract Minter {
    IMembershipNFT public membershipNFT;
    IFobNFT public fobNFT;
    IRegistry public registry;
    
    address public accountV3;
    bytes32 public salt;

    // daily fee for Fob access.
    uint256 public fobDaily = .01 ether;
    
    // Multisig
    address public paymentReceiver; 
    address public admin;

    /// @dev Initialize with 6551 implementations, contracts and Admin addresses.
    /// @param _registry (address)
    /// @param _accountV3 (address)
    /// @param _membershipNFT (address)
    /// @param _fobNFT (address)
    /// @param _paymentReceiver (address)
    /// @param _admin (address)
    /// @param _salt (bytes32) Salt for TokenBound account creation.
    constructor (
        address _registry,
        address _accountV3,
        address _membershipNFT,
        address _fobNFT,
        address _paymentReceiver,
        address _admin,
        bytes32 _salt
    ) {
        membershipNFT = IMembershipNFT(_membershipNFT);
        fobNFT = IFobNFT(_fobNFT);
        registry = IRegistry(_registry);
        accountV3 = _accountV3;
        paymentReceiver = _paymentReceiver;
        admin = _admin;
        salt = _salt;
    }

    /// @notice Issue a Membership NFT with name to an address.
    /// @dev No namehash collision allowed.
    /// @param to (address)
    /// @param name (string)
    function issueMembership(address to, string calldata name) external returns (address) {
        uint256 tokenId = membershipNFT.nameToId(keccak256(abi.encode(name)));
        require(tokenId == 0, "name exists");
        membershipNFT.mint(to, name);

        return
            registry.createAccount(
                accountV3,
                bytes32(salt),
                block.chainid,
                address(membershipNFT),
                tokenId
            );
    }

    /// @notice Get the 6551 TokenBound address from token ID.
    /// @dev Must be a valid token ID.
    /// @param tokenId (uint256)
    function getMembershipAddressById(uint256 tokenId) view external returns (address) {
        require(tokenId != 0, "token doesn't exist");
        return registry.account(
            accountV3,
            bytes32(salt),
            block.chainid,
            address(membershipNFT),
            tokenId
        );
    }

    /// @notice Get the 6551 TokenBound address from name.
    /// @dev Must be a valid name.
    /// @param name (string)
    function getMembershipAddressByName(string calldata name) view external returns (address) {
        uint256 tokenId = membershipNFT.nameToId(keccak256(abi.encode(name)));
        require(tokenId != 0, "name doesn't exists");

        return registry.account(
            accountV3,
            bytes32(salt),
            block.chainid,
            address(membershipNFT),
            tokenId
        );
    }

    /// @dev Must send daily fee exact. Dues to Multisig.
    /// @param to (address)
    /// @param fobNumber (uint256)
    /// @param numDays (uint256)
    function issueFob(address to, uint256 fobNumber, uint256 numDays) external payable {
        require(msg.value == (fobDaily * numDays), "wrong amount");
        payable(paymentReceiver).transfer(msg.value);
        fobNFT.issue(to, fobNumber, numDays);
    }

    /// @notice Helper function to burn and mint token ID in one transaction.
    /// @dev Must be called by owner or admin, fee exact. Dues to Multisig.
    /// @param to (address)
    /// @param fobNumber (uint256)
    /// @param numDays (uint256)
    function burnAndMintFob(address to, uint256 fobNumber, uint256 numDays) external payable {
        require(msg.sender == admin || msg.sender == fobNFT.ownerOf(fobNumber), "not owner");
        require(msg.value == (fobDaily * numDays), "wrong amount");
        payable(paymentReceiver).transfer(msg.value);
        fobNFT.reissue(to, fobNumber, numDays);
    }

    /// @notice Lost fob scenario. 
    /// @notice Burns old token ID and mints new token ID with same expiration.
    /// @dev Must be called by owner or admin, fee exact. Dues to Multisig.
    /// @param old_fobNumber (uint256)
    /// @param new_fobNumber (uint256)
    function transferExpirationToNewFobNumber(address to, uint256 old_fobNumber, uint256 new_fobNumber) external payable {
        require(msg.sender == admin || msg.sender == fobNFT.ownerOf(old_fobNumber), "not owner");
        uint256 remainingDays = fobNFT.idToExpiration(old_fobNumber) - block.timestamp;
        fobNFT.burn(old_fobNumber);
        fobNFT.issue(to, new_fobNumber, remainingDays);
    }


    /// @notice Extend the expiry time for a given token ID.
    /// @dev fee exact for extension period. Dues to Multisig.
    /// @param fobNumber (uint256)
    /// @param numDays (uint256)
    function extendFob(uint256 fobNumber, uint256 numDays) external payable {
        require(msg.value == (fobDaily * numDays), "wrong amount");
        payable(paymentReceiver).transfer(msg.value);
        fobNFT.extend(fobNumber, numDays);
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

    /// @notice Set new daily due rate.
    /// @dev Sender must be admin.
    /// @param _fobDaily (uint256)
    function setFobDaily(uint256 _fobDaily) external {
        require(msg.sender == admin, "not admin");
        fobDaily = _fobDaily;
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

    function set6551Details(address _registry, address _accountV3, bytes32 _salt) external {
        require(msg.sender == admin, "not admin");
        registry = IRegistry(_registry);
        accountV3 = _accountV3;
        salt = _salt;
    }
}