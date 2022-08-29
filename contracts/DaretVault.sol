// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ParentVault.sol";
// Import this file to use console.log
import "hardhat/console.sol";
import "./TestToken.sol";

contract DaretVault {
    using DecimalMath for uint256;
    using SafeCast for uint256;

    event Rewarded(address indexed userAddress, uint256 amount);

    uint256 public recurrence = 30 days;
    uint256 public amount = 0;
    address[] public userList; //The order is the list order for now
    uint256 public total = 0;
    address payable public owner;
    uint256 public balance = 0;
    TestToken public token;
    ParentVault vault;  

    address public USDCAddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    USDCInterface USDC = USDCInterface(USDCAddress);

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
    constructor(
        uint256 _recurrence,
        uint256 _amount,
        address _wallets,
        address _tokenAddress

    ) {
        recurrence = _recurrence;
        amount = _amount;
        userList.push(_wallets);
        total = _amount * userList.length;
        token = TestToken(_tokenAddress);
    }

    function reward(address _wallet) public {
        token.transfer(_wallet, total);
        emit Rewarded(_wallet,total);
    }

    function pay() public {
        token.transferFrom(msg.sender, address(this), amount);
    }
}
interface USDCInterface {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

library DecimalMath {
    function muld(uint256 x, uint256 y) internal pure returns (uint256) {
        return x * y / 1e27;
    }
}

library SafeCast {
    function i256(uint256 x) internal pure returns (int256) {
        require (x <= uint256(type(int256).max), "Cast overflow");
        return int256(x);
    }
}