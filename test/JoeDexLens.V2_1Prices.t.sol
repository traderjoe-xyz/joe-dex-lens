// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TestHelper.sol";

contract TestV2_1Prices is TestHelper {
    ERC20MockDecimals internal token6D;
    ERC20MockDecimals internal token10D;
    ERC20MockDecimals internal token12D;
    ERC20MockDecimals internal token18D;
    ERC20MockDecimals internal token24D;

    uint24 SHIFT_ID_ONE_1e4 = 4_609; // The result of `log( 1e10/1e6 ) / log(1.002)`, when 1 token6D is equal to 1 token10D
    uint24 SHIFT_ID_ONE_1e18 = 20_743; // The result of `log( 1e24/1e6 ) / log(1.002)`, when 1 token6D is equal to 1 token24D

    function setUp() public override {
        vm.createSelectFork(vm.rpcUrl("fuji"), 14_541_000);
        super.setUp();

        token10D = new ERC20MockDecimals(10);
        token24D = new ERC20MockDecimals(24);

        joeDexLens = new JoeDexLens(lbRouter, lbFactory, LBLegacyRouter, LBLegacyFactory, joeFactory, wNative, USDC);

        lbFactory.addQuoteAsset(token10D);
        lbFactory.addQuoteAsset(token24D);
    }

    function test_V2PriceUSDC_10D() public {
        createPairAndAddToUSDDataFeeds(USDC, address(token10D), ID_ONE + SHIFT_ID_ONE_1e4, IJoeDexLens.dfType.V2_1);

        uint256 priceT10D = joeDexLens.getTokenPriceUSD(address(token10D));

        // uint256(DEFAULT_BIN_STEP) * 1e14 = 0.2%
        assertApproxEqRel(priceT10D, 1e6, uint256(DEFAULT_BIN_STEP) * 1e14);
    }

    function test_V2PriceUSDC_24D() public {
        createPairAndAddToUSDDataFeeds(USDC, address(token24D), ID_ONE + SHIFT_ID_ONE_1e18, IJoeDexLens.dfType.V2_1);

        uint256 price = joeDexLens.getTokenPriceUSD(address(token24D));

        assertApproxEqRel(price, 1e6, uint256(DEFAULT_BIN_STEP) * 1e14);
    }

    function test_V2Price10D_USDC() public {
        createPairAndAddToUSDDataFeeds(address(token10D), USDC, ID_ONE - SHIFT_ID_ONE_1e4, IJoeDexLens.dfType.V2_1);

        uint256 price = joeDexLens.getTokenPriceUSD(address(token10D));

        assertApproxEqRel(price, 1e6, uint256(DEFAULT_BIN_STEP) * 1e14);
    }

    function test_V2Price24D_USDC() public {
        createPairAndAddToUSDDataFeeds(address(token24D), USDC, ID_ONE - SHIFT_ID_ONE_1e18, IJoeDexLens.dfType.V2_1);

        uint256 price = joeDexLens.getTokenPriceUSD(address(token24D));

        assertApproxEqRel(price, 1e6, uint256(DEFAULT_BIN_STEP) * 1e14);
    }
}
