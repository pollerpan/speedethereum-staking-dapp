// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
	error Staker_DeadLineHasPassedOrNotEnoughFunds();
	error Staker_WithdrawNotOpen();
	error Staker_NotFundsToWithdraw();
	error Staker_TransferFailed();
	

	ExampleExternalContract public exampleExternalContract;

	mapping(address => uint256) public balances;

	uint256 public constant threshold = 1 ether;
	uint256 public deadline = block.timestamp + 72 hours;
	bool public openForWithdraw = false;

	event Stake(address, uint256);

	modifier notCompleted() {
		require(!exampleExternalContract.completed(), "Staker already completed");
		_;
	}

	constructor(address exampleExternalContractAddress) {
		exampleExternalContract = ExampleExternalContract(
			exampleExternalContractAddress
		);
	}

	// Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
	// (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
	function stake() public payable {
		if (block.timestamp >= deadline) {
			revert Staker_DeadLineHasPassedOrNotEnoughFunds();
		}
		require(msg.value > 0, "value must be greater than 0");
		balances[msg.sender] += msg.value;
		emit Stake(msg.sender, msg.value);
	}

	// After some `deadline` allow anyone to call an `execute()` function
	// If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
	function execute() public notCompleted {
		if (block.timestamp >= deadline && address(this).balance >= threshold) {
			exampleExternalContract.complete{ value: address(this).balance }();
		} else {
			openForWithdraw = true;
		} 
	}

	// If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
	function withdraw() public payable notCompleted {
		if (!openForWithdraw) {
			revert Staker_WithdrawNotOpen();
			
		} 
		
		uint256 balanceOfUser = balances[msg.sender];
		
		if (balanceOfUser == 0) {
			revert Staker_NotFundsToWithdraw();
		} 

		
		balances[msg.sender] = 0;
		(bool fundsWithdraw,) = payable(msg.sender).call{value: balanceOfUser}("");

		if (!fundsWithdraw) {
			revert Staker_TransferFailed();
		}


	}

	// Add a `timeLeft()` vie w function that returns the time left before the deadline for the frontend
	function timeLeft() public view returns (uint256) {
		if (block.timestamp >= deadline) {
			return 0;
		} else {
			return deadline - block.timestamp;
		}
	}

	// Add the `receive()` special function that receives eth and calls stake()
	receive() external payable {
		stake();
	}
}
