// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdFund {
    event Launch(
        address indexed creator,
        uint256 goal,
        uint32 startAt,
        uint32 endAt
    );
    event Cancel();
    event Pledge(address indexed caller, uint256 amount);
    event Unpledge(address indexed caller, uint256 amount);
    event Claim();
    event Refund(address indexed caller, uint256 amount);

    // Creator of campaign
    address public creator;
    // Amount of tokens to raise
    uint256 public goal;
    // Total amount pledged
    uint256 public pledged;
    // Timestamp of start of campaign
    uint32 public startAt;
    // Timestamp of end of campaign
    uint32 public endAt;
    // True if goal was reached and creator has claimed the tokens.
    bool public claimed;
    // Mapping from pledger => amount pledged
    mapping(address => uint256) public pledgedAmount;
    // Fee Account
    address public feeAccount;

    constructor(uint256 _goal, uint32 _durationInDays, address _feeAccount) {
        uint32 _startAt = uint32(block.timestamp);
        uint32 _endAt = uint32(block.timestamp + (_durationInDays * 1 days));
        require(_endAt > _startAt, "duration should be greater than 0");

        creator = msg.sender;
        feeAccount = _feeAccount;
        goal = _goal;
        pledged = 0;
        startAt = _startAt;
        endAt = _endAt;
        claimed = false;
        emit Launch(creator, _goal, _startAt, _endAt);
    }

    function cancel() external {
        require(feeAccount == msg.sender, "not admin");
        require(!claimed, "claimed");

        selfdestruct(payable(feeAccount));
        emit Cancel();
    }

    function pledge() external payable {
        require(block.timestamp >= startAt, "not started");
        require(block.timestamp <= endAt, "ended");

        pledged += msg.value;
        pledgedAmount[msg.sender] += msg.value;

        emit Pledge(msg.sender, msg.value);
    }

    function unpledge(uint256 _amount) external {
        require(block.timestamp <= endAt, "ended");

        pledgedAmount[msg.sender] -= _amount;
        pledged -= _amount;
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");

        emit Unpledge(msg.sender, _amount);
    }

    function claim() external {
        require(creator == msg.sender, "not creator");
        require(pledged >= goal, "pledged < goal");
        require(!claimed, "claimed");

        claimed = true;
        (bool success, ) = msg.sender.call{value: pledged}("");
        require(success, "Transfer failed");

        emit Claim();
    }

      function refund() external {
        require(block.timestamp > endAt, "not ended");
        require(pledged < goal, "pledged >= goal");

        uint256 bal = pledgedAmount[msg.sender];
        pledgedAmount[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: bal}("");
        require(success, "refund failed");

        emit Refund(msg.sender, bal);
    }
}