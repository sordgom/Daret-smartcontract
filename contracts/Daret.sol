// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Daret is Ownable {
    event Reward(address indexed userAddress, uint256 amount);
    event Paid(address indexed userAddress, uint256 recurrence);

    mapping(address => bool) public rewarded;
    mapping(address => mapping(uint256 => bool)) public payments;

    address public USDCAddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    IERC20 public usdc = IERC20(USDCAddress);

    uint256 public recurrence;
    uint256 public paymentIteration;
    uint256 public amount;
    uint256 public total;
    uint256 public balance;
    uint256 public timeCreated;
    address[] public wallets;
    IERC20 public token;

    /**
     * @param _recurrence to determine the frequency of the payments (in seconds)
     * @param _amount the amount the users have to pay on each contribution
     * @param _wallets list of wallets involved
     * @param _tokenAddress the address of the ERC20 token to use for payments
     */
    constructor(
        uint256 _recurrence,
        uint256 _amount,
        address[] memory _wallets,
        address _tokenAddress
    ) {
        require(_wallets.length > 0, "DaretVault: wallets list is empty");
        require(_amount > 0, "DaretVault: amount is zero");
        require(
            _recurrence > 0,
            "DaretVault: recurrence interval is zero"
        );
        require(
            _tokenAddress != address(0),
            "DaretVault: invalid token address"
        );

        recurrence = _recurrence;
        amount = _amount;
        timeCreated = block.timestamp;
        token = IERC20(_tokenAddress);

        // Fill the mappings with initial values
        for (uint256 i = 0; i < _wallets.length; i++) {
            wallets.push(_wallets[i]);
            rewarded[_wallets[i]] = false;
            for (uint256 j = 0; j < _recurrence; j++) {
                payments[_wallets[i]][j] = false;
            }
        }

        total = _amount * wallets.length;
        require(
            token.balanceOf(address(this)) >= total,
            "DaretVault: insufficient token balance"
        );
    }

    function getWallets() external view returns (address[] memory) {
        return wallets;
    }

    modifier isRewarded(address _address) {
        require(!rewarded[_address], "DaretVault: wallet is already rewarded");
        _;
    }

    modifier hasToPay(address _address, uint256 _iteration) {
        require(
            !payments[_address][_iteration],
            "DaretVault: wallet already paid"
        );
        _;
    }

    // Reward functionlity
    function reward() external isRewarded(msg.sender) {
        token.transfer(msg.sender, total);
        emit Reward(msg.sender, total);
        rewarded[msg.sender] = true;
        paymentIteration++;
        balance -= total;
    }

    // Users should be able to pay their contribution
    function pay() public hasToPay(msg.sender, paymentIteration) {
        require(token.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(token.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        emit Paid(msg.sender, paymentIteration);
        payments[msg.sender][paymentIteration] = true;
        balance += amount;
    }

    // Self destruct function after all the users have been paid
    function endDaret() public onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
            require(rewarded[wallets[i]], "The contract is not over yet");
        }
        selfdestruct(payable(owner()));
    }
}