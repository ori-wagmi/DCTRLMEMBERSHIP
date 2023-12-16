// This file contains general utility functions
const Blockchain = require("./Blockchain.js");
const Globals = require("./Globals.js");
var readline = require('readline');

// Prompts for user input to 'query'
module.exports.askQuestion = function askQuestion(query) {
    var rl = readline.createInterface(process.stdin, process.stdout);

    return new Promise(resolve => rl.question(query, ans => {
        resolve(ans);
        rl.close();
    }));
}

// Calls askQuestion() and loops until user response with 'Y' or 'N'
// returns bool 'Y' == true
module.exports.getYesNo = async function getYesNo(query) {
    let answer;
    while (answer !== "Y" && answer !== "N") {
        answer = await this.askQuestion(query);
    }
    return answer == "Y";
}

// Prints deployed contract addresses
module.exports.printDeployments = function printDeployments() {
    console.log("\t ERC6551Registry: " + Globals.registryContract.address);
    console.log("\t AccountV3: " + Globals.accountContract.address);
    console.log("\t MembershipNFT: " + Globals.membershipContract.address);
    console.log("\t FobNFT: " + Globals.fobContract.address);
    console.log("\t Minter: " + Globals.minterContract.address);
}

// Prints TokenBoundAccounts (issued memberships) details
module.exports.printTokenBoundAccounts = async function printTokenBoundAccounts() {
    console.log("\nTokenBound Accounts:");
    for (i in Globals.accountArray) {
        console.log(`\tTokenId: ${i}, AccountAddress: ${Globals.accountArray[i]}, ether: ${await hre.ethers.provider.getBalance(Globals.accountArray[i])}`);
    }
}

// Print user details. Signer[0] is the multisig
module.exports.printUsers = async function printUsers() {
    let signers = await hre.ethers.getSigners();
    console.log("\nUsers:")
    console.log(`\tMultisig, address ${signers[0].address}, ether: ${await hre.ethers.provider.getBalance(signers[0].address)}`)

    for (let i = 1; i < 10; i++) {
        console.log(`\tUser ${i}, address ${signers[i].address}, ether: ${await hre.ethers.provider.getBalance(signers[i].address)}`)
    }
}

// sends ether from `sender` to `receiver`
module.exports.sendEther = async function sendEther() {
    console.log("~~ Sending ether ~~")
    let sender = await this.askQuestion("Sender address: ");
    let receiver = await this.askQuestion("Receiver address: ");
    let amount = await this.askQuestion("Amount: ");
    await Blockchain.sendEther(sender, receiver, amount);
}

// Deploys all contracts
module.exports.onetime_deployContracts = async function onetime_deployContracts() {
    console.log("Deploying contracts...");

    [Globals.minterContract,
        Globals.registryContract, 
        Globals.accountContract, 
        Globals.membershipContract, 
        Globals.fobContract] = await Blockchain.setupContracts();
    this.printDeployments();
}