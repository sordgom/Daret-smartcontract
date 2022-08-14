// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Import this file to use console.log
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract ParentVault is Ownable,ERC20 {

    uint256 public SCALE = 10**18;
    /**
     * @dev Fired when a child contract is created
     */
    event Child(
        // Users users,
        // reccurence ,
        // amount,
        // balance
    );

    /**
     * @dev Create a contract token that'll be provided to investors 
     */
    constructor() ERC20("Daret Vault","DC"){
        _mint(msg.sender,1 * SCALE);
    }

   
}