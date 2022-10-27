// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TestHelper.sol";

contract TestV2Prices is TestHelper {
    ERC20MockDecimals internal token6D;
    ERC20MockDecimals internal token10D;
    ERC20MockDecimals internal token12D;
    ERC20MockDecimals internal token18D;
    ERC20MockDecimals internal token24D;

    uint24 SHIFT_ID_ONE_1e4 = 4_609; // The result of `log( 1e10/1e6 ) / log(1.002)`, when 1 token6D is equal to 1 token10D
    uint24 SHIFT_ID_ONE_1e18 = 20_743; // The result of `log( 1e24/1e6 ) / log(1.002)`, when 1 token6D is equal to 1 token24D

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("fuji"), 14_541_000);
        token10D = new ERC20MockDecimals(10);
        token24D = new ERC20MockDecimals(24);

        joeDexLens = new JoeDexLens(LBRouter, joeFactory, wNative, USDC);

        vm.startPrank(factoryOwner);
        LBFactory.setFactoryLockedState(false);

        LBFactory.addQuoteAsset(token10D);
        LBFactory.addQuoteAsset(token24D);
        vm.stopPrank();
    }

    function testPriceSameToken() public {
        uint256 priceUSDC = joeDexLens.getTokenPriceUSD(USDC);
        uint256 priceWNative = joeDexLens.getTokenPriceNative(wNative);

        uint8 decimalsUSDC = IERC20Metadata(USDC).decimals();
        uint8 decimalsWNative = IERC20Metadata(wNative).decimals();

        assertEq(10**decimalsUSDC, priceUSDC);
        assertEq(10**decimalsWNative, priceWNative);
    }

    function testV2PriceUSDC_USDT() public {
        ILBPair pair = ILBPair(USDCUSDT1bps);

        (, , uint256 id) = pair.getReservesAndId();

        uint256 price128x128 = LBRouter.getPriceFromId(pair, uint24(id));

        uint8 decimalsX = IERC20Metadata(USDT).decimals();
        uint256 priceReal = ((price128x128 * 10**decimalsX) >> 128);

        addUSDDataFeed(USDT, USDCUSDT1bps);
        uint256 priceLens = joeDexLens.getTokenPriceUSD(USDT);

        assertApproxEqAbs(priceLens, priceReal, 1);
    }

    function testV2PriceNativeUSDC10bps() public {
        ILBPair pair = ILBPair(NativeUSDC10bps);

        (, , uint256 id) = pair.getReservesAndId();

        uint256 price128x128 = LBRouter.getPriceFromId(pair, uint24(id));

        uint8 decimalsX = IERC20Metadata(wNative).decimals();
        uint256 priceReal = (price128x128 * 10**decimalsX) >> 128;

        addUSDDataFeed(wNative, NativeUSDC10bps);
        uint256 priceLens = joeDexLens.getTokenPriceUSD(wNative);

        assertApproxEqAbs(priceLens, priceReal, 1);
    }

    function testV2PriceUSDC_10D() public {
        createPairAndAddToUSDDataFeeds(USDC, address(token10D), ID_ONE + SHIFT_ID_ONE_1e4);

        uint256 priceT10D = joeDexLens.getTokenPriceUSD(address(token10D));

        // uint256(DEFAULT_BIN_STEP) * 1e14 = 0.2%
        assertApproxEqRel(priceT10D, 1e6, uint256(DEFAULT_BIN_STEP) * 1e14);
    }

    function testV2PriceUSDC_24D() public {
        createPairAndAddToUSDDataFeeds(USDC, address(token24D), ID_ONE + SHIFT_ID_ONE_1e18);

        uint256 price = joeDexLens.getTokenPriceUSD(address(token24D));

        assertApproxEqRel(price, 1e6, uint256(DEFAULT_BIN_STEP) * 1e14);
    }

    function testV2Price10D_USDC() public {
        createPairAndAddToUSDDataFeeds(address(token10D), USDC, ID_ONE - SHIFT_ID_ONE_1e4);

        uint256 price = joeDexLens.getTokenPriceUSD(address(token10D));

        assertApproxEqRel(price, 1e6, uint256(DEFAULT_BIN_STEP) * 1e14);
    }

    function testV2Price24D_USDC() public {
        createPairAndAddToUSDDataFeeds(address(token24D), USDC, ID_ONE - SHIFT_ID_ONE_1e18);

        uint256 price = joeDexLens.getTokenPriceUSD(address(token24D));

        assertApproxEqRel(price, 1e6, uint256(DEFAULT_BIN_STEP) * 1e14);
    }
}
