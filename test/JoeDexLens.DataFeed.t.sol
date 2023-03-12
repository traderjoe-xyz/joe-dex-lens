// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "joe-v2/interfaces/ILBRouter.sol";

import "../src/JoeDexLens.sol";
import "./TestHelper.sol";

contract TestJoeDexLens is TestHelper {
    function setUp() public override {
        vm.createSelectFork(vm.rpcUrl("avalanche"), 27_354_769);
        super.setUp();

        MockAggregator aggregator = new MockAggregator();
        aggregator.setLatestAnswer(15e8);

        joeDexLens = new JoeDexLens(lbFactory, LBLegacyFactory, factoryV1, wNative);

        joeDexLens.setNativeDataFeed(address(aggregator));
    }

    function test_GetNativePrice() public {
        assertEq(joeDexLens.getNativePrice(), 15e18);
        assertEq(joeDexLens.getTokenPriceUSD(wNative), 15e18);
        assertEq(joeDexLens.getTokenPriceNative(wNative), 1e18);
    }

    function test_GetTokenPriceUsingNativeDataFeeds() public {
        joeDexLens.addDataFeed(USDC, IJoeDexLens.DataFeed(wNative, AVAX_USDC_V1, 1000, IJoeDexLens.DataFeedType.V1));

        assertApproxEqAbs(joeDexLens.getTokenPriceUSD(USDC), 1e18, 0.05e18);
        assertApproxEqAbs(joeDexLens.getTokenPriceNative(USDC), uint256(1e36) / 15e18, 0.05e18);

        joeDexLens.addDataFeed(USDC, IJoeDexLens.DataFeed(wNative, AVAX_USDC_20BP, 1000, IJoeDexLens.DataFeedType.V2));

        assertApproxEqAbs(joeDexLens.getTokenPriceUSD(USDC), 1e18, 0.05e18);
        assertApproxEqAbs(joeDexLens.getTokenPriceNative(USDC), uint256(1e36) / 15e18, 0.05e18);
    }

    function test_GetTokenPriceUsingDataFeeds() public {
        joeDexLens.addDataFeed(USDC, IJoeDexLens.DataFeed(JOE, JOE_USDC_25BP, 1000, IJoeDexLens.DataFeedType.V2));
        joeDexLens.addDataFeed(JOE, IJoeDexLens.DataFeed(wNative, JOE_AVAX_15BP, 1000, IJoeDexLens.DataFeedType.V2));

        assertApproxEqAbs(joeDexLens.getTokenPriceUSD(USDC), 1e18, 0.05e18);
        assertApproxEqAbs(joeDexLens.getTokenPriceNative(USDC), uint256(1e36) / 15e18, 0.05e18);

        joeDexLens.addDataFeed(USDC, IJoeDexLens.DataFeed(WETH, ETH_USDC_15BP, 1000, IJoeDexLens.DataFeedType.V2));
        joeDexLens.addDataFeed(WETH, IJoeDexLens.DataFeed(wNative, AVAX_ETH_10BP, 1000, IJoeDexLens.DataFeedType.V2));

        assertApproxEqAbs(joeDexLens.getTokenPriceUSD(USDC), 1e18, 0.05e18);
        assertApproxEqAbs(joeDexLens.getTokenPriceNative(USDC), uint256(1e36) / 15e18, 0.05e18);

        joeDexLens.addDataFeed(WETH, IJoeDexLens.DataFeed(wNative, AVAX_ETH_V1, 1000, IJoeDexLens.DataFeedType.V1));

        assertApproxEqAbs(joeDexLens.getTokenPriceUSD(USDC), 1e18, 0.05e18);
        assertApproxEqAbs(joeDexLens.getTokenPriceNative(USDC), uint256(1e36) / 15e18, 0.05e18);
    }
}
