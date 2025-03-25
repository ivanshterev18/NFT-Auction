// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721TicketAuction} from "src/interfaces/IERC721TicketAuction.sol";
import {IERC721TicketAuctionErrors} from "src/interfaces/IERC721TicketAuctionErrors.sol";

contract ERC721TicketAuction is IERC721TicketAuction, IERC721TicketAuctionErrors {
    IERC721 public immutable CONTRACT_ADDRESS;

    uint256 public auctionCount;
    mapping(uint256 => mapping(address => uint256)) public bidsPerAddress;
    mapping(uint256 => address[]) public auctionBidders;
    mapping(uint256 => Auction) public auctions;

    mapping(address => Bid[]) public bids;
    mapping(uint256 => mapping(address => uint256)) public outbidded;

    constructor(address _contractAddress) {
        CONTRACT_ADDRESS = IERC721(_contractAddress);
    }

    /// @notice Creates a new auction for a specific NFT.
    /// @param tokenId The ID of the NFT to auction.
    /// @param reservePrice The minimum price for the auction.
    /// @param duration The end time of the auction.
    function createAuction(uint256 tokenId, uint256 reservePrice, uint256 duration) external {
        if (reservePrice <= 0) revert ReservePriceMustBeGreaterThanZero();

        CONTRACT_ADDRESS.transferFrom(msg.sender, address(this), tokenId);

        auctionCount++;
        if (duration <= block.timestamp) revert EndTimeMustBeInTheFuture();

        auctions[auctionCount] = Auction({
            seller: msg.sender,
            reservePrice: reservePrice,
            highestBidAmount: 0,
            highestBidder: address(0),
            endTime: duration,
            finalized: false,
            tokenId: tokenId,
            id: auctionCount
        });
    }

    /// @notice Places a bid on an ongoing auction.
    /// @param auctionId The ID of the auction to bid on.
    function bid(uint256 auctionId) external payable {
        Auction storage auction = auctions[auctionId];
        if (block.timestamp >= auction.endTime) revert AuctionHasEnded();
        if (msg.value <= auction.highestBidAmount || msg.value < auction.reservePrice) {
            revert BidMustBeHigherThanCurrentHighestBidAndReservePrice();
        }
        if (msg.sender == auction.seller) revert CannotBidOnOwnAuction();

        // Refund the previous highest bidder if there is one
        if (auction.highestBidder != address(0)) {
            uint256 previousBidAmount = auction.highestBidAmount;
            outbidded[auctionId][auction.highestBidder] += previousBidAmount;
        }

        if (auction.endTime - block.timestamp < 2 minutes) {
            auction.endTime += 5 minutes;
        }

        auction.highestBidder = msg.sender;
        auction.highestBidAmount = msg.value;

        bidsPerAddress[auctionId][msg.sender] = msg.value;
        auctionBidders[auctionId].push(msg.sender);

        Bid memory newBid = Bid({auctionId: auctionId, bidAmount: msg.value, endTime: auction.endTime});
        bids[msg.sender].push(newBid);
    }

    /// @notice Finalizes the auction, transferring the NFT and funds.
    /// @param auctionId The ID of the auction to finalize.
    function finalizeAuction(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        if (block.timestamp < auction.endTime) revert AuctionHasEnded();
        if (auction.finalized) revert AuctionAlreadyFinalized();
        if (msg.sender != auction.seller) revert NotTheSellerOfThisAuction();

        auction.finalized = true;

        if (auction.highestBidder != address(0)) {
            // Transfer funds to the seller
            payable(auction.seller).transfer(auction.highestBidAmount);

            // Transfer the NFT to the winner
            CONTRACT_ADDRESS.transferFrom(address(this), auction.highestBidder, auction.tokenId);
        } else {
            // If no bids were placed, return the NFT to the seller
            CONTRACT_ADDRESS.transferFrom(address(this), auction.seller, auction.tokenId);
        }

        // Refund non-winners
        for (uint256 i = 0; i < auctionBidders[auctionId].length; i++) {
            address bidder = auctionBidders[auctionId][i];
            uint256 bidAmount = outbidded[auctionId][bidder];
            if (bidAmount > 0) {
                payable(bidder).transfer(bidAmount);
                outbidded[auctionId][bidder] = 0;
            }
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
