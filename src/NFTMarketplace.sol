// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ReentrancyGuard, Pausable, Ownable {
    constructor() Ownable(msg.sender) {}

    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(address => uint256) public pendingWithdrawals;

    event NFTListed(address indexed nftAddress, uint256 indexed tokenId, address indexed seller, uint256 price);

    event NFTPurchased(address indexed nftAddress, uint256 indexed tokenId, address indexed buyer, uint256 price);

    event ListingCancelled(address indexed nftAddress, uint256 indexed tokenId, address indexed seller);

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function listNFT(address nftAddress, uint256 tokenId, uint256 price) external whenNotPaused {
        IERC721 nft = IERC721(nftAddress);

        require(nft.ownerOf(tokenId) == msg.sender, "Not NFT owner");

        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            "Marketplace not approved"
        );

        require(price > 0, "Invalid price");

        listings[nftAddress][tokenId] = Listing({seller: msg.sender, price: price});

        emit NFTListed(nftAddress, tokenId, msg.sender, price);
    }

    function buyNFT(address nftAddress, uint256 tokenId) external payable nonReentrant whenNotPaused {
        Listing memory listing = listings[nftAddress][tokenId];

        require(listing.seller != address(0), "NFT not listed");

        require(msg.value == listing.price, "Incorrect price");

        IERC721 nft = IERC721(nftAddress);

        require(nft.ownerOf(tokenId) == listing.seller, "Seller no longer owns NFT");

        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(listing.seller, address(this)),
            "Marketplace no longer approved"
        );

        delete listings[nftAddress][tokenId];

        nft.safeTransferFrom(listing.seller, msg.sender, tokenId);

        pendingWithdrawals[listing.seller] += msg.value;

        emit NFTPurchased(nftAddress, tokenId, msg.sender, listing.price);
    }

    function withdrawPayments() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];

        require(amount > 0, "No pending payments");

        pendingWithdrawals[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: amount}("");

        require(success, "Payment failed");
    }

    function cancelListing(address nftAddress, uint256 tokenId) external {
        Listing memory listing = listings[nftAddress][tokenId];

        require(listing.seller == msg.sender, "Not seller");

        delete listings[nftAddress][tokenId];

        emit ListingCancelled(nftAddress, tokenId, msg.sender);
    }

    function updatePrice(address nftAddress, uint256 tokenId, uint256 newPrice) external {
        Listing storage listing = listings[nftAddress][tokenId];

        require(listing.seller == msg.sender, "Not seller");

        require(newPrice > 0, "Invalid price");

        listing.price = newPrice;
    }
}
