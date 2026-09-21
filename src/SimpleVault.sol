// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleVault {
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    error ZeroAmount();
    error InsufficientBalance();
    error TransferFailed();

    function deposit() external payable {
        _deposit();
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        require(balances[msg.sender] >= amount, InsufficientBalance());

        balances[msg.sender] -= amount;

        emit Withdrawal(msg.sender, amount);

        (bool success,) = payable(msg.sender).call{value: amount}("");

        require(success, TransferFailed());
    }

    receive() external payable {
        _deposit();
    }

    function _deposit() internal {
        if (msg.value == 0) revert ZeroAmount();

        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    fallback() external payable {
        revert();
    }
}
