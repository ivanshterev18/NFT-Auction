// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IERC721TicketAuctionErrors {
    error ReservePriceMustBeGreaterThanZero();
    error EndTimeMustBeInTheFuture();
    error AuctionHasEnded();
    error BidMustBeHigherThanCurrentHighestBidAndReservePrice();
    error CannotBidOnOwnAuction();
    error AuctionAlreadyFinalized();
    error NotTheSellerOfThisAuction();
}
