// This file contains all the logic for interacting with smart contracts
const hre = require("hardhat");
const Globals = require("./Globals.js");

// Issues new fob to `receiver` with tokenId = `fobNumber`, `caller` pays
module.exports.issueFob = async function issueFob(caller, receiver, fobNumber) {
    await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [caller],
    });
    callerSigner = await ethers.getSigner(caller);

    await Globals.minterContract.connect(callerSigner).issueFob(receiver, fobNumber, { value: ethers.utils.parseEther("1") });
    console.log(`Fob issued with tokenID: ${fobNumber}`);
}

// ReIssues existing fob to `receiver` with tokenId = `fobNumber`, `caller` pays
// This is the same as calling `burnFob` and `issueFob` in one transaction
module.exports.reissueFob = async function reissueFob(caller, receiver, fobNumber) {
    await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [caller],
    });
    callerSigner = await ethers.getSigner(caller);

    await Globals.minterContract.connect(callerSigner).reissueFob(receiver, fobNumber, { value: ethers.utils.parseEther("1") });
    console.log(`Fob reissued with tokenID: ${fobNumber}`);
}


// Extends existing fob, `caller` pays
module.exports.extendFob = async function extendFob(caller, fobNumber) {
    await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [caller],
    });
    callerSigner = await ethers.getSigner(caller);

    await Globals.minterContract.connect(callerSigner).extendFob(fobNumber, { value: ethers.utils.parseEther("1") });
    console.log(`Fob extended with tokenID: ${fobNumber}`);
}

// Burns existing fob
// Caller must have `BURNER_ROLE`
module.exports.burnFob = async function burnFob(caller, fobNumber) {
    await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [caller],
    });
    callerSigner = await ethers.getSigner(caller);

    await Globals.fobContract.connect(callerSigner).burn(fobNumber);
    console.log(`Fob burned with tokenID: ${fobNumber}`);
}

// Prints fob metadata
module.exports.queryFobContractById = async function queryFobContractById(id) {
    console.log(`
    Owner of fob ${id}: ${await Globals.fobContract.ownerOf(id)}
    Expiration Date of fob ${id}: ${(new Date((await Globals.fobContract.idToExpiration(id))*1000)).toString()}
    `);
}

// grants `role` to `address`
module.exports.grantRoleFob = async function grantRoleFob(role, address) {
    if (role == 1) {
        await Globals.fobContract.grantRole(await Globals.fobContract.MINTER_ROLE(), address);
    }
    else if (role == 2) {
        await Globals.fobContract.grantRole(await Globals.fobContract.BURNER_ROLE(), address);
    }
}