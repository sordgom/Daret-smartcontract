// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// Import this file to use console.log
import "hardhat/console.sol";

contract TestToken is Ownable, ERC20 {
    constructor() public
        ERC20("Test Token", "GDai")
    {
        
        _mint(msg.sender, 500 ether);
        
    }
    function mint(address _address, uint256 _amount) public{
        _mint(_address, _amount);
    }
}