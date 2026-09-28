// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract NFTMarketplaceTest is Test {
    MyNFT nft;
    NFTMarketplace marketplace;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        nft = new MyNFT();
        marketplace = new NFTMarketplace();

        nft.mint(alice, "ipfs://example/nft0.json");

        vm.deal(bob, 5 ether);
    }

    function testBuyNFT() public {
        vm.startPrank(alice);

        nft.approve(address(marketplace), 0);
        marketplace.listNFT(address(nft), 0, 1.1 ether);

        vm.stopPrank();

        uint256 aliceBalanceBefore = alice.balance;

        vm.prank(bob);
        marketplace.buyNFT{value: 1.1 ether}(address(nft), 0);

        // Bob recibe el NFT
        assertEq(nft.ownerOf(0), bob);

        // Alice todavía no ha cobrado
        assertEq(alice.balance, aliceBalanceBefore);

        // El marketplace le debe 1.1 ETH
        assertEq(marketplace.pendingWithdrawals(alice), 1.1 ether);

        // Alice reclama el dinero
        vm.prank(alice);
        marketplace.withdrawPayments();

        // Ahora sí cobra
        assertEq(alice.balance, aliceBalanceBefore + 1.1 ether);

        // Ya no queda nada pendiente
        assertEq(marketplace.pendingWithdrawals(alice), 0);
    }

    function testCannotBuyWithWrongPrice() public {
        vm.startPrank(alice);

        nft.approve(address(marketplace), 0);
        marketplace.listNFT(address(nft), 0, 2 ether);

        vm.stopPrank();

        vm.prank(bob);
        vm.expectRevert("Incorrect price");

        marketplace.buyNFT{value: 1 ether}(address(nft), 0);
    }

    function testSellerCanCancelListing() public {
        vm.startPrank(alice);

        nft.approve(address(marketplace), 0);
        marketplace.listNFT(address(nft), 0, 2 ether);

        marketplace.cancelListing(address(nft), 0);

        vm.stopPrank();

        (address seller, uint256 price) = marketplace.listings(address(nft), 0);

        assertEq(seller, address(0));
        assertEq(price, 0);
    }

    function testOnlySellerCanCancelListing() public {
        vm.startPrank(alice);

        nft.approve(address(marketplace), 0);
        marketplace.listNFT(address(nft), 0, 2 ether);

        vm.stopPrank();

        vm.prank(bob);
        vm.expectRevert("Not seller");

        marketplace.cancelListing(address(nft), 0);
    }

    function testSellerCanUpdatePrice() public {
        vm.startPrank(alice);

        nft.approve(address(marketplace), 0);
        marketplace.listNFT(address(nft), 0, 2 ether);

        marketplace.updatePrice(address(nft), 0, 3 ether);

        (address seller, uint256 price) = marketplace.listings(address(nft), 0);

        assertEq(seller, alice);
        assertEq(price, 3 ether);

        vm.stopPrank();
    }

    function testNFTCannotBeBoughtTwice() public {
        address carlos = address(0xCA12);

        vm.deal(carlos, 5 ether);

        vm.startPrank(alice);

        nft.approve(address(marketplace), 0);
        marketplace.listNFT(address(nft), 0, 2 ether);

        vm.stopPrank();

        // Bob compra primero
        vm.prank(bob);
        marketplace.buyNFT{value: 2 ether}(address(nft), 0);

        // Carlos intenta comprar el mismo NFT
        vm.prank(carlos);
        vm.expectRevert("NFT not listed");

        marketplace.buyNFT{value: 2 ether}(address(nft), 0);

        assertEq(nft.ownerOf(0), bob);
    }

    function testCannotBuyIfSellerNoLongerOwnsNFT() public {
        address carlos = address(0xCA12);

        vm.startPrank(alice);

        nft.approve(address(marketplace), 0);
        marketplace.listNFT(address(nft), 0, 2 ether);

        nft.transferFrom(alice, carlos, 0);

        vm.stopPrank();

        vm.prank(bob);
        vm.expectRevert("Seller no longer owns NFT");

        marketplace.buyNFT{value: 2 ether}(address(nft), 0);
    }

    function testReentrancyAttackOnWithdrawFails() public {
        ReentrantSeller attacker = new ReentrantSeller(marketplace, nft);

        nft.mint(address(attacker), "ipfs://example/attacker.json");

        // El #0 ya pertenece a Alice, así que attacker recibe el #1
        attacker.list(1, 2 ether);

        vm.prank(bob);
        marketplace.buyNFT{value: 2 ether}(address(nft), 1);

        assertEq(marketplace.pendingWithdrawals(address(attacker)), 2 ether);

        attacker.withdraw();

        assertEq(address(attacker).balance, 2 ether);

        assertEq(marketplace.pendingWithdrawals(address(attacker)), 0);

        assertTrue(attacker.attemptedReentrancy());
    }
}

contract ReentrantSeller is ERC721Holder {
    NFTMarketplace public marketplace;
    MyNFT public nft;

    bool public attemptedReentrancy;

    constructor(NFTMarketplace _marketplace, MyNFT _nft) {
        marketplace = _marketplace;
        nft = _nft;
    }

    function list(uint256 tokenId, uint256 price) external {
        nft.approve(address(marketplace), tokenId);
        marketplace.listNFT(address(nft), tokenId, price);
    }

    function withdraw() external {
        marketplace.withdrawPayments();
    }

    receive() external payable {
        if (!attemptedReentrancy) {
            attemptedReentrancy = true;

            try marketplace.withdrawPayments() {
            // Si funcionase, habría reentrado.
            }
                catch {
                // nonReentrant bloquea el segundo withdraw.
            }
        }
    }
}
