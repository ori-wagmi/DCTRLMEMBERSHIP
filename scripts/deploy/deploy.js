// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

const waitFor = (delay) => new Promise((resolve) => setTimeout(resolve, delay));

async function main() {
  let [owner] = await ethers.getSigners();

  const MembershipNFT = await hre.ethers.getContractFactory("MembershipNFT");
  const membership = await MembershipNFT.deploy(owner.address);
  await membership.deployed();
  console.log("MembershipNFT minted: " + membership.address);
  await waitFor(2000);

  const FobNFT = await hre.ethers.getContractFactory("FobNFT");
  const fob = await FobNFT.deploy(owner.address);
  await fob.deployed();
  console.log("FobNFT minted: " + fob.address);
  await waitFor(2000);

  const Minter = await hre.ethers.getContractFactory("Minter");
  const minter = await Minter.deploy(membership.address, fob.address, owner.address);
  await minter.deployed();
  console.log("Minter minted: " + minter.address);
  await waitFor(2000);

  await membership.grantRole(await membership.MINTER_ROLE(), minter.address);
  await waitFor(2000);

  await membership.grantRole(await membership.TRANSFER_ROLE(), owner.address);
  await waitFor(2000);

  await fob.grantRole(await fob.MINTER_ROLE(), minter.address);
  await waitFor(2000);

  await fob.grantRole(await fob.BURNER_ROLE(), minter.address);
  await waitFor(2000);

  await fob.grantRole(await fob.BURNER_ROLE(), owner.address);
  console.log("roles granted");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
