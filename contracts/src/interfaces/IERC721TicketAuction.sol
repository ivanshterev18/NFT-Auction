// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IERC721TicketAuction {
    struct Auction {
        address seller;
        uint256 initialPrice;
        uint256 highestBidAmount;
        address highestBidder;
        uint256 endTime;
        bool finalized;
        uint256 tokenId;
        uint256 id;
    }

    struct Bid {
        uint256 auctionId;
        uint256 bidAmount;
        uint256 endTime;
    }

    struct SupportedToken {
        address token;
        string symbol;
    }

    function bid(uint256 auctionId) external payable;
    function finalizeAuction(uint256 auctionId) external;
    function getAuction(uint256 auctionId) external view returns (Auction memory);
    function getAuctions() external view returns (Auction[] memory);
    function getMyBid(uint256 auctionId) external view returns (Bid memory);
    function getMyBids() external view returns (Bid[] memory);
}
