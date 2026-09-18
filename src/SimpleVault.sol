// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleVault {

    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    function deposit() public payable {
        balances[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;

        emit Withdrawal(msg.sender, amount);

        (bool success, ) = payable(msg.sender).call{value: amount}("");

        require(success, "Transfer failed");
    }
}