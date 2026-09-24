// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyNFT} from "../src/MyNFT.sol";

contract MyNFTTest is Test {
    MyNFT nft;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        nft = new MyNFT();
    }

    function testMintCreatesDifferentNFTs() public {
        nft.mint(alice, "ipfs://example/nft0.json");
        nft.mint(bob, "ipfs://example/nft1.json");

        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.ownerOf(1), bob);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.balanceOf(bob), 1);
    }

    function testTransferNFT() public {
        nft.mint(alice, "ipfs://example/nft0.json");

        vm.prank(alice);
        nft.transferFrom(alice, bob, 0);

        assertEq(nft.ownerOf(0), bob);
        assertEq(nft.balanceOf(alice), 0);
        assertEq(nft.balanceOf(bob), 1);
    }

    function testApproveAndTransferNFT() public {
        nft.mint(alice, "ipfs://example/nft0.json");

        vm.prank(alice);
        nft.approve(bob, 0);

        vm.prank(bob);
        nft.transferFrom(alice, bob, 0);

        assertEq(nft.ownerOf(0), bob);
    }

    function testMintStoresTokenURI() public {
        string memory uri = "ipfs://example/nft0.json";

        nft.mint(alice, uri);

        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.tokenURI(0), uri);
    }

    function testTransferKeepsTokenURI() public {
        string memory uri = "ipfs://example/nft0.json";

        nft.mint(alice, uri);

        vm.prank(alice);
        nft.transferFrom(alice, bob, 0);

        assertEq(nft.ownerOf(0), bob);
        assertEq(nft.tokenURI(0), uri);
    }

    function testOwnerCanBurnNFT() public {
        nft.mint(alice, "ipfs://example/nft0.json");

        vm.prank(alice);
        nft.burn(0);

        vm.expectRevert();
        nft.ownerOf(0);
    }
}
