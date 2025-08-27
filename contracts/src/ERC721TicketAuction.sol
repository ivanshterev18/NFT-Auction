// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC721TicketAuction} from "src/interfaces/IERC721TicketAuction.sol";
import {IERC721TicketAuctionErrors} from "src/interfaces/IERC721TicketAuctionErrors.sol";

contract ERC721TicketAuction is IERC721TicketAuction, IERC721TicketAuctionErrors, ReentrancyGuard {
    IERC721 public immutable ERC721_TICKET_CONTRACT;

    uint256 public auctionCount;
    mapping(uint256 => mapping(address => uint256)) public bidsPerAddress;
    mapping(uint256 => address[]) public auctionBidders;
    mapping(uint256 => Auction) public auctions;
    mapping(address => Bid[]) public bids;
    mapping(uint256 => mapping(address => uint256)) public outbidded;

    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 initialPrice,
        uint256 endTime
    );
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 bidAmount, uint256 endTime);
    event AuctionFinalized(uint256 indexed auctionId, address indexed winner, uint256 finalPrice, bool hasWinner);
    event AuctionExtended(uint256 indexed auctionId, uint256 newEndTime);

    constructor(address contractAddress) {
        ERC721_TICKET_CONTRACT = IERC721(contractAddress);
    }

    /// @notice Creates a new auction for a specific NFT.
    /// @param tokenId The ID of the NFT to auction.
    /// @param initialPrice The initial price for the auction.
    /// @param duration The duration of the auction in seconds.
    function createAuction(uint256 tokenId, uint256 initialPrice, uint256 duration) external {
        if (initialPrice <= 0) revert InitialPriceMustBeGreaterThanZero();
        if (duration <= 0) revert DurationMustBeGreaterThanZero();

        uint256 endTime = duration + block.timestamp;

        ERC721_TICKET_CONTRACT.transferFrom(msg.sender, address(this), tokenId);

        auctionCount++;

        auctions[auctionCount] = Auction({
            seller: msg.sender,
            initialPrice: initialPrice,
            highestBidAmount: 0,
            highestBidder: address(0),
            endTime: endTime,
            finalized: false,
            tokenId: tokenId,
            id: auctionCount
        });

        emit AuctionCreated(auctionCount, msg.sender, tokenId, initialPrice, endTime);
    }

    /// @notice Places a bid on an ongoing auction.
    /// @param auctionId The ID of the auction to bid on.
    function bid(uint256 auctionId) external payable nonReentrant {
        Auction storage auction = auctions[auctionId];
        if (block.timestamp >= auction.endTime) revert AuctionHasEnded();
        if (msg.value <= auction.highestBidAmount || msg.value < auction.initialPrice) {
            revert BidMustBeHigherThanCurrentHighestBidAndInitialPrice();
        }
        if (msg.sender == auction.seller) revert CannotBidOnOwnAuction();

        // Refund the previous highest bidder if there is one
        if (auction.highestBidder != address(0)) {
            uint256 previousBidAmount = auction.highestBidAmount;
            payable(auction.highestBidder).transfer(previousBidAmount);
        }

        if (auction.endTime - block.timestamp < 2 minutes) {
            auction.endTime += 5 minutes;
            emit AuctionExtended(auctionId, auction.endTime);
        }

        auction.highestBidder = msg.sender;
        auction.highestBidAmount = msg.value;

        bidsPerAddress[auctionId][msg.sender] = msg.value;
        auctionBidders[auctionId].push(msg.sender);

        Bid memory newBid = Bid({auctionId: auctionId, bidAmount: msg.value, endTime: auction.endTime});
        bids[msg.sender].push(newBid);

        emit BidPlaced(auctionId, msg.sender, msg.value, auction.endTime);
    }

    /// @notice Finalizes the auction, transferring the NFT and funds.
    /// @param auctionId The ID of the auction to finalize.
    function finalizeAuction(uint256 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];

        if (block.timestamp < auction.endTime) revert AuctionNotEndedYet();
        if (auction.finalized) revert AuctionAlreadyFinalized();
        if (msg.sender != auction.seller) revert NotTheSellerOfThisAuction();

        // All state changes first
        auction.finalized = true;

        // External calls after all state changes
        if (auction.highestBidder != address(0)) {
            // Transfer funds to the seller
            payable(auction.seller).transfer(auction.highestBidAmount);

            // Transfer the NFT to the winner
            ERC721_TICKET_CONTRACT.transferFrom(address(this), auction.highestBidder, auction.tokenId);

            emit AuctionFinalized(auctionId, auction.highestBidder, auction.highestBidAmount, true);
        } else {
            // If no bids were placed, return the NFT to the seller
            ERC721_TICKET_CONTRACT.transferFrom(address(this), auction.seller, auction.tokenId);

            emit AuctionFinalized(auctionId, address(0), 0, false);
        }
    }

    /// @notice Retrieves the list of bidders and their bid amounts for a specific auction.
    /// @param auctionId The ID of the auction to query.
    /// @return bidders An array of addresses of bidders.
    /// @return amounts An array of bid amounts corresponding to the bidders.
    function getAuctionBids(uint256 auctionId) external view returns (address[] memory, uint256[] memory) {
        address[] memory bidders = auctionBidders[auctionId];
        uint256[] memory amounts = new uint256[](bidders.length);

        for (uint256 i = 0; i < bidders.length; i++) {
            amounts[i] = bidsPerAddress[auctionId][bidders[i]];
        }

        return (bidders, amounts);
    }

    /// @notice Retrieves all auctions created.
    /// @return allAuctions An array of all auctions.
    function getAuctions() external view returns (Auction[] memory) {
        Auction[] memory allAuctions = new Auction[](auctionCount);
        for (uint256 i = 0; i < auctionCount; i++) {
            allAuctions[i] = auctions[i + 1];
        }
        return allAuctions;
    }

    /// @notice Retrieves details of a specific auction.
    /// @param auctionId The ID of the auction to retrieve.
    /// @return The auction details.
    function getAuction(uint256 auctionId) external view returns (Auction memory) {
        return auctions[auctionId];
    }

    /// @notice Retrieves the user's bid for a specific auction.
    /// @param auctionId The ID of the auction to query.
    /// @return The user's bid details.
    function getMyBid(uint256 auctionId) external view returns (Bid memory) {
        return bids[msg.sender][auctionId];
    }

    /// @notice Retrieves all bids made by the user.
    /// @return An array of the user's bids.
    function getMyBids() external view returns (Bid[] memory) {
        return bids[msg.sender];
    }
}
