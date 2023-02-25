require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();
require("@nomiclabs/hardhat-etherscan");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version:   "0.8.0",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    }
  },
  
  defaultNetwork: "hardhat",

  networks: {
    hardhat: {
      chainId: 1337,
      allowUnlimitedContractSize: true
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.ALCHEMY_API_KEY}` || "",
      accounts: [`0x${process.env.GOERLI_PRIVATE_KEY}`],
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env.ALCHEMY_API_KEY}` || "",
      accounts: [`0x${process.env.GOERLI_PRIVATE_KEY}`],
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: process.env.ETHERSCAN_API
  }

};
