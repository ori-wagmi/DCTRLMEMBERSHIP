// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/// @title FobNFT
/// @notice Fob NFT with access control
contract FobNFT is ERC721, AccessControl {
    using Strings for uint256;

    // Special roles for accessing mint, burn functions.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // Map a token ID to an expiration number.
    mapping(uint256 => uint256) public idToExpiration;

    // Standard events
    event Mint(address indexed owner, uint256 indexed fobNumber);
    event Burn(uint256 indexed fobNumber);
    
    address public admin;

    /// @dev Grants Default Admin, Minter, and Burner role to address upon initialization.
    /// @param _admin (address)
    constructor(address _admin) ERC721("Fob", "FOB") {
        admin = _admin;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(BURNER_ROLE, admin);
    }

    /// @notice Given a token ID, returns the expiry timestamp.
    /// @dev Expiry as string, not protocol prefix as required for URI.
    /// @param tokenId (uint256)
    /// @return Timestamp as string.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return idToExpiration[tokenId].toString();
    }

    /// @notice Mint a new token ID for `numDays`.
    /// @dev Must be non-existant ID. Minter role only.
    /// @param to (adddress)
    /// @param fobNumber (uint256)
    /// @param numDays (uint256)
    function issue(address to, uint256 fobNumber, uint256 numDays) public onlyRole(MINTER_ROLE) {
        require(!_exists(fobNumber), "already exists");
        _issue(to, fobNumber, numDays);
    }

    /// @notice Burn and re-mint a given token ID for `numDays`.
    /// @dev Must be an existing ID. Minter role only.
    /// @param to (address)
    /// @param fobNumber (uint256)
    /// @param numDays (uint256)
    function reissue(address to, uint256 fobNumber, uint256 numDays) public onlyRole(MINTER_ROLE) {
        _requireMinted(fobNumber);
        burn(fobNumber);
        _issue(to, fobNumber, numDays);
    }

    /// @notice Extend the expiry time for a given token ID in day incremenets.
    /// @dev Must be an existing ID, adds numDays to expiry. Minter role only.
    /// @param fobNumber (uint256)
    /// @param numDays (uint256)
    function extend(uint256 fobNumber, uint256 numDays) public onlyRole(MINTER_ROLE) {
        _requireMinted(fobNumber);
        idToExpiration[fobNumber] = idToExpiration[fobNumber] + (1 days * numDays);
    }

    /// @notice Destroy a given token ID.
    /// @dev Must be an existing ID, delete it, call _burn, emit burn event. Burner role only.
    /// @param fobNumber (uint256)
    function burn(uint256 fobNumber) public onlyRole(BURNER_ROLE) {
        _requireMinted(fobNumber);
        delete idToExpiration[fobNumber];
        _burn(fobNumber);
        emit Burn(fobNumber);
    }

    /// @inheritdoc ERC721
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Issue a new token with an expiration.
    /// @dev Internal mint function, add numDays to .
    /// @param to (address)
    /// @param fobNumber (uint256)
    /// @param numDays (uint256)
    function _issue(address to, uint256 fobNumber, uint256 numDays) internal {
        idToExpiration[fobNumber] = block.timestamp + (1 days * numDays);
        _safeMint(to, fobNumber);
        emit Mint(to, fobNumber);
    }

    /// @notice Set a new admin.
    /// @dev Grants DEFAULT_ADMIN_ROLE to new admin, revokes old.
    /// @dev Sender must already have DEFAULT_ADMIN_ROLE and be admin.
    /// @param _admin (address)
    function setAdmin(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(admin != _admin, "already admin");
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _revokeRole(DEFAULT_ADMIN_ROLE, admin);
        admin = _admin;
    }
}
