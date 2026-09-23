// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyTokenOZ} from "../src/MyTokenOZ.sol";
import {TokenVault} from "../src/TokenVault.sol";

contract TokenVaultTest is Test {
    MyTokenOZ token;
    TokenVault vault;

    address alice = address(0xA11CE);

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    function setUp() public {
        token = new MyTokenOZ();
        vault = new TokenVault(address(token));

        token.mint(alice, 500 ether);
    }

    function testDepositAndWithdraw() public {
        vm.startPrank(alice);

        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether);

        assertEq(token.balanceOf(alice), 400 ether);
        assertEq(token.balanceOf(address(vault)), 100 ether);
        assertEq(vault.balances(alice), 100 ether);

        vault.withdraw(100 ether);

        assertEq(token.balanceOf(alice), 500 ether);
        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(vault.balances(alice), 0);

        vm.stopPrank();
    }

    function testCannotWithdrawMoreThanDeposited() public {
        vm.startPrank(alice);

        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether);

        vm.expectRevert("Insufficient balance");
        vault.withdraw(150 ether);

        vm.stopPrank();
    }

    function testCannotDepositWithoutApproval() public {
        vm.prank(alice);

        vm.expectRevert();
        vault.deposit(100 ether);
    }

    function testDepositEmitsEvent() public {
        vm.startPrank(alice);

        token.approve(address(vault), 100 ether);

        vm.expectEmit(true, false, false, true);
        emit Deposit(alice, 100 ether);

        vault.deposit(100 ether);

        vm.stopPrank();
    }

    function testWithdrawEmitsEvent() public {
        vm.startPrank(alice);

        token.approve(address(vault), 100 ether);
        vault.deposit(100 ether);

        vm.expectEmit(true, false, false, true);
        emit Withdrawal(alice, 100 ether);

        vault.withdraw(100 ether);

        vm.stopPrank();
    }
}
