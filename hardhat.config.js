require("@nomicfoundation/hardhat-toolbox");
if (process.env.TEST_MODE) {
  require("@nomicfoundation/hardhat-foundry");
}
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
