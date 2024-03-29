// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/// @title MembershipNFT
/// @notice Membership NFT with access control
contract MembershipNFT is ERC721, AccessControl {
    using Strings for uint256;

    // Initialize supply at zero.
    uint256 public totalSupply = 0;

    // Special roles accessing mint and transfer functions.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // Roles types for membership status.
    enum roles {
        Visitor,
        Member,
        Trusted,
        Admin,
        Banned
    }

    struct membershipMetadata {
        uint256 creationDate;
        string name;
        roles role;
    }

    // Maps a token ID to a membershipMetadata struct.
    mapping(uint256 => membershipMetadata) public idToMetadata;

    // Reserved for future use.
    struct additionalFields {
        uint256 field0;
        uint256 field1;
        string field2;
        string field3;
        bytes32 field4;
        bytes32 field5;
        address field6;
        address field7;
    }

    // Maps a token ID to a membershipMetadata struct.
    mapping(uint256 => additionalFields) public idToAdditionalFields;

    // Maps the keccak hash of name metadata to a token ID.
    mapping(bytes32 => uint256) public nameToId;

    // Multisig account.
    address public multisig;

    event Mint(address indexed name, uint256 indexed tokenId);

    /// @dev Sets the multisig account with Admin role upon initialization.
    /// @param _multisig (address)
    constructor(address _multisig) ERC721("Membership", "MEMBER") {
        multisig = _multisig;
        _grantRole(DEFAULT_ADMIN_ROLE, multisig);
        _grantRole(MINTER_ROLE, multisig);
        _grantRole(TRANSFER_ROLE, multisig);
    }
    
    /// @notice Mint a new token to an address, with a name.
    /// @dev Store timestamp and name in metadata,
    /// @dev Store namehash at tokenId, indexed from 1, mint increment supply.
    /// @param to (address)
    /// @param name (string)
    function mint(address to, string calldata name) public onlyRole(MINTER_ROLE) {
        totalSupply += 1; // tokenId starts at 1

        idToMetadata[totalSupply] = membershipMetadata(block.timestamp, name, roles.Visitor);
        nameToId[keccak256(abi.encode(name))] = totalSupply;

        _safeMint(to, totalSupply);
        emit Mint(to, totalSupply);
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
        // TRANSFER_ROLE always approved
        return (hasRole(TRANSFER_ROLE, msg.sender) || 
            spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender
        );
    }

    /// @notice Transfers multisig to new address
    /// @dev Revokes DEFAULT_ADMIN_ROLE from old multisig, grants it to new multisig
    /// @dev MINTER_ROLE and TRANSFER_ROLE are set in constructor, but should be manually managed.
    function setMultisig(address _multisig) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(multisig != _multisig, "already multisig");
        _grantRole(DEFAULT_ADMIN_ROLE, _multisig);
        _revokeRole(DEFAULT_ADMIN_ROLE, multisig);
        multisig = _multisig;
    }

    /// @notice Sets a new role for a member
    /// @dev Must be MANAGER_ROLE
    function setRole(uint256 tokenId, roles _role) public onlyRole(MANAGER_ROLE) {
        require(_exists(tokenId), "must exist");
        idToMetadata[tokenId].role = _role;
    }
    /// @notice Transfers multisig to new address
    /// @dev Must be MANAGER_ROLE
    function setName(uint256 tokenId, string calldata name) public onlyRole(MANAGER_ROLE) {
        require(_exists(tokenId), "must exist");
        idToMetadata[tokenId].name = name;
    }
    /// @notice Reserved for future use. Sets additional field for member.
    function setField0(uint256 tokenId, uint256 field0) public onlyRole(MANAGER_ROLE) {
        require(_exists(tokenId), "must exist");
        idToAdditionalFields[tokenId].field0 = field0;
    }
    /// @notice Reserved for future use. Sets additional field for member.
    function setField1(uint256 tokenId, uint256 field1) public onlyRole(MANAGER_ROLE) {
        require(_exists(tokenId), "must exist");
        idToAdditionalFields[tokenId].field1 = field1;
    }
    /// @notice Reserved for future use. Sets additional field for member.
    function setField2(uint256 tokenId, string memory field2) public onlyRole(MANAGER_ROLE) {
        require(_exists(tokenId), "must exist");
        idToAdditionalFields[tokenId].field2 = field2;
    }
    /// @notice Reserved for future use. Sets additional field for member.
    function setField3(uint256 tokenId, string memory field3) public onlyRole(MANAGER_ROLE) {
        require(_exists(tokenId), "must exist");
        idToAdditionalFields[tokenId].field3 = field3;
    }
    /// @notice Reserved for future use. Sets additional field for member.
    function setField4(uint256 tokenId, bytes32 field4) public onlyRole(MANAGER_ROLE) {
        require(_exists(tokenId), "must exist");
        idToAdditionalFields[tokenId].field4 = field4;
    }
    /// @notice Reserved for future use. Sets additional field for member.
    function setField5(uint256 tokenId, bytes32 field5) public onlyRole(MANAGER_ROLE) {
        require(_exists(tokenId), "must exist");
        idToAdditionalFields[tokenId].field5 = field5;
    }
    /// @notice Reserved for future use. Sets additional field for member.
    function setField6(uint256 tokenId, address field6) public onlyRole(MANAGER_ROLE) {
        require(_exists(tokenId), "must exist");
        idToAdditionalFields[tokenId].field6 = field6;
    }
    /// @notice Reserved for future use. Sets additional field for member.
    function setField7(uint256 tokenId, address field7) public onlyRole(MANAGER_ROLE) {
        require(_exists(tokenId), "must exist");
        idToAdditionalFields[tokenId].field7 = field7;
    }

    function checkFieldInit(uint256 tokenId, uint8 index) public view returns (bool initial) {

        // Sanity check
        require(index < 8, "Index out of range");

        additionalFields storage currentFields = idToAdditionalFields[tokenId];
        bytes32 fieldValue;

        assembly {
            // Calculate the storage slot of the field
            let fieldSlot := add(currentFields.slot, index)
            fieldValue := sload(fieldSlot)
        }

        // Normalize for multiple types
        bytes memory encoded = abi.encodePacked(fieldValue);

        // Pad out to 32 bytes
        bytes32 padded = abi.decode(encoded, (bytes32));

        if (padded != bytes32(0)) {
            return true;
        }
    }

    /// @inheritdoc ERC721
    /// @notice Given a token ID, returns its metadata.
    /// @dev Standard JSON metadata format wrapped by a data URI.
    /// @param tokenId (uint256)
    /// @return Data URI string
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return getTokenURI(tokenId);
    }

    /// @notice Given a token ID, prepare the JSON metadata string.
    /// @dev Concat all additional fields as JSON and keep packing into base64 encoding.
    /// @param tokenId (uint256)
    /// @return Data URI string
    function getTokenURI(uint256 tokenId) internal view returns (string memory) {
        string memory imageBaseURI = "ipfs://test/";

        string[8] memory valuesToPack;

        if (checkFieldInit(tokenId, 0)) valuesToPack[0] = string(abi.encodePacked('"field_0": "', idToAdditionalFields[tokenId].field0, '",'));
        else valuesToPack[0] = "";
        if (checkFieldInit(tokenId, 1)) valuesToPack[1] = string(abi.encodePacked('"field_1": "', idToAdditionalFields[tokenId].field1, '",'));
        else valuesToPack[1] = "";
        if (checkFieldInit(tokenId, 2)) valuesToPack[2] = string(abi.encodePacked('"field_2": "', idToAdditionalFields[tokenId].field2, '",'));
        else valuesToPack[2] = "";
        if (checkFieldInit(tokenId, 3)) valuesToPack[3] = string(abi.encodePacked('"field_3": "', idToAdditionalFields[tokenId].field3, '",'));
        else valuesToPack[3] = "";
        if (checkFieldInit(tokenId, 4)) valuesToPack[4] = string(abi.encodePacked('"field_4": "', idToAdditionalFields[tokenId].field4, '",'));
        else valuesToPack[4] = "";
        if (checkFieldInit(tokenId, 5)) valuesToPack[5] = string(abi.encodePacked('"field_5": "', idToAdditionalFields[tokenId].field5, '",'));
        else valuesToPack[5] = "";
        if (checkFieldInit(tokenId, 6)) valuesToPack[6] = string(abi.encodePacked('"field_6": "', idToAdditionalFields[tokenId].field6, '",'));
        else valuesToPack[6] = "";
        if (checkFieldInit(tokenId, 7)) valuesToPack[7] = string(abi.encodePacked('"field_7": "', idToAdditionalFields[tokenId].field7, '",'));
        else valuesToPack[7] = "";

        string memory fieldsConcat = string(abi.encodePacked(
            valuesToPack[0], valuesToPack[1], valuesToPack[2], valuesToPack[3], valuesToPack[4], valuesToPack[5], valuesToPack[6], valuesToPack[7]
        ));

        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name":"', idToMetadata[tokenId].name, '",',
                '"description": "DCTRL Membership token.",',
                '"image": "', imageBaseURI, tokenId.toString(), '",',
                '"external_url": "",',
                '"animation_url": "",',
                '"creation_date": "', idToMetadata[tokenId].creationDate.toString(), '",',
                fieldsConcat,
            '}'
        );
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

}
