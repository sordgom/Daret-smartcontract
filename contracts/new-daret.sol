// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Rosca is Ownable {
    using SafeMath for uint256;

    uint256 private constant MAX_MEMBERS = 50;

    uint256 public constant MIN_CONTRIBUTION = 1 ether;

    uint256 public constant MAX_CONTRIBUTION = 10 ether;

    uint256 public constant MIN_ROUNDS = 2;

    uint256 public constant MAX_ROUNDS = 50;

    uint256 public constant FEE_PERCENTAGE = 1;

    uint256 public constant SECONDS_IN_DAY = 86400;

    uint256 public constant GRACE_PERIOD = 3 * SECONDS_IN_DAY; // 3 days

    uint256 public constant MAX_ADMIN_FEE = 10;

    uint256 public constant MAX_WINNER_FEE = 2;

    enum State { Setup, Open, Closed, Completed }

    struct Member {
        uint256 contribution;
        uint256 paidRounds;
        bool paid;
    }

    struct Round {
        uint256 roundNumber;
        uint256 contribution;
        uint256 adminFee;
        uint256 winnerFee;
        uint256 payout;
        uint256 startTime;
        uint256 gracePeriodEndTime;
        uint256 endTime;
        address[] members;
        mapping(address => Member) memberInfo;
        address winner;
        bool paidOut;
    }

    mapping(uint256 => Round) public rounds;

    uint256 public currentRound;

    uint256 public maxRounds;

    uint256 public maxMembers;

    uint256 public currentFeePercentage;

    uint256 public startTime;

    address public feeAccount;

    State public state;

    event RoundStarted(uint256 roundNumber, uint256 startTime, uint256 endTime);

    event MemberJoined(uint256 roundNumber, address member);

    event ContributionAdded(uint256 roundNumber, address member, uint256 amount);

    event RoundCompleted(uint256 roundNumber, address winner, uint256 payout);

    event ContractClosed(uint256 time);

    modifier onlyState(State _state) {
        require(state == _state, "Invalid state");
        _;
    }

     /**
     * @param _maxRounds Rounds the contract will run for
     * @param _maxMembers The number of members
     * @param _feePercentage The percentage of the contribution that will be used for admin fees
     * @param _feeAccount The account that will receive the admin fees
     */
    constructor(
        uint256 _maxRounds,
        uint256 _maxMembers,
        uint256 _feePercentage,
        address _feeAccount
    ) {
        require(_maxRounds >= MIN_ROUNDS && _maxRounds <= MAX_ROUNDS, "Invalid number of rounds");
        require(_maxMembers > 1 && _maxMembers <= MAX_MEMBERS, "Invalid number of members");
        require(_feePercentage <= MAX_ADMIN_FEE, "Invalid fee percentage");
        require(_feeAccount != address(0), "Invalid fee account");

        maxRounds = _maxRounds;
        maxMembers = _maxMembers;
        currentFeePercentage = _feePercentage;
        feeAccount = _feeAccount;

        state = State.Setup;
    }
    
     //The Reason I have private and public is startRound() is only called by the owner and _startRound() is called by startRound() and completeRound()
     function _startRound()  private{
        currentRound++;

        require(currentRound <= maxRounds, "Maximum rounds reached");

        Round storage round = rounds[currentRound];
        round.roundNumber = currentRound;
        round.contribution = MIN_CONTRIBUTION;
        round.adminFee = currentFeePercentage;
        round.winnerFee = MAX_WINNER_FEE;
        round.startTime = block.timestamp;
        round.gracePeriodEndTime = round.startTime + GRACE_PERIOD;
        round.endTime = round.startTime + GRACE_PERIOD.mul(maxMembers);
        //payout = contribution * maxmembers * (100 - adminFee - winnerFee) / 100
        round.payout = (round.contribution.mul(maxMembers).mul(100 - round.adminFee - round.winnerFee)).div(100); 
        round.winner = address(0);
        round.paidOut = false;

        state = State.Open;

        emit RoundStarted(currentRound, round.startTime, round.endTime);
    }

    function startRound() external onlyOwner onlyState(State.Setup){
        _startRound();
    }

    function joinRound() external payable onlyState(State.Open) {
        require(msg.value == MIN_CONTRIBUTION, "Invalid contribution amount");
        require(rounds[currentRound].memberInfo[msg.sender].contribution == 0, "You have already joined this round");
        require(rounds[currentRound].members.length < maxMembers, "Maximum number of members reached");

        Round storage round = rounds[currentRound];
        round.memberInfo[msg.sender].contribution = msg.value;
        round.memberInfo[msg.sender].paidRounds = 0;
        round.memberInfo[msg.sender].paid = false;
        round.members.push(msg.sender);

        emit MemberJoined(currentRound, msg.sender);

        if (round.members.length == maxMembers) {
            state = State.Closed;
            round.endTime = block.timestamp;
        }
    }

    function addContribution() external payable onlyState(State.Open) {
        require(msg.value == MIN_CONTRIBUTION, "Invalid contribution amount");
        require(rounds[currentRound].memberInfo[msg.sender].contribution > 0, "You have not joined this round");

        rounds[currentRound].memberInfo[msg.sender].contribution = rounds[currentRound].memberInfo[msg.sender].contribution.add(msg.value);

        emit ContributionAdded(currentRound, msg.sender, msg.value);
    }

    function completeRound(address payable winner) external onlyOwner onlyState(State.Closed) {
        Round storage round = rounds[currentRound];
        require(round.winner == address(0), "Round already completed");

        round.winner = winner;
        round.paidOut = true;

      // Calculate payout and fees
        uint256 winnerPayout = round.payout.sub(round.contribution.mul(round.winnerFee).div(100));
        uint256 totalAdminFee = round.contribution.mul(round.adminFee).div(100);

        // Check contract balance
        require(address(this).balance >= winnerPayout.add(totalAdminFee), "Insufficient contract balance");

        // Transfer funds to winner and owner
        winner.transfer(winnerPayout);
        payable(feeAccount).transfer(totalAdminFee);

        if (currentFeePercentage < MAX_ADMIN_FEE) {
            currentFeePercentage++; 
        }

        if (currentRound == maxRounds) {
            state = State.Completed;
            emit ContractClosed(block.timestamp);
        } else {
            _startRound();
        }

        emit RoundCompleted(currentRound, winner, round.payout);
    }

    // function closeContract() external onlyOwner onlyState(State.Open) {
    //     require(currentRound > 0, "No rounds started");
    //     require(block.timestamp > rounds[currentRound].endTime + GRACE_PERIOD, "Grace period not over yet");

    //     uint256 balance = address(this).balance;

    //     uint256 feeAmount = balance.mul(currentFeePercentage).div(100);
    //     uint256 amount = balance.sub(feeAmount);

    //     payable(feeAccount).transfer(feeAmount);
    //     payable(owner()).transfer(amount);

    //     state = State.Closed;

    //     emit ContractClosed(block.timestamp);
    // }

    function closeContract() external onlyOwner onlyState(State.Open) {
        require(currentRound > 0, "No rounds started");

        // Close current round if it is still open
        if (rounds[currentRound].endTime > 0 && rounds[currentRound].endTime > block.timestamp) {
            rounds[currentRound].endTime = block.timestamp;
        }

        state = State.Closed;

        emit ContractClosed(block.timestamp);
    }
}