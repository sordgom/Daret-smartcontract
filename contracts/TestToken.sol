// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestToken is Ownable, ERC20 {
    constructor()
        ERC20("Test Token", "GDai")
    {
        
            _mint(msg.sender, 500 ether);
        
    }
}