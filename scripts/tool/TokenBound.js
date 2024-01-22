// This file handles acting as a TokenBoundAccount (membershipNFT)
const Blockchain = require("./Blockchain.js");
const Utils = require("./Utils.js");

module.exports.main = async function main() {
    let option;
    while (option != 0) {
        console.log(`
        ~~ TokenBound Account ~~
        1. Issue Fob as TokenBoundAccount
        2. Extend Fob as TokenBoundAccount
        3. Transfer Fob as TokenBoundAccount
        4. Send Ether as TokenBoundAccount
        5. Query TokenBoundAccount owner
        0. Go back
        `);
        option = Number(await Utils.askQuestion("Enter number: "));

        switch (option) {
            case 1:
                await fobMint();
                break;
            case 2:
                await fobExtend();
                break;
            case 3:
                await fobTransfer();
                break;
            case 4:
                await sendEther();
                break;
            case 5:
                await queryAccount();
            default:
        }  
    }
}

async function fobMint() {
    console.log("~~ Issuing Fob as TokenBoundAccount ~~")
    let account = await Utils.askQuestion("Enter TokenBound Account address: ");
    let caller = await Utils.askQuestion("Enter caller address: ");
    let receiver = await Utils.askQuestion("Who is receiving the fob?: ");
    let isCallerPay = await Utils.getYesNo("Is caller paying? (Y/N): ");
    let fobNumber = Number(await Utils.askQuestion("What is the fob number?: "));
    let months = Number(await Utils.askQuestion("How many months?: "));
    await Blockchain.issueFobAsTokenBound(account, caller, receiver, fobNumber, months, isCallerPay);
}

async function fobExtend() {
    console.log("~~ Extending Fob as TokenBoundAccount ~~")
    let account = await Utils.askQuestion("Enter TokenBound Account address: ");
    let caller = await Utils.askQuestion("Enter caller address: ");
    let isCallerPay = await Utils.getYesNo("Is caller paying? (Y/N): ");
    let fobNumber = Number(await Utils.askQuestion("What is the fob number?: "));
    let months = Number(await Utils.askQuestion("How many months?: "));

    await Blockchain.extendFobAsTokenBound(account, caller, fobNumber, months, isCallerPay);
}

async function fobTransfer() {
    console.log("~~ Transferring Fob as TokenBoundAccount ~~")
    let account = await Utils.askQuestion("Enter TokenBound Account address: ");
    let caller = await Utils.askQuestion("Enter caller address: ");
    let from = await Utils.askQuestion("Sending fob from?: ");
    let to = await Utils.askQuestion("Sending fob to?: ");
    let fobNumber = Number(await Utils.askQuestion("What is the fob number?: "));

    await Blockchain.transferFobAsTokenBound(account, caller, from, to, fobNumber);
}

async function sendEther() {
    console.log("~~ Sending ether as TokenBoundAccount ~~")
    let account = await Utils.askQuestion("Enter TokenBound Account address: ");
    let caller = await Utils.askQuestion("Enter caller address: ");
    let receiver = await Utils.askQuestion("Who is receiving the ether?: ");
    let amount = await Utils.askQuestion("Amount?: ");

    await Blockchain.sendEtherAsTokenBoundAccount(account, caller, receiver, amount);
}

async function queryAccount() {
    let address = await Utils.askQuestion("Enter TokenBound Account address: ");
    await Blockchain.queryTokenBoundAccount(address);
}