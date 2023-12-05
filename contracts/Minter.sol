// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMembershipNFT {
    function mint(address to, string calldata name) external;
    function nameToId(bytes32 name) external returns (uint256);
}
interface IFobNFT is IERC721 {
    function reissue(address to, uint256 fobNumber) external;
    function issue(address to, uint256 fobNumber) external;
    function extend(uint256 fobNumber) external;
}

contract Minter {
    IMembershipNFT public membershipNFT;
    IFobNFT public fobNFT;
    uint256 public fobMonthly = 1 ether;
    address public multisig;

    constructor (address _membershipNFT, address _fobNFT, address _multisig) {
        membershipNFT = IMembershipNFT(_membershipNFT);
        fobNFT = IFobNFT(_fobNFT);
        multisig = _multisig;
    }

    function issueMembership(address to, string calldata name) external {
        require(to != multisig, "is multisig");
        require(membershipNFT.nameToId(keccak256(abi.encode(name))) == 0, "name exists");
        membershipNFT.mint(to, name);
    }

    function issueMembershipCustodian(string calldata name) external {
        require(membershipNFT.nameToId(keccak256(abi.encode(name))) == 0, "name exists");
        membershipNFT.mint(multisig, name);
    }

    function issueFob(address to, uint256 fobNumber) external payable {
        require(msg.value == fobMonthly, "wrong amount");
        payable(multisig).transfer(msg.value);
        fobNFT.issue(to, fobNumber);
    }

    function reissueFob(address to, uint256 fobNumber) external payable {
        require(msg.sender == multisig || msg.sender == fobNFT.ownerOf(fobNumber), "not owner");
        require(msg.value == fobMonthly, "wrong amount");
        payable(multisig).transfer(msg.value);
        fobNFT.reissue(to, fobNumber);
    }

    function extendFob(uint256 fobNumber) external payable {
        require(msg.value == fobMonthly, "wrong amount");
        payable(multisig).transfer(msg.value);
        fobNFT.extend(fobNumber);
    }
}