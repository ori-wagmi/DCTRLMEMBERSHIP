const hre = require("hardhat");

const waitFor = (delay) => new Promise((resolve) => setTimeout(resolve, delay));

async function main() {
    let [owner] = await ethers.getSigners();

    // **FobNFT
    const FobNFT = await hre.ethers.getContractFactory("FobNFT");
    const fob = await FobNFT.deploy(owner.address);
    await fob.deployed();
    console.log("FobNFT minted: " + fob.address);

    // Mint a fob
    await fob.issue(owner.address, 1, 1);

    // Check the metadata
    console.log(await fob.tokenURI(1));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
