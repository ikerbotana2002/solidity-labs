// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

import {MyTokenOZ} from "../src/MyTokenOZ.sol";

contract MyTokenHandler is Test {
    MyTokenOZ public token;

    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    constructor(MyTokenOZ _token) {
        token = _token;
    }

    function mintToAlice(uint256 amount) external {
        amount = bound(amount, 1, 1_000_000 ether);
        token.mint(alice, amount);
    }

    function mintToBob(uint256 amount) external {
        amount = bound(amount, 1, 1_000_000 ether);
        token.mint(bob, amount);
    }

    function transferAliceToBob(uint256 amount) external {
        uint256 balance = token.balanceOf(alice);

        if (balance == 0) return;

        amount = bound(amount, 1, balance);

        vm.prank(alice);
        token.transfer(bob, amount);
    }

    function transferBobToAlice(uint256 amount) external {
        uint256 balance = token.balanceOf(bob);

        if (balance == 0) return;

        amount = bound(amount, 1, balance);

        vm.prank(bob);
        token.transfer(alice, amount);
    }
}

contract MyTokenInvariantTest is StdInvariant, Test {
    MyTokenOZ token;
    MyTokenHandler handler;

    function setUp() public {
        token = new MyTokenOZ();

        handler = new MyTokenHandler(token);

        // El owner del token pasa a ser el Handler,
        // así puede ejecutar mint()
        token.transferOwnership(address(handler));

        // Foundry atacará las funciones del Handler
        targetContract(address(handler));
    }

    function invariant_TotalSupplyEqualsBalances() public view {
        uint256 balances = token.balanceOf(handler.alice()) + token.balanceOf(handler.bob());

        assertEq(token.totalSupply(), balances);
    }
}
