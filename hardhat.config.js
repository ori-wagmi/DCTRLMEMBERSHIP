require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.22",
  networks: {
    sepolia: {
      url: `https://ethereum-sepolia.publicnode.com`	,
      accounts: [process.env.DEPLOYER_PRIV_KEY],
    },
    arb: {
      url: `https://ethereum-sepolia.publicnode.com`,
      accounts: [process.env.DEPLOYER_PRIV_KEY],
    },
    op_sepolia: {
      url: `https://sepolia.optimism.io`,
      accounts: [process.env.DEPLOYER_PRIV_KEY],
    },
    
  },
};
