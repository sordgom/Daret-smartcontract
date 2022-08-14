// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ParentVault.sol";

contract DaretVault{
    uint256 public recurrence = 30 days; 
    uint256 public amount = 0 ; 
    address[] public userList; //The order is the list order for now
    uint256 public total = 0 ;

    ParentVault vault ; 

    mapping(uint256 => User) users;
    /**
     * @dev User struct to keep track of users registered 
     */
    struct User {
        uint256 id;    
        address walletAddress;
    }

 
    /**
     * @param _recurrence to determine the frequency of the payments(1 month by default)
     * @param _amount the amount the users have to pay on each contribution 
     * @param _wallets list of wallets involved
     */
    constructor(uint256 _recurrence, uint256 _amount, address[] memory _wallets) public {
        recurrence = _recurrence;
        amount = _amount;
        userList = _wallets;
        total = _amount * _wallets.length;
    }

    function award(address _wallet) {
        require(_wallet.length > 0,"Please enter a valid wallet");
        transfer(_wallet, total);
    }   

    function pay() public {
        transferFrom(msg.sender, address(this), amount);
    }

}