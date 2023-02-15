pragma solidity ^0.8.15;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract mockUSDC is ERC20 {

    uint scale = 10 ** 18;

    constructor() ERC20("MockUSDC", "USDC") {
        _mint(msg.sender, 1000000 * scale);
    }
}