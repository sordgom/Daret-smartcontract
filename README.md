# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
GAS_REPORT=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js --network goerli
npx hardhat run scripts/deployCrowdFund.js --network goerli
npx hardhat verify --network goerli --constructor-args constructor-args.js $address
npx hardhat verify --network goerli $sc_address 
npx hardhat clean
```

## Daret contract explanation

* constructor(address _tokenAddress): This function is used to initialize the Daret contract. It takes the address of the token contract as a parameter and sets the token address in the contract.(should have initial balance)
  
* startRound(): This function is used to start a new round of the ROSCA. It is only callable by the contract owner and can only be called in the 'Setup' state. It creates a new Round struct in the rounds mapping, sets the round number, contribution, and fee percentages, and sets the start and end times for the round.

* joinRound(uint256 _roundNumber): This function is used by members to join a round of the ROSCA. It can only be called in the 'Open' state and adds the calling address to the members array for the specified round.

* addContribution(uint256 _roundNumber): This function is used by members to add their contribution to a round of the ROSCA. It can only be called in the 'Open' state and adds the calling address to the members array for the specified round.

* completeRound(uint256 _roundNumber): This function is used to complete a round of the ROSCA. It can only be called by the contract owner and can only be called in the 'Open' state after the round has ended. It calculates the winner of the round and sets the winner address for the round. It also sets the payout amount for the round and updates the paidRounds count for each member who contributed to the round. Finally, it sets the state to 'Completed' and starts a new round with the startRound() function.

* closeContract(): This function is used to close the ROSCA contract. It can only be called by the contract owner and can only be called in the 'Setup' or 'Open' states. If the contract is in the 'Open' state, it calculates the payout for the current round and sets the state to 'Closed'. If the contract is in the 'Setup' state, it simply sets the state to 'Closed'. Once the contract is closed, no further rounds can be started and no contributions can be added.

## CrowdFund contract explanation

* constructor(uint256 _goal, uint32 _durationInDays, address _feeAccount): This function initializes the CrowdFund contract. It takes the goal amount to be raised, the duration of the campaign in days, and the address of the fee account as parameters. It sets the start and end times for the campaign, the goal amount, the creator address, and the fee account address.

* cancel(): This function is used to cancel the campaign. It can only be called by the fee account and can only be called before the campaign is claimed. It self-destructs the contract and returns the remaining balance to the fee account.

* pledge(): This function is used by users to pledge funds to the campaign. It can only be called during the campaign and adds the pledged amount to the total pledged amount and updates the pledged amount for the caller.

* unpledge(uint256 _amount): This function is used by users to unpledge a certain amount of their pledge. It can only be called during the campaign and updates the pledged amount and the total pledged amount for the caller.

* claim(): This function is used by the creator to claim the pledged amount once the campaign is successfully completed. It can only be called by the creator after the campaign has ended and the goal has been reached. It sets the claimed state to true, transfers the pledged amount to the creator, and emits the Claim event.

* refund(): This function is used by users to request a refund of their pledged amount if the campaign is not successfully completed. It can only be called after the campaign has ended and the goal has not been reached. It transfers the pledged amount back to the caller and emits the Refund event.
