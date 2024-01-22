// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract FobNFT is ERC721, AccessControl {
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    mapping(uint256 => uint256) public idToExpiration;
    event Mint(address indexed owner, uint256 indexed fobNumber);
    event Burn(uint256 indexed fobNumber);
    
    address public admin;

    constructor(address _admin) ERC721("Fob", "FOB") {
        admin = _admin;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(BURNER_ROLE, admin);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return idToExpiration[tokenId].toString();
    }

    function issue(address to, uint256 fobNumber, uint256 months) public onlyRole(MINTER_ROLE) {
        require(!_exists(fobNumber), "already exists");
        _issue(to, fobNumber, months);
    }

    function reissue(address to, uint256 fobNumber, uint256 months) public onlyRole(MINTER_ROLE) {
        _requireMinted(fobNumber);
        burn(fobNumber);
        _issue(to, fobNumber, months);
    }

    function extend(uint256 fobNumber, uint256 months) public onlyRole(MINTER_ROLE) {
        _requireMinted(fobNumber);
        idToExpiration[fobNumber] = idToExpiration[fobNumber] + (30 days * months);
    }

    function burn(uint256 fobNumber) public onlyRole(BURNER_ROLE) {
        _requireMinted(fobNumber);
        delete idToExpiration[fobNumber];
        _burn(fobNumber);
        emit Burn(fobNumber);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _issue(address to, uint256 fobNumber, uint256 months) internal {
        idToExpiration[fobNumber] = block.timestamp + (30 days * months);
        _safeMint(to, fobNumber);
        emit Mint(to, fobNumber);
    }

    // Transfers admin to new address
    // Revokes DEFAULT_ADMIN_ROLE from old admin, grants it to new admin
    // BURNER_ROLE and MINTER_ROLE should be manually managed
    function setAdmin(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(admin != _admin, "already admin");
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _revokeRole(DEFAULT_ADMIN_ROLE, admin);
        admin = _admin;
    }
}
