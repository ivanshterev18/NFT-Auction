// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IERC721TicketAuctionErrors {
    error InitialPriceMustBeGreaterThanZero();
    error AuctionHasEnded();
    error DurationMustBeGreaterThanZero();
    error AuctionNotEndedYet();
    error BidMustBeHigherThanCurrentHighestBidAndInitialPrice();
    error CannotBidOnOwnAuction();
    error AuctionAlreadyFinalized();
    error NotTheSellerOfThisAuction();
}
