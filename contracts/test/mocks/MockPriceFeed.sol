// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MockAggregatorV3 is AggregatorV3Interface {
    int256 private price;
    uint8 private _decimals;

    constructor(int256 _initialPrice, uint8 decimals_) {
        price = _initialPrice;
        _decimals = decimals_;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function description() external pure override returns (string memory) {
        return "Mock Aggregator";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 /*_roundId*/ )
        external
        pure
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (0, 0, 0, 0, 0);
    }

    function latestRoundData() external view override returns (uint80, int256, uint256, uint256, uint80) {
        return (0, price, block.timestamp, block.timestamp, 0);
    }

    function updatePrice(int256 _newPrice) external {
        price = _newPrice;
    }
}
