// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyTokenOZ} from "../src/MyTokenOZ.sol";
import {Staking} from "../src/Staking.sol";

contract StakingTest is Test {
    MyTokenOZ token;
    Staking staking;

    address alice = address(0xA11CE);

    function setUp() public {
        token = new MyTokenOZ();
        staking = new Staking(address(token));

        token.mint(alice, 1000 ether);
    }

    function testStake() public {
        vm.startPrank(alice);

        token.approve(address(staking), 100 ether);
        staking.stake(100 ether);

        vm.stopPrank();

        assertEq(staking.stakedBalance(alice), 100 ether);
        assertEq(token.balanceOf(alice), 900 ether);
        assertEq(token.balanceOf(address(staking)), 100 ether);
    }

    function testRewardAfterTwoDays() public {
        token.mint(address(staking), 1000 ether);
        vm.startPrank(alice);

        token.approve(address(staking), 100 ether);
        staking.stake(100 ether);

        vm.warp(block.timestamp + 2 days);

        staking.claimRewards();

        vm.stopPrank();

        assertEq(token.balanceOf(alice), 902 ether);
    }

    function testPartialUnstakeKeepsRewards() public {
        token.mint(address(staking), 1000 ether);

        vm.startPrank(alice);

        token.approve(address(staking), 100 ether);
        staking.stake(100 ether);

        vm.warp(block.timestamp + 2 days);

        staking.unstake(40 ether);

        assertEq(staking.stakedBalance(alice), 60 ether);
        assertEq(staking.rewards(alice), 2 ether);

        vm.stopPrank();
    }

    function testRemainingStakeContinuesGeneratingRewards() public {
        token.mint(address(staking), 1000 ether);

        vm.startPrank(alice);

        token.approve(address(staking), 100 ether);
        staking.stake(100 ether);

        vm.warp(block.timestamp + 2 days);
        staking.unstake(40 ether);

        vm.warp(block.timestamp + 1 days);
        staking.claimRewards();

        vm.stopPrank();

        assertEq(token.balanceOf(alice), 942.6 ether);
    }
}
