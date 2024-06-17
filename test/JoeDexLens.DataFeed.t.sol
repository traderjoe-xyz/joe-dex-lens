// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "joe-v2/interfaces/ILBRouter.sol";
import "openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../src/JoeDexLens.sol";
import "./TestHelper.sol";

contract TestJoeDexLens is TestHelper {
    uint256 AVAX_PRICE = 35.7e18;

    function setUp() public override {
        vm.createSelectFork(vm.rpcUrl("avalanche"), 41284321);
        super.setUp();

        JoeDexLens imp = new JoeDexLens(lbFactory, LBLegacyFactory, factoryV1, wNative);

        joeDexLens = JoeDexLens(address(new TransparentUpgradeableProxy(address(imp), address(1), "")));

        IJoeDexLens.DataFeed[] memory dataFeeds = new IJoeDexLens.DataFeed[](2);
        dataFeeds[0] = IJoeDexLens.DataFeed(wNative, AVAX_USDC_20BP, 1000, IJoeDexLens.DataFeedType.V2_1);
        dataFeeds[1] = IJoeDexLens.DataFeed(wNative, AVAX_USDT_20BP, 100, IJoeDexLens.DataFeedType.V2_1);

        joeDexLens.initialize(dataFeeds);
    }

    function test_GetNativePrice() public {
        assertApproxEqRel(joeDexLens.getTokenPriceUSD(wNative), AVAX_PRICE, 1e16, "test_GetNativePrice::1");
        assertEq(joeDexLens.getTokenPriceNative(wNative), 1e18, "test_GetNativePrice::2");
    }

    function test_GetTokenPriceUsingNativeDataFeeds() public {
        joeDexLens.addDataFeed(USDC, IJoeDexLens.DataFeed(wNative, AVAX_USDC_V1, 1000, IJoeDexLens.DataFeedType.V1));

        assertApproxEqAbs(joeDexLens.getTokenPriceUSD(USDC), 1e18, 0.05e18, "test_GetTokenPriceUsingNativeDataFeeds::1");
        assertApproxEqAbs(
            joeDexLens.getTokenPriceNative(USDC),
            uint256(1e36) / AVAX_PRICE,
            0.05e18,
            "test_GetTokenPriceUsingNativeDataFeeds::2"
        );

        joeDexLens.addDataFeed(USDC, IJoeDexLens.DataFeed(wNative, AVAX_USDC_20BP, 1000, IJoeDexLens.DataFeedType.V2_1));

        assertApproxEqAbs(joeDexLens.getTokenPriceUSD(USDC), 1e18, 0.05e18, "test_GetTokenPriceUsingNativeDataFeeds::3");
        assertApproxEqAbs(
            joeDexLens.getTokenPriceNative(USDC),
            uint256(1e36) / AVAX_PRICE,
            0.05e18,
            "test_GetTokenPriceUsingNativeDataFeeds::4"
        );
    }

    function test_GetTokenPriceUsingDataFeeds() public {
        joeDexLens.addDataFeed(USDC, IJoeDexLens.DataFeed(JOE, JOE_USDC_25BP, 1000, IJoeDexLens.DataFeedType.V2_1));
        joeDexLens.addDataFeed(JOE, IJoeDexLens.DataFeed(wNative, JOE_AVAX_15BP, 1000, IJoeDexLens.DataFeedType.V2_1));

        assertApproxEqAbs(joeDexLens.getTokenPriceUSD(USDC), 1e18, 0.05e18, "test_GetTokenPriceUsingDataFeeds::1");
        assertApproxEqAbs(
            joeDexLens.getTokenPriceNative(USDC),
            uint256(1e36) / AVAX_PRICE,
            0.05e18,
            "test_GetTokenPriceUsingDataFeeds::2"
        );

        joeDexLens.addDataFeed(USDC, IJoeDexLens.DataFeed(WETH, ETH_USDC_15BP, 1000, IJoeDexLens.DataFeedType.V2_1));
        joeDexLens.addDataFeed(WETH, IJoeDexLens.DataFeed(wNative, AVAX_ETH_10BP, 1000, IJoeDexLens.DataFeedType.V2_1));

        assertApproxEqAbs(joeDexLens.getTokenPriceUSD(USDC), 1e18, 0.05e18, "test_GetTokenPriceUsingDataFeeds::3");
        assertApproxEqAbs(
            joeDexLens.getTokenPriceNative(USDC),
            uint256(1e36) / AVAX_PRICE,
            0.05e18,
            "test_GetTokenPriceUsingDataFeeds::4"
        );

        joeDexLens.addDataFeed(WETH, IJoeDexLens.DataFeed(wNative, AVAX_ETH_V1, 1000, IJoeDexLens.DataFeedType.V1));

        assertApproxEqAbs(joeDexLens.getTokenPriceUSD(USDC), 1e18, 0.05e18, "test_GetTokenPriceUsingDataFeeds::5");
        assertApproxEqAbs(
            joeDexLens.getTokenPriceNative(USDC),
            uint256(1e36) / AVAX_PRICE,
            0.05e18,
            "test_GetTokenPriceUsingDataFeeds::6"
        );
    }

    function test_GetTokenPriceUsingNativeFallback() public {
        // Will use (fallback: V2_1 USDC/AVAX, V1 USDC/AVAX) -> AVAX USDC oracle
        assertApproxEqAbs(joeDexLens.getTokenPriceUSD(USDC), 1e18, 0.05e18, "test_GetTokenPriceUsingNativeFallback::1");

        joeDexLens.addDataFeed(USDC, IJoeDexLens.DataFeed(JOE, JOE_USDC_25BP, 1000, IJoeDexLens.DataFeedType.V2_1));

        // Will use V2_1 JOE/USDC -> (fallback: V2_1 JOE/AVAX, V1 JOE/AVAX) -> AVAX USDC oracle
        assertApproxEqAbs(joeDexLens.getTokenPriceUSD(USDC), 1e18, 0.05e18, "test_GetTokenPriceUsingNativeFallback::2");

        joeDexLens.addDataFeed(USDC, IJoeDexLens.DataFeed(WETH, ETH_USDC_15BP, 1000, IJoeDexLens.DataFeedType.V2_1));

        // Will use:
        // (V2_1 JOE/USDC, V2_1 ETH/USDC)
        // -> (fallback joe/usdc: V2_1 JOE/AVAX, V1 JOE/AVAX, fallback eth/usdc: V2_1 ETH/AVAX, V1 ETH/AVAX)
        // -> AVAX USDC oracle
        assertApproxEqAbs(joeDexLens.getTokenPriceUSD(USDC), 1e18, 0.05e18, "test_GetTokenPriceUsingNativeFallback::3");
    }

    function test_GetTokenPriceUsingFallback() public {
        uint24 ID_10_25bp = 8389530;
        uint24 ID_0_25_25bp = 8388052;

        address newToken0 = address(new ERC20MockDecimals(6));

        address pair0 = createLBPairV2_1(newToken0, USDC, ID_10_25bp);

        vm.label(newToken0, "newToken0");
        vm.label(pair0, "token0_usdc_25bp");

        addLiquidityV2_1(pair0, 1000e6, 100e6);

        assertEq(joeDexLens.getTokenPriceUSD(address(newToken0)), 0, "test_GetTokenPriceUsingFallback::1");

        joeDexLens.addDataFeed(USDC, IJoeDexLens.DataFeed(wNative, AVAX_USDC_20BP, 1000, IJoeDexLens.DataFeedType.V2_1));

        address[] memory trustedTokens = new address[](1);
        trustedTokens[0] = USDC;

        joeDexLens.setTrustedTokensAt(1, trustedTokens);

        assertApproxEqRel(
            joeDexLens.getTokenPriceNative(address(newToken0)),
            uint256(1e36) / AVAX_PRICE * 10,
            0.01e18,
            "test_GetTokenPriceUsingFallback::2"
        );
        assertApproxEqRel(
            joeDexLens.getTokenPriceUSD(address(newToken0)), 10e18, 1e16, "test_GetTokenPriceUsingFallback::3"
        );

        address newToken1 = address(new ERC20MockDecimals(6));

        vm.label(newToken1, "newToken1");

        vm.prank(lbFactory.owner());
        lbFactory.addQuoteAsset(IERC20(newToken0));

        address pair1 = createLBPairV2_1(newToken1, newToken0, ID_0_25_25bp);
        addLiquidityV2_1(pair1, 1000e8, 100e6);

        assertEq(joeDexLens.getTokenPriceUSD(address(newToken1)), 0, "test_GetTokenPriceUsingFallback::4");

        joeDexLens.addDataFeed(
            address(newToken0), IJoeDexLens.DataFeed(USDC, pair0, 1000, IJoeDexLens.DataFeedType.V2_1)
        );

        trustedTokens = new address[](2);

        trustedTokens[0] = USDC;
        trustedTokens[1] = newToken0;

        joeDexLens.setTrustedTokensAt(1, trustedTokens);

        assertApproxEqRel(
            joeDexLens.getTokenPriceNative(address(newToken1)),
            uint256(1e36) * 25 / 10 / AVAX_PRICE,
            0.01e18,
            "test_GetTokenPriceUsingFallback::5"
        );
        assertApproxEqRel(
            joeDexLens.getTokenPriceUSD(address(newToken1)), 2.5e18, 1e16, "test_GetTokenPriceUsingFallback::6"
        );

        address pair2 = createLBPairV2_1(newToken1, USDC, ID_10_25bp);
        addLiquidityV2_1(pair2, 1000e8, 100e6);

        assertApproxEqRel(
            joeDexLens.getTokenPriceUSD(address(newToken1)),
            uint256(2.5e18 + 10e18) / 2,
            1e16,
            "test_GetTokenPriceUsingFallback::7"
        );
    }

    function test_revert_BadDataFeeds() public {
        joeDexLens.addDataFeed(USDC, IJoeDexLens.DataFeed(JOE, JOE_USDC_25BP, 1000, IJoeDexLens.DataFeedType.V2_1));

        // Revert if a cycle is detected (USDC -> JOE -> USDC -> JOE -> ...)
        vm.expectRevert();
        joeDexLens.addDataFeed(JOE, IJoeDexLens.DataFeed(USDC, JOE_USDC_25BP, 1000, IJoeDexLens.DataFeedType.V2_1));

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
