// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

contract FobMapper {
    mapping(uint256 => uint256) public hashToNumber;
    address owner;
    
    constructor() {
        owner = msg.sender;
    }

    function add(uint256 hash, uint256 number) external {
        // require(msg.sender == owner, "only owner");
        hashToNumber[hash] = number;
    }
}