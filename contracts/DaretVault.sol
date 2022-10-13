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

    uint256 public recurrence = 30 days;
    uint256 public iteration = 0 ;
    uint256 public amount;
    uint256 public total;
    uint256 public balance;
    uint public timeCreated;
    TestToken public token;

    address public USDCAddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    USDCInterface USDC = USDCInterface(USDCAddress);

    mapping(uint256 => address) public users;
    mapping(address => bool) public rewarded;
    mapping(address => mapping(uint256 => bool)) public payments;

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
        for(uint i = 0; i< _wallets.length; i++){
            users[i] = _wallets[i];
            rewarded[_wallets[i]] = false ;
            for(uint j=0 ; j< _recurrence ; j++){
                payments[_wallets[i]][j] = false;
            }
        }   

        recurrence = _recurrence;
        amount = _amount;
        timeCreated=block.timestamp;
        total = _amount * _wallets.length;
        token = TestToken(_tokenAddress);
        token.mint(address(this),1000000);
    }

    modifier isRewarded(address _address) {
        require(!rewarded[_address], "Wallet is already rewarded");
        _;
    }
    
    //Reward functionlity
    function reward(uint256 id) public isRewarded(users[id]){
        token.transfer(users[id],total);
        emit Reward(users[id],total);
        iteration++;
    }
    
    //Users should be able to pay their contribution
    function pay() public {
        //TODO
        //User has to approve the first
        token.transferFrom(msg.sender, address(this),amount);
        payments[msg.sender][iteration] = true ; 
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