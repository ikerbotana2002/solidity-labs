// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "../lib/forge-std/src/Test.sol";
import {SimpleVault} from "../src/SimpleVault.sol";

contract ReentrancyAttacker {
    SimpleVault public vault;

    constructor(SimpleVault _vault) {
        vault = _vault;
    }

    function attack() external payable {
        vault.deposit{value: msg.value}();
        vault.withdraw(msg.value);
    }

    receive() external payable {
        if (address(vault).balance >= 1 ether) {
            vault.withdraw(1 ether);
        }
    }
}

contract RejectEther {
    receive() external payable {
        revert();
    }
}

interface IFakeVault {
    function pepito() external;
}

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

    function testFallbackReverts() public {
        vm.expectRevert();

        IFakeVault(address(vault)).pepito();
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
        vm.expectRevert(SimpleVault.InsufficientBalance.selector);
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

    function testWithdrawFailsIfReceiverRejectsEther() public {
        RejectEther rejector = new RejectEther();

        vm.deal(address(rejector), 1 ether);

        vm.prank(address(rejector));
        vault.deposit{value: 1 ether}();

        vm.prank(address(rejector));
        vm.expectRevert(SimpleVault.TransferFailed.selector);
        vault.withdraw(1 ether);

        assertEq(vault.balances(address(rejector)), 1 ether);
        assertEq(address(vault).balance, 1 ether);
    }

    function testAttack() public {
        // Víctimas meten dinero
        vm.prank(alice);
        vault.deposit{value: 2 ether}();

        vm.prank(bob);
        vault.deposit{value: 3 ether}();

        // Creamos atacante
        ReentrancyAttacker attacker = new ReentrancyAttacker(vault);

        // Le damos dinero al usuario que lanzará el ataque
        vm.deal(address(this), 1 ether);

        vm.expectRevert();
        attacker.attack{value: 1 ether}();

        // El dinero de Alice y Bob sigue intacto
        assertEq(vault.balances(alice), 2 ether);
        assertEq(vault.balances(bob), 3 ether);
        assertEq(address(vault).balance, 5 ether);
    }

    function testReceiveDirectEther() public {
        vm.prank(alice);

        (bool success,) = address(vault).call{value: 1 ether}("");

        assertTrue(success);
        assertEq(vault.balances(alice), 1 ether);
        assertEq(address(vault).balance, 1 ether);
    }
}
