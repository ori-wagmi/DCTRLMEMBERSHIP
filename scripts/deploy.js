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

  // **ERC6551 
  const Registry = await hre.ethers.getContractFactory("ERC6551Registry");
  const registry = await Registry.deploy();
  await registry.deployed();
  console.log("Registry deployed: " + registry.address);
  await waitFor(2000);

  const Multicall3 = await hre.ethers.getContractFactory("Multicall3");
  const forwarder = await Multicall3.deploy();
  await forwarder.deployed();
  console.log("Multicall3 deployed: " + forwarder.address);
  await waitFor(2000);

  const AccountGuardian = await hre.ethers.getContractFactory("AccountGuardian");
  const guardian = await AccountGuardian.deploy(owner.address);
  await guardian.deployed();
  console.log("AccountGuardian deployed: " + guardian.address);
  await waitFor(2000);

  const AccountV3 = await hre.ethers.getContractFactory("AccountV3");
  const implementation = await AccountV3.deploy(
    owner.address,
    forwarder.address,
    registry.address,
    guardian.address
  );
  await implementation.deployed();
  console.log("AccountV3 deployed: " + implementation.address);
  await waitFor(2000);

  // **MembershipNFT
  const MembershipNFT = await hre.ethers.getContractFactory("MembershipNFT");
  const membership = await MembershipNFT.deploy(owner.address);
  await membership.deployed();
  console.log("MembershipNFT minted: " + membership.address);
  await waitFor(2000);

  // **FobNFT
  const FobNFT = await hre.ethers.getContractFactory("FobNFT");
  const fob = await FobNFT.deploy(owner.address);
  await fob.deployed();
  console.log("FobNFT minted: " + fob.address);
  await waitFor(2000);

  // **Minter
  const Minter = await hre.ethers.getContractFactory("Minter");
  const minter = await Minter.deploy(
    registry.address,
    implementation.address,
    membership.address,
    fob.address,
    owner.address, // payment receiver
    owner.address, // admin
    hre.ethers.utils.formatBytes32String("DCTRL"),  // salt
  );

  await minter.deployed();
  console.log("Minter minted: " + minter.address);
  await waitFor(2000);

  await membership.grantRole(await membership.MINTER_ROLE(), minter.address);
  await waitFor(2000);

  await fob.grantRole(await fob.MINTER_ROLE(), minter.address);
  await waitFor(2000);

  await fob.grantRole(await fob.BURNER_ROLE(), minter.address);
  await waitFor(2000);

  console.log("roles granted");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
