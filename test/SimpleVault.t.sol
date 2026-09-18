// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SimpleVault} from "../src/SimpleVault.sol";

contract SimpleVaultTest is Test {
    SimpleVault vault;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    function setUp() public {
        vault = new SimpleVault();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function testDeposit() public {
        vm.prank(alice);
        vault.deposit{value: 1 ether}();

        assertEq(vault.balances(alice), 1 ether);
        assertEq(address(vault).balance, 1 ether);
    }

    function testWithdraw() public {
        vm.startPrank(alice);

        vault.deposit{value: 1 ether}();
        vault.withdraw(1 ether);

        vm.stopPrank();

        assertEq(vault.balances(alice), 0);
        assertEq(address(vault).balance, 0);
    }

    function testCannotWithdrawMoreThanBalance() public {
        vm.prank(alice);
        vault.deposit{value: 1 ether}();

        vm.prank(alice);
        vm.expectRevert("Insufficient balance");
        vault.withdraw(1.1 ether);
    }

    function testDepositEmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit Deposit(alice, 1 ether);

        vm.prank(alice);
        vault.deposit{value: 1 ether}();
    }
    function testWithdrawEmitsEvent() public {
        vm.prank(alice);
        vault.deposit{value: 1 ether}();

        vm.expectEmit(true, false, false, true);
        emit Withdrawal(alice, 1 ether);

        vm.prank(alice);
        vault.withdraw(1 ether);
    }

    function testUserBalancesAreSeparate() public {
        vm.prank(alice);
        vault.deposit{value: 2 ether}();

        vm.prank(bob);
        vault.deposit{value: 3 ether}();

        assertEq(vault.balances(alice), 2 ether);
        assertEq(vault.balances(bob), 3 ether);
    }
}