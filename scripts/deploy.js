// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const DaretVault = await hre.ethers.getContractFactory("DaretVault");
  const daretVault = await DaretVault.deploy(
    30,
    100,
    ["0xC6A3dd9e9D73Eb3e66669534Ed21ee169aEd7f14"],
    "0x0AD4F5143c1e3Bd2749F246548547B7711d82382"
  ); //Add args

  await daretVault.deployed();

  console.log("Daret address: ", daretVault.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
