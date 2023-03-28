// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const DaretVault = await hre.ethers.getContractFactory("Rosca");
  const daretVault = await DaretVault.deploy(
    5, 
    5,
    2,
    "0xa485A768CB6DE1DE1e0Fc5AB2b93703a11615c1A",
    100,
    {
      value: 100
    }
  );

  await daretVault.deployed();

  console.log("Daret address: ", daretVault.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
