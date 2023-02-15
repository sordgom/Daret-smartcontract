// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const CrowdFund = await hre.ethers.getContractFactory("CrowdFund");
  const crowdFund = await CrowdFund.deploy("0x0AD4F5143c1e3Bd2749F246548547B7711d82382");

  await crowdFund.deployed();

  console.log("CF address: ", crowdFund.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
