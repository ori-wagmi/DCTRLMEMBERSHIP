// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/// @title MembershipNFT
/// @author Ori Wagmi (ori-wagmi)
/// @notice Membership NFT with access control
contract MembershipNFT is ERC721, AccessControl {

    // @var Init supply at zero.
    uint256 public totalSupply = 0;

    // @var Special roles for mint, transfer access.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    struct nftMetadata {
        uint256 creationDate;
        string name;
    }
    // @var Maps a token ID to a metadat struct.
    mapping(uint256 => nftMetadata) public idToMetadata;

    // @var Maps bytes to a token ID.
    mapping(bytes32 => uint256) public nameToId;

    // @var The multisig account.
    address public multisig;

    // Standard events
    event Mint(address indexed name, uint256 indexed tokenId);

    /// @dev Sets the multisig account with Admin role upon initialization.
    /// @param _multisig (address)
    constructor(address _multisig) ERC721("Membership", "MEMBER") {
        multisig = _multisig;
        _grantRole(DEFAULT_ADMIN_ROLE, multisig);
    }
    
    /// @notice Mint a new token to an address, with a name.
    /// @dev Store metadata, set name-hash to token ID, mint, emit, increment supply.
    /// @param to (address)
    /// @param name (string)
    function mint(address to, string calldata name) public onlyRole(MINTER_ROLE) {
        idToMetadata[totalSupply] = nftMetadata(block.timestamp, name);
        // @todo check-effects-interactions
        nameToId[keccak256(abi.encode(name))] = totalSupply;

        _safeMint(to, totalSupply);
        emit Mint(to, totalSupply);
        totalSupply += 1;
    }

    /// @inheritdoc ERC721
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @inheritdoc ERC721
    /// @dev Transfer role only.
    function transferFrom(address from, address to, uint256 tokenId) public override onlyRole(TRANSFER_ROLE)  {
        super.transferFrom(from, to, tokenId);
    }
    
    /// @inheritdoc ERC721
    /// @dev Transfer role only.
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyRole(TRANSFER_ROLE) {
        super.safeTransferFrom(from, to, tokenId, "");
    }

    /// @inheritdoc ERC721
    /// @notice Transfer with arbitrary bytes.
    /// @dev Transfer role only.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyRole(TRANSFER_ROLE) {
        super._safeTransfer(from, to, tokenId, data);
    }

    /// @notice Check an addresss for ownership or operator approval.
    /// @dev `multisig` address is always approved
    /// @param spender (address), tokenId (uint256)
    /// @return flag (bool), returns true if msg.sender is Admin (multisig), spender is equivalent to owner, owner carries contract approval or spender carries token approval.
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (msg.sender == multisig ||
            spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender
        );
    }
}
