// This file contains all the logic for interacting with smart contracts
const hre = require("hardhat");
const Globals = require("./Globals.js");

// As TokenBound
// Issues new fob to `receiver` for `months` as TokenBound `account` as `caller`
// Expected caller is owner of TokenBound Account
// `isCallerPay` determines who is paying for the fob (caller vs. account)
module.exports.issueFobAsTokenBound = async function issueFobAsTokenBound(account, caller, receiver, fobNumber, months, isCallerPay) {
    let payment = (await Globals.minterContract.fobMonthly()).mul(months).toString();
    let encodedWithSignature = (Globals.minterContract.interface).encodeFunctionData('issueFob', [receiver, fobNumber, months]);
    await executeAsTokenBound(account, caller, payment, isCallerPay, encodedWithSignature, Globals.minterContract.address);
    console.log(`Paid ${ethers.utils.formatEther(payment)} ether to issue Fob ${fobNumber} for ${months} months`);
}

// As TokenBound
// Extends existing fob for `months` as TokenBound `account` as `caller`
// Expected caller is owner of TokenBound Account
// `isCallerPay` determines who is paying for the extension (caller vs. account)
module.exports.extendFobAsTokenBound = async function extendFobAsTokenBound(account, caller, fobNumber, months, isCallerPay) {
    let payment = (await Globals.minterContract.fobMonthly()).mul(months).toString();
    let encodedWithSignature = (Globals.minterContract.interface).encodeFunctionData('extendFob', [fobNumber, months]);
    await executeAsTokenBound(account, caller, payment, isCallerPay, encodedWithSignature, Globals.minterContract.address);
    console.log(`Paid ${ethers.utils.formatEther(payment)} ether to extend Fob ${fobNumber} for ${months} months`);
}

// As TokenBound
// Transfers fobNFT `from` -> `to`
// Expected `from` is `account`
// Expected caller is owner of TokenBound Account
module.exports.transferFobAsTokenBound = async function transferFobAsTokenBound(account, caller, from, to, fobNumber) {
    let encodedWithSignature = (Globals.fobContract.interface).encodeFunctionData('safeTransferFrom(address, address, uint256)', [from, to, fobNumber]);
    await executeAsTokenBound(account, caller, 0, false, encodedWithSignature, Globals.fobContract.address);
    console.log(`Fob ${fobNumber} transfered to ${to}`);
}

// As TokenBound
// Sends ether from `account` to `receiver`
// Expected caller is owner of TokenBound Account
module.exports.sendEtherAsTokenBoundAccount = async function sendEtherAsTokenBoundAccount(account, caller, receiver, amount) {
    await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [caller],
    });
    callerSigner = await ethers.getSigner(caller);

    const AccountV3 = await hre.ethers.getContractFactory("AccountV3");
    let accountContract = AccountV3.attach(account);

    await accountContract.connect(callerSigner).execute(receiver, ethers.utils.parseEther(amount), '0x', 0);
    console.log(`${amount} ether transfered to ${receiver}`);
}

// helper function for creating TokenBounAccount.execute() call
async function executeAsTokenBound(account, caller, amountSendEth, isCallerPay, encodedWithSignature, targetContract) {
    await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [caller],
    });
    callerSigner = await ethers.getSigner(caller);

    const AccountV3 = await hre.ethers.getContractFactory("AccountV3");
    let accountContract = AccountV3.attach(account);

    await accountContract.connect(callerSigner).execute(
        targetContract, 
        amountSendEth,
        encodedWithSignature,
        0,
        isCallerPay ? { value: amountSendEth } : {});
}

// Prints TokenBound metadata
module.exports.queryTokenBoundAccount = async function queryTokenBoundAccount(address) {
    const AccountV3 = await hre.ethers.getContractFactory("AccountV3");
    const account = AccountV3.attach(address);
    let [chainId, tokenContract, tokenId] = await account.token();
    let owner = await account.owner();
    console.log(`
    TokenBoundAccount:
        chainId: ${chainId}
        nftContract address: ${tokenContract}
        tokenId: ${tokenId}
        owner address: ${owner}
    `);
}