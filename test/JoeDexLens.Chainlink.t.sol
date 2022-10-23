// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TestHelper.sol";
import "./mocks/MockAggregator.sol";

contract TestChainlink is TestHelper {
    MockAggregator aggregator;
    address token;

    function setUp() public {
        address MockUSDC = address(new ERC20MockDecimals(6));
        address MockWAVAX = address(new ERC20MockDecimals(18));

        token = address(new ERC20MockDecimals(18));

        joeDexLens = new JoeDexLens(LBRouter, joeFactory, MockWAVAX, MockUSDC);
        aggregator = new MockAggregator();
    }

    function testChainlinkUSDPrice() public {
        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(address(aggregator), 1, IJoeDexLens.dfType.CHAINLINK);
        joeDexLens.addUSDDataFeed(token, df);

        assertEq(joeDexLens.getTokenPriceUSD(token), 1e6);
    }

    function testChainlinkWavaxPrice() public {
        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(address(aggregator), 1, IJoeDexLens.dfType.CHAINLINK);
        joeDexLens.addAVAXDataFeed(token, df);

        assertEq(joeDexLens.getTokenPriceAVAX(token), 1e18);
    }
}
