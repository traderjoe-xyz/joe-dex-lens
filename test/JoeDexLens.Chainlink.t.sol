// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TestHelper.sol";
import "./mocks/MockAggregator.sol";

contract TestChainlink is TestHelper {
    MockAggregator aggregator;
    address token;

    function setUp() public override {
        vm.createSelectFork(vm.rpcUrl("fuji"), 14_541_000);
        super.setUp();

        token = address(new ERC20MockDecimals(18));

        joeDexLens = new JoeDexLens(lbRouter, lbFactory, LBLegacyRouter, LBLegacyFactory, joeFactory, wNative, USDC);
        aggregator = new MockAggregator();
    }

    function test_ChainlinkUSDPrice() public {
        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(address(aggregator), 1, IJoeDexLens.dfType.CHAINLINK);
        joeDexLens.addUSDDataFeed(token, df);

        assertEq(joeDexLens.getTokenPriceUSD(token), 1e6);
    }

    function test_ChainlinkWNativePrice() public {
        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(address(aggregator), 1, IJoeDexLens.dfType.CHAINLINK);
        joeDexLens.addNativeDataFeed(token, df);

        assertEq(joeDexLens.getTokenPriceNative(token), 1e18);
    }
}
