// This is the main Blockchain file contains all the logic for interacting with smart contracts
// This file re-exports the Blockchain_*.js files, callers are expected to only interact with this one
const hre = require("hardhat");
const BlockchainMembership = require("./Blockchain_Membership.js");
const BlockchainFob = require("./Blockchain_Fob.js");
const BlockchainTokenBoundAccount = require("./Blockchain_TokenBoundAccount.js");

module.exports = {
    ...BlockchainMembership,
    ...BlockchainFob,
    ...BlockchainTokenBoundAccount
}

// Deploys 6551Registry, AccountV3, Minter, Membership, and Fob contracts
// Grants `minterContract` MINTER_ROLE for Membership, and MINTER_ROLE for Fob
// Grants owner[0] (multisig) TRANSFER_ROLE for Membership, and BURNER_ROLE for Fob
module.exports.setupContracts = async function setupContracts() {
    let [owner] = await ethers.getSigners();
    const Registry = await hre.ethers.getContractFactory("ERC6551Registry");
    const registry = await Registry.deploy();
    await registry.deployed();

    const Multicall3 = await hre.ethers.getContractFactory("Multicall3");
    const forwarder = await Multicall3.deploy();
    await forwarder.deployed();

    const AccountGuardian = await hre.ethers.getContractFactory("AccountGuardian");
    const guardian = await AccountGuardian.deploy(owner.address);
    await guardian.deployed();

    const AccountV3 = await hre.ethers.getContractFactory("AccountV3");
    const implementation = await AccountV3.deploy(
        owner.address,
        forwarder.address,
        registry.address,
        guardian.address
        );
    await implementation.deployed();

    const MembershipNFT = await hre.ethers.getContractFactory("MembershipNFT");
    const membership = await MembershipNFT.deploy(owner.address);
    await membership.deployed();

    const FobNFT = await hre.ethers.getContractFactory("FobNFT");
    const fob = await FobNFT.deploy(owner.address);
    await fob.deployed();

    const Minter = await hre.ethers.getContractFactory("Minter");
    const minter = await Minter.deploy(membership.address, fob.address, owner.address);
    await minter.deployed();

    await membership.grantRole(await membership.MINTER_ROLE(), minter.address);
    await membership.grantRole(await membership.TRANSFER_ROLE(), owner.address);
    await fob.grantRole(await fob.MINTER_ROLE(), minter.address);
    await fob.grantRole(await fob.BURNER_ROLE(), minter.address);
    await fob.grantRole(await fob.BURNER_ROLE(), owner.address);

    return [minter, registry, implementation, membership, fob];
}

// Sends `amount` ether from `sender` to `receiver`
module.exports.sendEther = async function sendEther(sender, receiver, amount) {
    await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [sender],
    });
    senderSigner = await ethers.getSigner(sender);

    tx = {to: receiver, value: ethers.utils.parseEther(amount)};

    await senderSigner.sendTransaction(tx);
    console.log(`${amount} ether sent`);
}