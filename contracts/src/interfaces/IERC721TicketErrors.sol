// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IERC721TicketErrors {
    error NotWhitelisted();
    error InsufficientFunds();
    error PriceFeedNotSet(address token);
    error InvalidETHPrice();
    error TokenTransferFailed();
}
