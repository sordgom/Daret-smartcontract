// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const CrowdFund = await hre.ethers.getContractFactory("CrowdFund");
  let _goal = 10, _durationInDays = 1, _feeAccount = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  const crowdFund = await CrowdFund.deploy(  
    _goal,
    _durationInDays,
    _feeAccount
    );
  await crowdFund.deployed();
  console.log("CF address: ", crowdFund.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
