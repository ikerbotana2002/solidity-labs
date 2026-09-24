// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Staking {
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public rewards;

    constructor(address tokenAddress) {
        stakingToken = IERC20(tokenAddress);
    }

    function stake(uint256 amount) external {
        _updateReward(msg.sender);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        stakedBalance[msg.sender] += amount;
    }

    function unstake(uint256 amount) external {
        require(stakedBalance[msg.sender] >= amount, "Insufficient staked balance");

        _updateReward(msg.sender);

        stakedBalance[msg.sender] -= amount;

        stakingToken.safeTransfer(msg.sender, amount);
    }

    function _updateReward(address user) internal {
        uint256 timeElapsed = block.timestamp - lastUpdateTime[user];

        // De momento: 1 MTK de recompensa por cada 100 MTK
        // en staking durante 1 día.
        uint256 reward = (stakedBalance[user] * timeElapsed) / (100 * 1 days);

        rewards[user] += reward;
        lastUpdateTime[user] = block.timestamp;
    }

    function claimRewards() external {
        _updateReward(msg.sender);

        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;

        stakingToken.safeTransfer(msg.sender, reward);
    }
}
