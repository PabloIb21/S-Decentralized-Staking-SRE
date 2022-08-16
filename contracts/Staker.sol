// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping(address => uint) public balances;

  uint256 public deadline = block.timestamp + 30 seconds;
  uint256 public constant threshold = 1 ether;
  bool public openForWithdraw;

  event Stake(address indexed sender, uint256 amount);

  modifier deadlineReached(bool requireReached) {
    uint256 timeRemaining = timeLeft();
    if (requireReached) {
      require(timeRemaining == 0, "Staker: Withdrawal period is not reached yet");
    } else {
      require(timeRemaining > 0, "Staker: Withdrawal period has been reached");
    }
    _;
  }

  modifier notCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "Staker: Stake already completed");
    _;
  }

  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  function stake() public payable deadlineReached(false) {
    require(msg.value > 0, "Staker: You need to send some Ether");
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  function withdraw() public deadlineReached(true) notCompleted {
    require(openForWithdraw, "Staker: Withdrawal period is not open yet");
    require(balances[msg.sender] > 0, "Staker: You have no balance to withdraw");
    uint amount = balances[msg.sender];
    balances[msg.sender] = 0;

    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Staker: Transfer failed");
  }

  function execute() public deadlineReached(true) notCompleted {
    uint256 totalBalance = address(this).balance;
    if (totalBalance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      openForWithdraw = true;
    }
  }

  receive() external payable {
    stake();
  }

}
