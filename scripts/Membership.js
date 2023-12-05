// This file handles interacting with MembershipNFTs as an EOA
const Blockchain = require("./Blockchain.js");
const Utils = require("./Utils.js");
const Globals = require("./Globals.js");

module.exports.main = async function main() {
    let option;
    while (option != 0) {
        console.log(`
        ~~ Membership ~~
        1. Issue new membership
        2. Transfer existing membership
        3. Query existing membership
        4. Grant Role
        0. Go back
        `);
        option = Number(await Utils.askQuestion("Enter number: "));
        switch (option) {
            case 1:
                await issueMembership();
                break;
            case 2:
                await transferMembership();
                break;
            case 3:
                await queryMembership();
                break;
            case 4:
                await grantRole();
                break;
            default:
        }
    }
}

// Mints a membershipNFT with {owner: 'name'}
// If membership is NOT self-custody, it's minted to the multisig
// MembershipNFTs are automatically upgraded to TokenBoundAccounts
async function issueMembership() {
    console.log("~~ Issuing new membership ~~");
    let isSelfCustody = await Utils.getYesNo("Is this membership self-custody? (Y/N): ");
    let name = await Utils.askQuestion("What is the member's name?: ");

    let tokenId;
    if (isSelfCustody) {
        let receiver = await Utils.askQuestion("What is the self-custody address?: ");
        tokenId = await Blockchain.issueMembership(receiver, name);
    } else {
        tokenId = await Blockchain.issueMembershipCustodian(name);
    }

    let accountAddress = await Blockchain.registryCreateAccount(tokenId);
    // add TokenBoundAccount to the global accountArray
    Globals.accountArray[tokenId] = accountAddress;
}

// Transfers membershipNFT as `caller` from `from` to `to`
async function transferMembership() {
    console.log("~~ Transferring membership ~~");
    let tokenId = Number(await Utils.askQuestion("Enter membership tokenId: "));
    let caller = await Utils.askQuestion("Enter caller address: ");
    let from = await Utils.askQuestion("Transfer From: ");
    let to = await Utils.askQuestion("Transfer To: ");
    await Blockchain.transferMembership(caller, from, to, tokenId);
    console.log(`Transferred membership ${tokenId} from ${from} to ${to}`);
}

// Queries membershipNFT metadata by `TokenId` or `Name`
async function queryMembership() {
    console.log(`
        ~~ Query membership by TokenId or Owner? ~~
        1. TokenId
        2. Name
    `)
    let option = Number(await Utils.askQuestion("Enter number: "));
    let query = await Utils.askQuestion("Enter query: ");

    await Blockchain.queryMembershipContract(query, option == 1 ? false : true)
}

// Grants an access control role to the address
async function grantRole() {
    let option;
    while (option != 0) {
        console.log(`
        ~~ Granting Role for MembershipContract ~~
        1. MINTER_ROLE
        2. TRANSFER_ROLE
        0. Go back
        `);
        option = Number(await Utils.askQuestion("Enter number: "));
        if (option == 1 || option == 2) {
            let address = await Utils.askQuestion("Grant role to which address?: ");
            await Blockchain.grantRoleMembership(option, address);
            console.log("Role granted")
        }
    }
}