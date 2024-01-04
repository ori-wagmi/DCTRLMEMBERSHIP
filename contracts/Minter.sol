// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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