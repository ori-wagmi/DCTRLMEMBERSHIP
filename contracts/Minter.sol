// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMembershipNFT {
    function mint(address to, string calldata name) external;
    function nameToId(bytes32 name) external view returns (uint256);
}

interface IFobNFT is IERC721 {
    function reissue(address to, uint256 fobNumber, uint256 months) external;
    function issue(address to, uint256 fobNumber, uint256 months) external;
    function extend(uint256 fobNumber, uint256 months) external;
} 

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

contract Minter {
    IMembershipNFT public membershipNFT;
    IFobNFT public fobNFT;
    IRegistry public registry;
    address public accountV3;
    bytes32 public salt;

    uint256 public fobMonthly = .1 ether;
    address public paymentReceiver;
    address public admin;

    constructor(
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

    function issueMembership(
        address to,
        string calldata name
    ) external returns (address) {
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
