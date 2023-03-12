// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../src/interfaces/AggregatorV3Interface.sol";

/// @title MockAggregator
/// @author Trader Joe
/// @dev ONLY FOR TESTS
contract MockAggregator is AggregatorV3Interface {
    int256 price = 1e8;

    function decimals() external pure returns (uint8) {
        return 8;
    }

    function description() external pure returns (string memory) {
        return "Mock Aggregator";
    }

    function version() external pure returns (uint256) {
        return 0;
    }

    function getRoundData(uint80)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return latestRoundData();
    }

    function latestRoundData()
        public
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        roundId = 123;
        answer = price;
        startedAt = block.timestamp;
        updatedAt = block.timestamp;
        answeredInRound = 123;
    }

    function setLatestAnswer(int256 _price) external {
        price = _price;
    }
}
