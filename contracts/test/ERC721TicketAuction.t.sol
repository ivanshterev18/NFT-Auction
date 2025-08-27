// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {ERC721TicketAuction} from "src/ERC721TicketAuction.sol";
import {ERC721Ticket} from "src/ERC721Ticket.sol";
import {IERC721TicketAuction} from "src/interfaces/IERC721TicketAuction.sol";
import {IERC721TicketAuctionErrors} from "src/interfaces/IERC721TicketAuctionErrors.sol";
import {MockNFT} from "./mocks/MockNFT.sol";
import {MockAdminWallet} from "./mocks/MockAdminWallet.sol";

contract ERC721TicketAuctionTest is Test {
    ERC721TicketAuction erc721TicketAuction;
    MockNFT mockNFT;
    MockAdminWallet adminWallet;
    address adminWalletAddress;

    address admin = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);

    uint256 tokenId1 = 0;
    uint256 tokenId2 = 1;
    uint256 initialPrice = 1 ether;
    uint256 duration = 1 days;

    event LogAuctionState(uint256 auctionId, bool finalized, address highestBidder, uint256 highestBidAmount);

    function setUp() public {
        vm.startPrank(admin);
        vm.deal(admin, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);

        mockNFT = new MockNFT();
        adminWallet = new MockAdminWallet();
        adminWalletAddress = address(adminWallet);
        erc721TicketAuction = new ERC721TicketAuction(address(mockNFT));

        mockNFT.mint();
        mockNFT.mint();
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

        assertEq(auctions[0].initialPrice, 1 ether, "First auction initial price mismatch");
        assertEq(auctions[0].tokenId, tokenId1, "First auction token ID mismatch");
        assertEq(auctions[0].seller, admin, "First auction seller mismatch");

        assertEq(auctions[1].initialPrice, 2 ether, "Second auction initial price mismatch");
        assertEq(auctions[1].tokenId, tokenId2, "Second auction token ID mismatch");
        assertEq(auctions[1].seller, admin, "Second auction seller mismatch");
    }

    function testPlaceBidTimeExtended() public {
        duration = 1 minutes;

        vm.startPrank(admin);
        mockNFT.approve(address(erc721TicketAuction), tokenId1);
        erc721TicketAuction.createAuction(tokenId1, initialPrice, duration);

        uint256 originalEndTime = erc721TicketAuction.getAuction(1).endTime;

        vm.startPrank(user1);
        erc721TicketAuction.bid{value: 2 ether}(1);

        IERC721TicketAuction.Auction memory auction = erc721TicketAuction.getAuction(1);

        assertEq(auction.highestBidAmount, 2 ether);
        erc721TicketAuction.bid{value: 3 ether}(1);

        assertEq(auction.endTime, originalEndTime + 5 minutes, "Auction end time should be extended");

        vm.stopPrank();
    }

    function testGetAuctionBids() public {
        vm.startPrank(admin);
        mockNFT.approve(address(erc721TicketAuction), tokenId1);
        erc721TicketAuction.createAuction(tokenId1, initialPrice, duration);
        vm.stopPrank();

        vm.startPrank(user1);
        erc721TicketAuction.bid{value: 1.5 ether}(1);
        vm.stopPrank();

        vm.deal(user2, 2 ether);
        vm.startPrank(user2);
        erc721TicketAuction.bid{value: 2 ether}(1);
        vm.stopPrank();

        (address[] memory bidders, uint256[] memory amounts) = erc721TicketAuction.getAuctionBids(1);

        assertEq(bidders.length, 2, "Expected 2 bidders");
        assertEq(amounts.length, 2, "Expected 2 amounts");

        assertEq(bidders[0], user1, "First bidder should be user1");
        assertEq(bidders[1], user2, "Second bidder should be user2");
    }

    function testGetMyBid() public {
        vm.startPrank(admin);
        mockNFT.approve(address(erc721TicketAuction), tokenId1);
        erc721TicketAuction.createAuction(tokenId1, initialPrice, duration);
        vm.stopPrank();

        vm.startPrank(user1);
        erc721TicketAuction.bid{value: 1.5 ether}(1);

        IERC721TicketAuction.Bid memory myBid = erc721TicketAuction.getMyBid(0);

        assertEq(myBid.auctionId, 1, "Auction ID should match");
        assertEq(myBid.bidAmount, 1.5 ether, "Bid amount should match");
        assertTrue(myBid.endTime > block.timestamp, "End time should be in the future");
    }

    function testGetMyBidsWithNoBids() public {
        vm.startPrank(user2);
        IERC721TicketAuction.Bid[] memory myBids = erc721TicketAuction.getMyBids();
        assertEq(myBids.length, 0, "User2 should have 0 bids");
        vm.stopPrank();
    }

    function testFinalizeAuction() public {
        uint256 tokenId = 2;

        vm.startPrank(adminWalletAddress);
        mockNFT.mint();

        mockNFT.approve(address(erc721TicketAuction), tokenId);
        erc721TicketAuction.createAuction(tokenId, initialPrice, duration);

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

    function testCreateAuctionWithZeroInitialPrice() public {
        vm.startPrank(admin);
        mockNFT.approve(address(erc721TicketAuction), tokenId1);

        vm.expectRevert(IERC721TicketAuctionErrors.InitialPriceMustBeGreaterThanZero.selector);
        erc721TicketAuction.createAuction(tokenId1, 0, duration);
        vm.stopPrank();
    }

    function testCreateAuctionWithZeroDuration() public {
        vm.startPrank(admin);
        mockNFT.approve(address(erc721TicketAuction), tokenId1);

        vm.expectRevert(IERC721TicketAuctionErrors.DurationMustBeGreaterThanZero.selector);
        erc721TicketAuction.createAuction(tokenId1, initialPrice, 0);
        vm.stopPrank();
    }

    function testBidBelowHighestBid() public {
        vm.startPrank(admin);
        mockNFT.approve(address(erc721TicketAuction), tokenId1);
        erc721TicketAuction.createAuction(tokenId1, initialPrice, duration);
        vm.stopPrank();

        vm.startPrank(user1);
        erc721TicketAuction.bid{value: 1.5 ether}(1);
        vm.stopPrank();

        vm.startPrank(user2);
        vm.expectRevert(IERC721TicketAuctionErrors.BidMustBeHigherThanCurrentHighestBidAndInitialPrice.selector);
        erc721TicketAuction.bid{value: 1.4 ether}(1);
        vm.stopPrank();
    }

    function testSellerCannotBidOnOwnAuction() public {
        vm.startPrank(admin);
        mockNFT.approve(address(erc721TicketAuction), tokenId1);
        erc721TicketAuction.createAuction(tokenId1, initialPrice, duration);
        vm.stopPrank();

        vm.startPrank(admin);
        vm.expectRevert(IERC721TicketAuctionErrors.CannotBidOnOwnAuction.selector);
        erc721TicketAuction.bid{value: 2 ether}(1);
        vm.stopPrank();
    }

    function testFinalizeAuctionBeforeEndTime() public {
        vm.startPrank(admin);
        mockNFT.approve(address(erc721TicketAuction), tokenId1);
        erc721TicketAuction.createAuction(tokenId1, initialPrice, duration);
        vm.stopPrank();

        vm.startPrank(admin);
        vm.expectRevert(IERC721TicketAuctionErrors.AuctionNotEndedYet.selector);
        erc721TicketAuction.finalizeAuction(1);
        vm.stopPrank();
    }

    function testFinalizeAuctionTwice() public {
        vm.startPrank(admin);
        mockNFT.approve(address(erc721TicketAuction), tokenId1);
        erc721TicketAuction.createAuction(tokenId1, initialPrice, duration);
        vm.stopPrank();

        vm.warp(block.timestamp + duration + 1);

        vm.startPrank(admin);
        erc721TicketAuction.finalizeAuction(1);

        vm.expectRevert();
        erc721TicketAuction.finalizeAuction(1);
        vm.stopPrank();
    }

    function testBidOnNonExistentAuction() public {
        vm.startPrank(user1);
        vm.expectRevert();
        erc721TicketAuction.bid{value: 1.5 ether}(999);
        vm.stopPrank();
    }

    function testFinalizeNonExistentAuction() public {
        vm.startPrank(admin);
        vm.expectRevert();
        erc721TicketAuction.finalizeAuction(999);
        vm.stopPrank();
    }
}
