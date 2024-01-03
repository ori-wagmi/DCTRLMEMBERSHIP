// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract MembershipNFT is ERC721, AccessControl {
    uint256 public totalSupply = 0;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    struct nftMetadata {
        uint256 creationDate;
        string name;
    }
    mapping(uint256 => nftMetadata) public idToMetadata;
    mapping(bytes32 => uint256) public nameToId;

    address public multisig;

    event Mint(address indexed name, uint256 indexed tokenId);

    constructor(address _multisig) ERC721("Membership", "MEMBER") {
        multisig = _multisig;
        _grantRole(DEFAULT_ADMIN_ROLE, multisig);
        _grantRole(MINTER_ROLE, multisig);
        _grantRole(TRANSFER_ROLE, multisig);
    }
    
    function mint(address to, string calldata name) public onlyRole(MINTER_ROLE) {
        totalSupply += 1; // starts at 1

        idToMetadata[totalSupply] = nftMetadata(block.timestamp, name);
        nameToId[keccak256(abi.encode(name))] = totalSupply;

        _safeMint(to, totalSupply);
        emit Mint(to, totalSupply);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyRole(TRANSFER_ROLE)  {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyRole(TRANSFER_ROLE) {
        super.safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyRole(TRANSFER_ROLE) {
        super._safeTransfer(from, to, tokenId, data);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (hasRole(TRANSFER_ROLE, msg.sender) || // TRANSFER_ROLE always approved
            spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender
        );
    }

    // Transfers multisig to new address
    // Revokes DEFAULT_ADMIN_ROLE from old multisig, grants it to new multisig
    // MINTER_ROLE and TRANSFER_ROLE should be manually managed
    function setMultisig(address _multisig) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(multisig != _multisig, "already multisig");
        _grantRole(DEFAULT_ADMIN_ROLE, _multisig);
        _revokeRole(DEFAULT_ADMIN_ROLE, multisig);
        multisig = _multisig;
    }
}
