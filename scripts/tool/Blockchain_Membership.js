const hre = require("hardhat");
const Globals = require("./Globals.js");

// Self-custody
// Mints membershipNFT to receiver with {owner: 'name'} 
// Does not TokenBound
// returns tokenId
module.exports.issueMembership = async function issueMembership(receiver, name) {
    await Globals.minterContract.issueMembership(receiver, name);
    let mintedTokenId = await Globals.membershipContract.totalSupply();
    console.log(`Membership minted to ${receiver} with tokenId ${mintedTokenId}`);
    return mintedTokenId;
}

// Custodian
// Mints membershipNFT to admin with {owner: 'name'}
// Does not TokenBound
// returns tokenId
module.exports.issueMembershipCustodian = async function issueMembershipCustodian(name) {
    await Globals.minterContract.issueMembership(await Globals.minterContract.admin(), name);
    let mintedTokenId = await Globals.membershipContract.totalSupply();
    console.log("Membership minted to multisig with tokenId: " + mintedTokenId)
    return mintedTokenId;
}

// TokenBounds the membershipNFT
// returns TokenBound Account address
module.exports.registryCreateAccount = async function registryCreateAccount(id) {
    await Globals.registryContract.createAccount(
        Globals.accountContract.address,              // accountV3 address
        hre.ethers.utils.formatBytes32String("0"),  // salt
        hre.network.config.chainId,                 // current chainId
        Globals.membershipContract.address,           // membershipNFT address
        id);                                        // tokenId

    let accountAddress = await Globals.registryContract.account(
        Globals.accountContract.address,
        hre.ethers.utils.formatBytes32String("0"),
        hre.network.config.chainId,
        Globals.membershipContract.address,
        id);

    console.log("TokenBound Account address: " + accountAddress);
    return accountAddress;
}

// Transfers membership NFT
module.exports.transferMembership = async function transferMembership(caller, from, to, id) {
    await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [caller],
    });
    callerSigner = await ethers.getSigner(caller);

    await Globals.membershipContract.connect(callerSigner).transferFrom(from, to, id);
}

// Prints memebership metadata
module.exports.queryMembershipContract = async function queryMembershipContract(query, isOwner) {
    let tokenId = query;
    if (isOwner) {
        let ownerEncoded = hre.ethers.utils.keccak256(hre.ethers.utils.defaultAbiCoder.encode(["string"], [query]));
        tokenId = await Globals.membershipContract.nameToId(ownerEncoded);
        console.log(`\tEncoded bytes of "${query}": ${ownerEncoded}`);
        console.log(`\tTokenId of owner "${query}": ${tokenId}`);
    }

    let [creationDate, owner] = await Globals.membershipContract.idToMetadata(tokenId);
    console.log(`\tOwner of token ${tokenId}: ${await Globals.membershipContract.ownerOf(tokenId)}
    \tMetadata of token ${tokenId}: 
    \t\tCreation Date: ${(new Date(creationDate*1000)).toString()}
    \t\tOwner: ${owner}`);
}

// grants `role` to `address`
module.exports.grantRoleMembership = async function grantRoleMembership(role, address) {
    if (role == 1) {
        await Globals.membershipContract.grantRole(await Globals.membershipContract.MINTER_ROLE(), address);
    }
    else if (role == 2) {
        await Globals.membershipContract.grantRole(await Globals.membershipContract.TRANSFER_ROLE(), address);
    }
}