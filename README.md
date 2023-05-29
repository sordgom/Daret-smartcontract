# Daret Smart Contract Project

This project is a use case of the Hardhat development environment for Ethereum. It includes two contracts: Daret and CrowdFund, tests for these contracts, and scripts to deploy them.

## Installation

First, clone this repo and install its dependencies:

```shell
git clone
cd daret
npm install
```

## Usage

Try running some of the following tasks:
Replace variables '$network' and '$sc_address' with the network name and contract address respectively.
create your own constructor-args.js file to verify your smart contract using the constructor arguments.

```shell
npx hardhat help
npx hardhat test
GAS_REPORT=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js --network $network
npx hardhat run scripts/deployCrowdFund.js --network $network
npx hardhat verify --network $network --constructor-args constructor-args.js $sc_address
npx hardhat verify --network $network $sc_address 
npx hardhat clean
```

## Contract Overview

### Daret Contract

This contract is designed for ROSCA (Rotating Savings and Credit Association) operations. Key functions include:

* constructor(address _tokenAddress): Initializes the Daret contract with the address of the token contract.

* startRound(): Starts a new round of the ROSCA.

* joinRound(uint256 _roundNumber): Enables members to join a round of the ROSCA.

* addContribution(uint256 _roundNumber): Allows members to add their contribution to a round of the ROSCA.

* completeRound(uint256 _roundNumber): Completes a round of the ROSCA.

* closeContract(): Closes the ROSCA contract.

Please refer to the contract source code for detailed comments about the functions and their modifiers.

### CrowdFund contract

This contract provides functionality for crowdfunding operations. Key functions include:

* constructor(uint256 _goal, uint32 _durationInDays, address _feeAccount): This function initializes the CrowdFund contract. It takes the goal amount to be raised, the duration of the campaign in days, and the address of the fee account as parameters. It sets the start and end times for the campaign, the goal amount, the creator address, and the fee account address.

* cancel(): This function is used to cancel the campaign. It can only be called by the fee account and can only be called before the campaign is claimed. It self-destructs the contract and returns the remaining balance to the fee account.

* pledge(): This function is used by users to pledge funds to the campaign. It can only be called during the campaign and adds the pledged amount to the total pledged amount and updates the pledged amount for the caller.

* unpledge(uint256 _amount): This function is used by users to unpledge a certain amount of their pledge. It can only be called during the campaign and updates the pledged amount and the total pledged amount for the caller.

* claim(): This function is used by the creator to claim the pledged amount once the campaign is successfully completed. It can only be called by the creator after the campaign has ended and the goal has been reached. It sets the claimed state to true, transfers the pledged amount to the creator, and emits the Claim event.

* refund(): This function is used by users to request a refund of their pledged amount if the campaign is not successfully completed. It can only be called after the campaign has ended and the goal has not been reached. It transfers the pledged amount back to the caller and emits the Refund event.

Refer to the contract source code for additional details and comments.

Contributions and suggestions are welcome! Please open an issue or submit a pull request with any suggestions or enhancements