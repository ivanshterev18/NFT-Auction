// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ERC721TicketAuction} from "src/ERC721TicketAuction1.sol";
import {ERC721Ticket} from "src/ERC721Ticket.sol";
import {IERC721TicketAuction} from "src/interfaces/IERC721TicketAuction.sol";
import {MockNFT} from "./mocks/MockNFT.sol";
import {MockAdminWallet} from "./mocks/MockAdminWallet.sol";

contract ERC721TicketAuctionTest is Test {
    ERC721TicketAuction erc721TicketAuction;
    MockNFT mockNFT;
    MockAdminWallet adminWallet;
    address adminWalletAddress;

    address admin = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x2);

    uint256 tokenId1 = 0;
    uint256 tokenId2 = 1;
    uint256 reservePrice = 1 ether;
    uint256 duration = block.timestamp + 1 days;

    event LogAuctionState(uint256 auctionId, bool finalized, address highestBidder, uint256 highestBidAmount);

    function setUp() public {
        vm.startPrank(admin);
        vm.deal(admin, 100 ether);
        vm.deal(user1, 100 ether);
        
        mockNFT = new MockNFT();
        adminWallet = new MockAdminWallet();
        adminWalletAddress = address(adminWallet);
        erc721TicketAuction = new ERC721TicketAuction(address(mockNFT));
        
        mockNFT.mint();
        mockNFT.mint();
        vm.stopPrank();
    }

    function testCreateAuction() public {
        vm.startPrank(admin);
        mockNFT.approve(address(erc721TicketAuction), tokenId1);
        erc721TicketAuction.createAuction(tokenId1, reservePrice, duration);

        (address seller, uint256 reserve,,,,,,) = erc721TicketAuction.auctions(1);

        assertEq(seller, admin);
        assertEq(reservePrice, reserve);
        vm.stopPrank();
    }

    function testBid() public {
        vm.startPrank(admin);
        mockNFT.approve(address(erc721TicketAuction), tokenId1);
        erc721TicketAuction.createAuction(tokenId1, reservePrice, duration);

        vm.stopPrank();

        vm.startPrank(user1);
        erc721TicketAuction.bid{value: 1.5 ether}(1);

        (,, uint256 highestBidAmount, address highestBidder,,,,) = erc721TicketAuction.auctions(1);

        assertEq(highestBidder, user1, "Highest bidder should be user1");
        assertEq(highestBidAmount, 1.5 ether, "Highest bid amount should be 1.5 ether");

        vm.stopPrank();
    }

    function testGetAuctions() public {
        vm.startPrank(admin);
        mockNFT.approve(address(erc721TicketAuction), tokenId1);
        mockNFT.approve(address(erc721TicketAuction), tokenId1);
        mockNFT.approve(address(erc721TicketAuction), tokenId2);

        erc721TicketAuction.createAuction(tokenId1, 1 ether, 1 days);
        erc721TicketAuction.createAuction(tokenId2, 2 ether, 1 days);

        IERC721TicketAuction.Auction[] memory auctions = erc721TicketAuction.getAuctions();

        assertEq(auctions.length, 2, "Expected 2 auctions to be created");

        assertEq(auctions[0].reservePrice, 1 ether, "First auction reserve price mismatch");
        assertEq(auctions[0].tokenId, tokenId1, "First auction token ID mismatch");
        assertEq(auctions[0].seller, admin, "First auction seller mismatch");

        assertEq(auctions[1].reservePrice, 2 ether, "Second auction reserve price mismatch");
        assertEq(auctions[1].tokenId, tokenId2, "Second auction token ID mismatch");
        assertEq(auctions[1].seller, admin, "Second auction seller mismatch");
    }

    function testPlaceBidTimeExtended() public {
        uint256 duration = block.timestamp + 1 minutes;

        vm.startPrank(admin);
        mockNFT.approve(address(erc721TicketAuction), tokenId1);
        erc721TicketAuction.createAuction(tokenId1, reservePrice, duration);
        uint256 oldDuration = duration;


        vm.startPrank(user1);
        erc721TicketAuction.bid{value: 2 ether}(1);

        IERC721TicketAuction.Auction memory auction = erc721TicketAuction.getAuction(1);

        assertEq(auction.highestBidAmount, 2 ether);
        erc721TicketAuction.bid{value: 3 ether}(1);

        uint256 newDuration = auction.endTime;
        assertTrue(newDuration == oldDuration + 5 minutes, "Auction end time should be extended");

        vm.stopPrank();
    }

    function testGetAuctionBids() public {
        vm.startPrank(admin);
        mockNFT.approve(address(erc721TicketAuction), tokenId1);
        erc721TicketAuction.createAuction(tokenId1, reservePrice, duration);
        vm.stopPrank();

        vm.startPrank(user1);
        erc721TicketAuction.bid{value: 1.5 ether}(1);
        vm.stopPrank();

        vm.deal(user2, 2 ether);
        vm.startPrank(user2);
        erc721TicketAuction.bid{value: 2 ether}(1);
        vm.stopPrank();

        // Retrieve auction bids
        (address[] memory bidders, uint256[] memory amounts) = erc721TicketAuction.getAuctionBids(1);

        assertEq(bidders.length, 2, "Expected 2 bidders");
        assertEq(amounts.length, 2, "Expected 2 amounts");

        assertEq(bidders[0], user1, "First bidder should be user1");
        assertEq(bidders[1], user2, "Second bidder should be user2");
    }

    function testGetMyBid() public {
        vm.startPrank(admin);
        mockNFT.approve(address(erc721TicketAuction), tokenId1);
        erc721TicketAuction.createAuction(tokenId1, reservePrice, duration);
        vm.stopPrank();

        vm.startPrank(user1);
        erc721TicketAuction.bid{value: 1.5 ether}(1);

        IERC721TicketAuction.Bid memory myBid = erc721TicketAuction.getMyBid(0);

        assertEq(myBid.auctionId, 1, "Auction ID should match");
        assertEq(myBid.bidAmount, 1.5 ether, "Bid amount should match");
        assertTrue(myBid.endTime > block.timestamp, "End time should be in the future");
    }


    function testGetMyBids() public {
        vm.startPrank(admin);

        mockNFT.approve(address(erc721TicketAuction), tokenId1);
        erc721TicketAuction.createAuction(tokenId1, reservePrice, duration);
        
        mockNFT.approve(address(erc721TicketAuction), tokenId2);
        erc721TicketAuction.createAuction(tokenId2, reservePrice, duration);

        vm.stopPrank();

        vm.startPrank(user1);
        erc721TicketAuction.bid{value: 1.5 ether}(1);

        IERC721TicketAuction.Bid[] memory myBids = erc721TicketAuction.getMyBids();

        assertEq(myBids.length, 1, "User1 should have 1 bid");
        assertEq(myBids[0].auctionId, 1, "First bidder should be user1");
        assertEq(myBids[0].bidAmount, 1.5 ether, "First bid amount should be 1.5 ether");

        vm.stopPrank();
    }


    function testFinalizeAuction() public {
        uint256 tokenId = 2;

        vm.startPrank(adminWalletAddress);
        mockNFT.mint();
        
        mockNFT.approve(address(erc721TicketAuction), tokenId);
        erc721TicketAuction.createAuction(tokenId, reservePrice, duration);
        
        vm.stopPrank();

        vm.startPrank(user1);
        erc721TicketAuction.bid{value: 1.5 ether}(1);
        vm.stopPrank();

        vm.startPrank(adminWalletAddress);
        vm.warp(block.timestamp + duration + 2 days);
        erc721TicketAuction.finalizeAuction(1);

        IERC721TicketAuction.Auction memory auction = erc721TicketAuction.getAuction(1);

        assertTrue(auction.finalized, "Auction should be finalized");
        assertEq(mockNFT.ownerOf(tokenId), user1, "NFT should be owned by the highest bidder");
        vm.stopPrank();
    }
}
