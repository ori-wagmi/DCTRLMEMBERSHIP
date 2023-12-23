// This file handles interacting with FobNFTs as EOA
const Blockchain = require("./Blockchain.js");
const Utils = require("./Utils.js");

module.exports.main = async function main() {
    let option;
    while (option != 0) {
        console.log(`
        ~~ Fob ~~
        1. Issue new fob
        2. Reissue existing fob
        3. Extend existing fob
        4. Burn existing fob
        5. Query existing fob
        6. Grant Role
        0. Go back
        `);
        option = Number(await Utils.askQuestion("Enter number: "));
        switch (option) {
            case 1:
                await issueFob();
                break;
            case 2:
                await reissueFob();
                break;
            case 3:
                await extendFob();
                break;
            case 4:
                await burnFob();
                break;
            case 5:
                await queryFob();
                break;
            case 6:
                await grantRole();
                break;
            default:
        }
    }
}

// issues a new fob with tokenId `fobNumber to `receiver`, `caller` pays
async function issueFob() {
    let caller = await Utils.askQuestion("Who is the caller: ");
    let receiver = await Utils.askQuestion("Who is receiving the fob?: ");
    let fobNumber = Number(await Utils.askQuestion("What is the fob number?: "));
    let months = Number(await Utils.askQuestion("Pay for how many months?: "));
    await Blockchain.issueFob(caller, receiver, fobNumber, months);
}

// reissues existing fob with tokenId `fobNumber` to `receiver`, `caller` pays.
// This is the same as calling `burnFob` and `issueFob` in one transaction
async function reissueFob() {
    let caller = await Utils.askQuestion("Who is the caller: ");
    let receiver = await Utils.askQuestion("Who is receiving the fob?: ");
    let fobNumber = Number(await Utils.askQuestion("What is the fob number?: "));
    let months = Number(await Utils.askQuestion("Pay for how many months?: "));
    await Blockchain.reissueFob(caller, receiver, fobNumber, months);
}

// extends expiration of existing fob
async function extendFob() {
    let caller = await Utils.askQuestion("Who is the caller?: ");
    let fobNumber = Number(await Utils.askQuestion("What is the fob number?: "));
    let months = Number(await Utils.askQuestion("Pay for how many months?: "));
    await Blockchain.extendFob(caller, fobNumber, months);
}

// burns existing fob. caller is expected to have `BURNER_ROLE`
async function burnFob() {
    let caller = await Utils.askQuestion("Who is the caller?: ");
    let fobNumber = Number(await Utils.askQuestion("What is the fob number?: "));
    await Blockchain.burnFob(caller, fobNumber);
}

// queries fob metadata
async function queryFob() {
    let id = Number(await Utils.askQuestion("Enter fob number: "));
    await Blockchain.queryFobContractById(id);
}

// grants access control role to address
async function grantRole() {
    let option;
    while (option != 0) {
        console.log(`
        ~~ Granting Role for FobContract ~~
        1. MINTER_ROLE
        2. BURNER_ROLE
        0. Go back
        `);
        option = Number(await Utils.askQuestion("Enter number: "));
        if (option == 1 || option == 2) {
            let address = await Utils.askQuestion("Grant role to which address?: ");
            await Blockchain.grantRoleFob(option, address);
            console.log("Role granted")
        }
    }
}