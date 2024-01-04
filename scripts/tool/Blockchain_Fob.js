// This file contains all the logic for interacting with smart contracts
const hre = require("hardhat");
const Globals = require("./Globals.js");

// Issues new fob to `receiver` with tokenId = `fobNumber` for `months`, `caller` pays
module.exports.issueFob = async function issueFob(caller, receiver, fobNumber, months) {
    await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [caller],
    });
    callerSigner = await ethers.getSigner(caller);

    let payment = (await Globals.minterContract.fobMonthly()).mul(months).toString();
    await Globals.minterContract.connect(callerSigner).issueFob(receiver, fobNumber, months, { value: payment });
    console.log(`Paid ${ethers.utils.formatEther(payment)} ether to issue Fob ${fobNumber} for ${months} months`);
}

// ReIssues existing fob to `receiver` with tokenId = `fobNumber` for `months`, `caller` pays
// This is the same as calling `burnFob` and `issueFob` in one transaction
module.exports.reissueFob = async function reissueFob(caller, receiver, fobNumber, months) {
    await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [caller],
    });
    callerSigner = await ethers.getSigner(caller);

    let payment = (await Globals.minterContract.fobMonthly()).mul(months).toString();
    await Globals.minterContract.connect(callerSigner).reissueFob(receiver, fobNumber, months, { value: payment });
    console.log(`Paid ${ethers.utils.formatEther(payment)} ether to reissue Fob ${fobNumber} for ${months} months`);
}


// Extends existing fob for `months`, `caller` pays
module.exports.extendFob = async function extendFob(caller, fobNumber, months) {
    await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [caller],
    });
    callerSigner = await ethers.getSigner(caller);

    let payment = (await Globals.minterContract.fobMonthly()).mul(months).toString();
    await Globals.minterContract.connect(callerSigner).extendFob(fobNumber, months, { value: payment });
    console.log(`Paid ${ethers.utils.formatEther(payment)} ether to extend Fob ${fobNumber} for ${months} months`);
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
    TokenUri of fob ${id}: ${await Globals.fobContract.tokenURI(id)}
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