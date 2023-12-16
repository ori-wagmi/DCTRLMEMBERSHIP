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
    
    constructor(address admin) ERC721("Fob", "FOB") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);    
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return idToExpiration[tokenId].toString();
    }

    function issue(address to, uint256 fobNumber) public onlyRole(MINTER_ROLE) {
        require(!_exists(fobNumber), "already exists");
        _issue(to, fobNumber);
    }

    function reissue(address to, uint256 fobNumber) public onlyRole(MINTER_ROLE) {
        _requireMinted(fobNumber);
        burn(fobNumber);
        _issue(to, fobNumber);
    }

    function extend(uint256 fobNumber) public onlyRole(MINTER_ROLE) {
        _requireMinted(fobNumber);
        idToExpiration[fobNumber] = idToExpiration[fobNumber] + 30 days;
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

    function _issue(address to, uint256 fobNumber) internal {
        idToExpiration[fobNumber] = block.timestamp + 30 days;
        _safeMint(to, fobNumber);
        emit Mint(to, fobNumber);
    }
}
