// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./ParentVault.sol";
// Import this file to use console.log
import "hardhat/console.sol";
import "./TestToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DaretVault is Ownable {
    using DecimalMath for uint256;
    using SafeCast for uint256;

    event Reward(address indexed userAddress, uint256 amount);
    event Paid(address indexed userAddress, uint256 recurrence);

    mapping(uint256 => address) public users;
    mapping(address => bool) public rewarded;
    mapping(address => mapping(uint256 => bool)) public payments;

    uint256 public recurrence = 30 days;
    uint256 public payment_iteration = 0;
    uint256 public amount;
    uint256 public total;
    uint256 public balance;
    uint256 public timeCreated;
    TestToken public token;
    address[] public wallets;

    address public USDCAddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    USDCInterface USDC = USDCInterface(USDCAddress);

    // ["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]

    /**
     * @param _recurrence to determine the frequency of the payments(1 month by default)
     * @param _amount the amount the users have to pay on each contribution
     * @param _wallets list of wallets involved
     */
    constructor(
        uint256 _recurrence,
        uint256 _amount,
        address[] memory _wallets,
        address _tokenAddress
    ) {
        //Fill the mappings with initial values
        for (uint256 i = 0; i < _wallets.length; i++) {
            users[i] = _wallets[i];
            rewarded[_wallets[i]] = false;
            for (uint256 j = 0; j < _recurrence; j++) {
                payments[_wallets[i]][j] = false;
            }
        }

        recurrence = _recurrence;
        amount = _amount;
        timeCreated = block.timestamp;
        total = _amount * _wallets.length;
        token = TestToken(_tokenAddress);
        token.mint(address(this), 1000000);
        balance = token.balanceOf(address(this));
        wallets = _wallets;
    }

    function getWallets() public view returns (address[] memory) {
        address[] memory elements = new address[](wallets.length);
        for (uint256 i = 0; i < wallets.length; i++) {
            elements[i] = wallets[i];
        }
        return elements;
    }

    modifier isRewarded(address _address) {
        require(!rewarded[_address], "Wallet is already rewarded");
        _;
    }

    modifier hasToPay(address _address, uint256 _iteration) {
        require(!payments[_address][_iteration], "Wallet already paid");
        _;
    }

    //Reward functionlity
    function reward() public isRewarded(msg.sender) {
        token.transfer(msg.sender, total);
        emit Reward(msg.sender, total);
        rewarded[msg.sender] = true;
        payment_iteration++;
        balance -= total;
    }

    //Users should be able to pay their contribution
    function pay() public hasToPay(msg.sender, payment_iteration) {
        token.transferFrom(msg.sender, address(this), amount);
        emit Paid(msg.sender, payment_iteration);
        payments[msg.sender][payment_iteration] = true;
        balance += amount;
    }

    // Self destruct function after all the users have been paid
    function endDaret() public {
        uint256 i = 0;
        while (i < wallets.length) {
            require(rewarded[wallets[i++]], "The contract is not over yet");
            if (i == wallets.length) {
                selfdestruct(
                    payable(address(this))
                );
            }
        }
    }
}

interface USDCInterface {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

library DecimalMath {
    function muld(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y) / 1e27;
    }
}

library SafeCast {
    function i256(uint256 x) internal pure returns (int256) {
        require(x <= uint256(type(int256).max), "Cast overflow");
        return int256(x);
    }
}
