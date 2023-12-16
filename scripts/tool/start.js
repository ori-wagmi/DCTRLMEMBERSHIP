// Entry point for the membership tool
const MembershipHelper = require("./Membership.js");
const FobHelper = require("./Fob.js");
const Utils = require("./Utils.js");
const TokenBoundHelper = require("./TokenBound.js");
const Blockchain = require("./Blockchain.js");


async function main() {
    await Utils.onetime_deployContracts();

    let option;
    while (option != 0) {
        await Utils.printUsers();
        await Utils.printTokenBoundAccounts();

        console.log(`
        ~~ Welcome to DctrlMembership Tool - Made by ori ~~
        1. Membership
        2. Fob
        3. TokenBound Account
        4. Send Ether
        0. Quit
        `)
        option = Number(await Utils.askQuestion("Enter number: "));
        try {
            switch (option) {
                case 1:
                    await MembershipHelper.main();
                    break;
                case 2:
                    await FobHelper.main();
                    break;
                case 3:
                    await TokenBoundHelper.main();
                    break;
                case 4:
                    await Utils.sendEther();
                default:
            }
        } catch (err) {
            console.log(`
            !!! ERROR !!!
            Oops, something went wrong. Let's try again
            ${err}
            !!! ERROR !!!
            `);
        }
    }
}

main();