// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "joe-v2/interfaces/ILBRouter.sol";
import "openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../src/JoeDexLens.sol";
import "./TestHelper.sol";

contract TestJoeDexLens is TestHelper {
    function setUp() public override {
        vm.createSelectFork(vm.rpcUrl("avalanche"), 27_354_769);
        super.setUp();

        MockAggregator aggregator = new MockAggregator();
        aggregator.setLatestAnswer(15e8);

        JoeDexLens imp = new JoeDexLens(lbFactory, LBLegacyFactory, factoryV1, wNative);

        joeDexLens = JoeDexLens(address(new TransparentUpgradeableProxy(address(imp), address(1), "")));
        joeDexLens.initialize(address(aggregator));
    }

    function test_GetNativePrice() public {
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

    function test_GetTokenPriceUsingFallback() public {
        // Will use (fallback: V2 USDC/AVAX, V1 USDC/AVAX) -> AVAX USDC oracle
        assertApproxEqAbs(joeDexLens.getTokenPriceUSD(USDC), 1e18, 0.05e18);

        joeDexLens.addDataFeed(USDC, IJoeDexLens.DataFeed(JOE, JOE_USDC_25BP, 1000, IJoeDexLens.DataFeedType.V2));

        // Will use V2 JOE/USDC -> (fallback: V2 JOE/AVAX, V1 JOE/AVAX) -> AVAX USDC oracle
        assertApproxEqAbs(joeDexLens.getTokenPriceUSD(USDC), 1e18, 0.05e18);

        joeDexLens.addDataFeed(USDC, IJoeDexLens.DataFeed(WETH, ETH_USDC_15BP, 1000, IJoeDexLens.DataFeedType.V2));

        // Will use:
        // (V2 JOE/USDC, V2 ETH/USDC)
        // -> (fallback joe/usdc: V2 JOE/AVAX, V1 JOE/AVAX, fallback eth/usdc: V2 ETH/AVAX, V1 ETH/AVAX)
        // -> AVAX USDC oracle
        assertApproxEqAbs(joeDexLens.getTokenPriceUSD(USDC), 1e18, 0.05e18);
    }

    function test_revert_BadDataFeeds() public {
        joeDexLens.addDataFeed(USDC, IJoeDexLens.DataFeed(JOE, JOE_USDC_25BP, 1000, IJoeDexLens.DataFeedType.V2));

        // Revert if a cycle is detected (USDC -> JOE -> USDC -> JOE -> ...)
        vm.expectRevert();
        joeDexLens.addDataFeed(JOE, IJoeDexLens.DataFeed(USDC, JOE_USDC_25BP, 1000, IJoeDexLens.DataFeedType.V2));

        address newToken = address(new ERC20MockDecimals(18));
        address pair = address(LBLegacyRouter.createLBPair(IERC20(newToken), IERC20(USDC), ID_ONE, DEFAULT_BIN_STEP));

        vm.expectRevert(IJoeDexLens.JoeDexLens__InvalidDataFeed.selector);
        joeDexLens.addDataFeed(USDC, IJoeDexLens.DataFeed(address(newToken), pair, 1000, IJoeDexLens.DataFeedType.V2));
    }

    function test_revert_AddingUnsetVersions() public {
        joeDexLens = new JoeDexLens(ILBFactory(address(0)), LBLegacyFactory, factoryV1, wNative);

        vm.expectRevert(IJoeDexLens.JoeDexLens__V2_1ContractNotSet.selector);
        joeDexLens.addDataFeed(
            address(0), IJoeDexLens.DataFeed(address(1), address(2), 0, IJoeDexLens.DataFeedType.V2_1)
        );

        joeDexLens = new JoeDexLens(lbFactory, ILBLegacyFactory(address(0)), factoryV1, wNative);

        vm.expectRevert(IJoeDexLens.JoeDexLens__V2ContractNotSet.selector);
        joeDexLens.addDataFeed(address(0), IJoeDexLens.DataFeed(address(1), address(2), 0, IJoeDexLens.DataFeedType.V2));

        joeDexLens = new JoeDexLens(lbFactory, LBLegacyFactory, IJoeFactory(address(0)), wNative);

        vm.expectRevert(IJoeDexLens.JoeDexLens__V1ContractNotSet.selector);
        joeDexLens.addDataFeed(address(0), IJoeDexLens.DataFeed(address(1), address(2), 0, IJoeDexLens.DataFeedType.V1));

        vm.expectRevert(IJoeDexLens.JoeDexLens__ZeroAddress.selector);
        new JoeDexLens(lbFactory, LBLegacyFactory, factoryV1, address(0));

        vm.expectRevert(IJoeDexLens.JoeDexLens__ZeroAddress.selector);
        new JoeDexLens(ILBFactory(address(0)), ILBLegacyFactory(address(0)), IJoeFactory(address(0)), wNative);
    }
}
