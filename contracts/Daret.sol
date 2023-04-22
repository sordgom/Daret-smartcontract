    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;

    import "@openzeppelin/contracts/access/Ownable.sol";
    import "@openzeppelin/contracts/utils/math/SafeMath.sol";

    contract Rosca is Ownable {
        using SafeMath for uint256;

        uint256 private constant MAX_MEMBERS = 1000;

        uint256 public constant MIN_CONTRIBUTION = 1 wei;

        uint256 public constant MAX_CONTRIBUTION = 1 ether;

        uint256 public constant MIN_ROUNDS = 1;

        uint256 public constant MAX_ROUNDS = 10000;

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

        uint256 public contribution; 

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
         * @param _contribution The contribution amount for each member 
         */
        constructor(
            uint256 _maxRounds,
            uint256 _maxMembers,
            uint256 _feePercentage,
            address _feeAccount,
            uint256 _contribution
        ) payable {
            require(_maxRounds >= MIN_ROUNDS && _maxRounds <= MAX_ROUNDS, "Invalid number of rounds");
            require(_maxMembers > 1 && _maxMembers <= MAX_MEMBERS, "Invalid number of members");
            require(_feePercentage <= MAX_ADMIN_FEE, "Invalid fee percentage");
            require(_feeAccount != address(0), "Invalid fee account");
            require(_contribution >= MIN_CONTRIBUTION && _contribution <= MAX_CONTRIBUTION, "Invalid contributio amount");
            
            maxRounds = _maxRounds;
            maxMembers = _maxMembers;
            currentFeePercentage = _feePercentage;
            feeAccount = _feeAccount;
            contribution = _contribution;
            state = State.Setup;

            // Start the first round automatically
            _startRound();

            // Creator joins the first round by default with the provided initial contribution
            require(msg.value == contribution, "Invalid contribution amount");
            _joinRound(msg.sender, _contribution);
        }
        // returns a list of members that joined the round
         function getMembers() public view returns (address[] memory) {
            return rounds[currentRound].members;
        }

        //The Reason I have private and public is startRound() is only called by the owner and _startRound() is called by startRound() and completeRound()
        function _startRound()  private{
            currentRound++;

            require(currentRound <= maxRounds, "Maximum rounds reached");

            Round storage round = rounds[currentRound];
            round.roundNumber = currentRound;
            round.contribution = contribution;
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
            require(msg.value == contribution, "Invalid contribution amount");
                
            require(rounds[currentRound].members.length < maxMembers, "Maximum number of members reached");

            _joinRound(msg.sender, msg.value);
        }

        function _joinRound(address _member, uint256 _amount) private {
            Round storage round = rounds[currentRound];
            round.memberInfo[_member].contribution = _amount;
            round.memberInfo[_member].paidRounds = 0;
            round.memberInfo[_member].paid = false;
            round.members.push(_member);

            emit MemberJoined(currentRound, _member);

            if (round.members.length == maxMembers) {
                state = State.Closed;
                round.endTime = block.timestamp;
            }
        }

        function getRoundWinner(uint256 roundNumber) public view returns (address) {
            require(roundNumber > 0 && roundNumber <= currentRound, "Invalid round number");
            return rounds[roundNumber].winner;
        }

        function completeRound(address payable winner) external onlyOwner onlyState(State.Closed) {
            Round storage round = rounds[currentRound];
            require(round.winner == address(0), "Round already completed");
            require(round.memberInfo[winner].contribution > 0, "Winner is not a member of the current round");
            
            // Ensure the winner has not won in any previous rounds
            for (uint256 i = 1; i < currentRound; i++) {
                require(getRoundWinner(i) != winner, "Winner has already won a previous round");
            }
            
            uint totalContribution = 0;
            for (uint i = 0; i < round.members.length; i++) {
                totalContribution = totalContribution.add(round.memberInfo[round.members[i]].contribution);
            }
            require(totalContribution >= round.payout, "Not enough contributions");

            round.winner = winner;
            round.paidOut = true;

            
        // Calculate payout and fees
            uint256 winnerFeeAmount = round.contribution.mul(round.winnerFee).div(100);
            uint256 winnerPayout = round.payout.sub(winnerFeeAmount);
            uint256 totalAdminFee = round.contribution.mul(round.adminFee).div(100).add(winnerFeeAmount);

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