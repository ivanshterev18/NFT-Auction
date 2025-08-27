// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IERC721TicketErrors {
    error NotWhitelisted();
    error InsufficientFunds();
    error PriceFeedNotSet(address token);
    error InvalidETHPrice();
    error TokenTransferFailed();
    error MintPriceMustBeGreaterThanZero();
}
