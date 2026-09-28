// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyTokenOZ} from "../src/MyTokenOZ.sol";

contract MyTokenOZTest is Test {
    MyTokenOZ token;

    function setUp() public {
        token = new MyTokenOZ();
    }

    function testInitialSupply() public view {
        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testTransfer() public {
        token.mint(address(this), 1000 ether);

        token.transfer(address(0xB0B), 100 ether);

        assertEq(token.balanceOf(address(this)), 900 ether);
        assertEq(token.balanceOf(address(0xB0B)), 100 ether);
        assertEq(token.totalSupply(), 1000 ether);
    }

    function testApproveAndTransferFrom() public {
        address alice = address(0xA11CE);
        address bob = address(0xB0B);

        token.mint(address(this), 1000 ether);

        token.transfer(alice, 200 ether);

        vm.prank(alice);
        token.approve(bob, 50 ether);

        vm.prank(bob);
        token.transferFrom(alice, bob, 30 ether);

        assertEq(token.balanceOf(alice), 170 ether);
        assertEq(token.balanceOf(bob), 30 ether);
        assertEq(token.allowance(alice, bob), 20 ether);
    }

    function testCannotTransferToZeroAddress() public {
        vm.expectRevert();
        token.transfer(address(0), 10 ether);
    }

    function testOwnerCanMint() public {
        token.mint(address(0xB0B), 100 ether);

        assertEq(token.balanceOf(address(0xB0B)), 100 ether);
    }

    function testNonOwnerCannotMint() public {
        address bob = address(0xB0B);

        vm.prank(bob);
        vm.expectRevert();

        token.mint(bob, 100 ether);
    }

    function testCannotMintToZeroAddress() public {
        vm.expectRevert();

        token.mint(address(0), 100 ether);
    }

    function testTransferOwnership() public {
        address alice = address(0xA11CE);

        token.transferOwnership(alice);

        assertEq(token.owner(), alice);

        vm.prank(alice);
        token.mint(alice, 100 ether);

        assertEq(token.balanceOf(alice), 100 ether);
    }

    function testFuzzMint(uint256 amount) public {
        amount = bound(amount, 1, 1_000_000 ether);

        token.mint(address(0xB0B), amount);

        assertEq(token.balanceOf(address(0xB0B)), amount);

        assertEq(token.totalSupply(), amount);
    }

    function testFuzzTransferBetweenDifferentUsers(address from, address to, uint256 amount) public {
        vm.assume(from != address(0));
        vm.assume(to != address(0));
        vm.assume(from != to);

        amount = bound(amount, 1, 1_000_000 ether);

        token.mint(from, amount);

        vm.prank(from);
        token.transfer(to, amount);

        assertEq(token.balanceOf(from), 0);
        assertEq(token.balanceOf(to), amount);
    }
}
