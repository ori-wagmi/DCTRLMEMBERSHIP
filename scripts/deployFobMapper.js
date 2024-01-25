const hre = require("hardhat");
const waitFor = (delay) => new Promise((resolve) => setTimeout(resolve, delay));

async function main() {
  let [owner] = await ethers.getSigners();

  // **ERC6551 
  const FobMapper = await hre.ethers.getContractFactory("FobMapper");
  const fobmapper = await FobMapper.deploy();
  await fobmapper.deployed();
  console.log("FobMapper deployed: " + fobmapper.address);
  await waitFor(2000);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  