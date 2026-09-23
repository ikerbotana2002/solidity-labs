// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken token;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        token = new MyToken();
    }

    function testMint() public {
        token.mint(alice, 100);

        assertEq(token.totalSupply(), 100);
        assertEq(token.balanceOf(alice), 100);
    }

    function testTransfer() public {
        token.mint(alice, 100);

        vm.prank(alice);
        token.transfer(bob, 30);

        assertEq(token.balanceOf(alice), 70);
        assertEq(token.balanceOf(bob), 30);
        assertEq(token.totalSupply(), 100);
    }

    function testOnlyOwnerCanMint() public {
        vm.prank(alice);
        vm.expectRevert("Not owner");

        token.mint(alice, 100);
    }

    function testCannotMintToZeroAddress() public {
        vm.expectRevert(MyToken.InvalidReceiver.selector);

        token.mint(address(0), 100);
    }

    function testApprove() public {
        token.mint(alice, 100);

        vm.prank(alice);
        token.approve(bob, 40);

        assertEq(token.allowance(alice, bob), 40);
    }

    function testTransferFrom() public {
        token.mint(alice, 100);

        vm.prank(alice);
        token.approve(bob, 40);

        vm.prank(bob);
        token.transferFrom(alice, bob, 30);

        assertEq(token.balanceOf(alice), 70);
        assertEq(token.balanceOf(bob), 30);
        assertEq(token.allowance(alice, bob), 10);
    }

    function testCannotTransferFromMoreThanAllowance() public {
        token.mint(alice, 100);

        vm.prank(alice);
        token.approve(bob, 40);

        vm.prank(bob);
        vm.expectRevert("Insufficient allowance");

        token.transferFrom(alice, bob, 50);
    }

    function testCannotTransferFromMoreThanBalance() public {
        token.mint(alice, 30);

        vm.prank(alice);
        token.approve(bob, 100);

        vm.prank(bob);
        vm.expectRevert("Insufficient balance");

        token.transferFrom(alice, bob, 50);
    }
}
