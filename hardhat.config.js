require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.22",
  networks: {
    arb: {
      url: `https://ethereum-sepolia.publicnode.com`,
      accounts: [process.env.DEPLOYER_PRIV_KEY],
    }
  },
};
