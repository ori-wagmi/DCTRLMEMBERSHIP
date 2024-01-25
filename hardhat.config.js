require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
if (process.env.TEST_MODE === "true") {
  require("@nomicfoundation/hardhat-foundry");
}
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.22",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
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
