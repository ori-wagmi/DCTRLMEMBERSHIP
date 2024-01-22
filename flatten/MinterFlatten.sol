// Sources flattened with hardhat v2.19.1 https://hardhat.org

// SPDX-License-Identifier: MIT AND UNLICENSED

// File @openzeppelin/contracts/utils/introspection/IERC165.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/IERC721.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File contracts/Minter.sol

// Original license: SPDX_License_Identifier: UNLICENSED
pragma solidity 0.8.22;
interface IMembershipNFT {
    function mint(address to, string calldata name) external;
    function nameToId(bytes32 name) external returns (uint256);
}
interface IFobNFT is IERC721 {
    function reissue(address to, uint256 fobNumber, uint256 months) external;
    function issue(address to, uint256 fobNumber, uint256 months) external;
    function extend(uint256 fobNumber, uint256 months) external;
}

contract Minter {
    IMembershipNFT public membershipNFT;
    IFobNFT public fobNFT;
    uint256 public fobMonthly = .1 ether;
    address public paymentReceiver;
    address public admin;

    constructor (address _membershipNFT, address _fobNFT, address _paymentReceiver, address _admin) {
        membershipNFT = IMembershipNFT(_membershipNFT);
        fobNFT = IFobNFT(_fobNFT);
        paymentReceiver = _paymentReceiver;
        admin = _admin;
    }

    function issueMembership(address to, string calldata name) external {
        require(membershipNFT.nameToId(keccak256(abi.encode(name))) == 0, "name exists");
        membershipNFT.mint(to, name);
    }

    function issueFob(address to, uint256 fobNumber, uint256 months) external payable {
        require(msg.value == (fobMonthly * months), "wrong amount");
        payable(paymentReceiver).transfer(msg.value);
        fobNFT.issue(to, fobNumber, months);
    }

    function reissueFob(address to, uint256 fobNumber, uint256 months) external payable {
        require(msg.sender == admin || msg.sender == fobNFT.ownerOf(fobNumber), "not owner");
        require(msg.value == (fobMonthly * months), "wrong amount");
        payable(paymentReceiver).transfer(msg.value);
        fobNFT.reissue(to, fobNumber, months);
    }

    function extendFob(uint256 fobNumber, uint256 months) external payable {
        require(msg.value == (fobMonthly * months), "wrong amount");
        payable(paymentReceiver).transfer(msg.value);
        fobNFT.extend(fobNumber, months);
    }

    /// Admin functions ///
    function setAdmin(address _admin) external {
        require(msg.sender == admin, "not admin");
        admin = _admin;
    }

    function setPaymentReceiver(address _paymentReceiver) external {
        require(msg.sender == admin, "not admin");
        paymentReceiver = _paymentReceiver;
    }

    function setFobMonthly(uint256 _fobMonthly) external {
        require(msg.sender == admin, "not admin");
        fobMonthly = _fobMonthly;
    }

    function setMembershipNFT(address _membershipNFT) external {
        require(msg.sender == admin, "not admin");
        membershipNFT = IMembershipNFT(_membershipNFT);
    }

    function setFobNFT(address _fobNFT) external {
        require(msg.sender == admin, "not admin");
        fobNFT = IFobNFT(_fobNFT);
    }
}
