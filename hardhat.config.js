require("@nomicfoundation/hardhat-toolbox");

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
    goerli: {
      url: "",
      accounts: []
    }
  }

};
