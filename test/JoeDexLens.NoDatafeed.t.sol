// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "joe-v2/interfaces/ILBRouter.sol";

import "../src/JoeDexLens.sol";
import "./TestHelper.sol";

contract TestJoeDexLens_ is TestHelper {
    ERC20MockDecimals internal token18D;

    function setUp() public override {
        vm.createSelectFork(vm.rpcUrl("fuji"), 14884890);
        super.setUp();

        joeDexLens = new JoeDexLens(lbRouter, USDC);

        token18D = new ERC20MockDecimals(18);
    }

    function test_PriceWithoutDataFeeds_V1() public {
        vm.expectRevert(IJoeDexLens.JoeDexLens__PairsNotCreated.selector);
        joeDexLens.getTokenPriceUSD(address(1));

        uint256 priceUSD = joeDexLens.getTokenPriceNative(WETH);
        uint256 priceNative = joeDexLens.getTokenPriceUSD(WETH);

        assertApproxEqRel(priceUSD, 0.335e18, 3e16);
        assertApproxEqRel(priceNative, 6.68e18, 3e16);
    }

    function test_PriceWithoutDataFeeds_LegacyV2() public {
        // 1 token18 = 2 USDC
        LBLegacyRouter.createLBPair(token18D, IERC20(USDC), 8361297, DEFAULT_BIN_STEP);

        // Fails if there is no liquidity
        vm.expectRevert(IJoeDexLens.JoeDexLens__PairsNotCreated.selector);
        uint256 tokenPrice = joeDexLens.getTokenPriceUSD(address(token18D));

        // Add liquidity but not enough to meet the lens requirements for a valid price
        ILBRouter.LiquidityParameters memory liquidityParameters =
            getLiquidityParameters(token18D, IERC20(USDC), 0.1e6, 8361297, 67, 15);

        deal(address(token18D), DEV, liquidityParameters.amountX);
        deal(USDC, DEV, liquidityParameters.amountY);
        token18D.approve(address(LBLegacyRouter), liquidityParameters.amountX);
        IERC20(USDC).approve(address(LBLegacyRouter), liquidityParameters.amountY);

        LBLegacyRouter.addLiquidity(Utils.toLegacy(liquidityParameters));

        vm.expectRevert(IJoeDexLens.JoeDexLens__PairsNotCreated.selector);
        tokenPrice = joeDexLens.getTokenPriceUSD(address(token18D));

        // Add enough liquidity this time
        liquidityParameters = getLiquidityParameters(token18D, IERC20(USDC), 10e6, 8361297, 3, 0);

        deal(address(token18D), DEV, liquidityParameters.amountX);
        deal(USDC, DEV, liquidityParameters.amountY);
        token18D.approve(address(LBLegacyRouter), liquidityParameters.amountX);
        IERC20(USDC).approve(address(LBLegacyRouter), liquidityParameters.amountY);

        LBLegacyRouter.addLiquidity(Utils.toLegacy(liquidityParameters));

        tokenPrice = joeDexLens.getTokenPriceUSD(address(token18D));

        assertApproxEqRel(tokenPrice, 2e6, 3e16);

        // Should also work with the other collateral
        uint256 tokenPriceNative = joeDexLens.getTokenPriceNative(address(token18D));
        uint256 nativePriceUSD = joeDexLens.getTokenPriceUSD(wNative);

        assertApproxEqRel(tokenPriceNative * nativePriceUSD / 1e18, 2e6, 3e16);
    }

    function test_PriceWithoutDataFeeds_V2_1() public {
        useLegacyBinStep = false;

        // 1 token18 = 2 USDC
        lbRouter.createLBPair(token18D, IERC20(USDC), 8361297, DEFAULT_BIN_STEP * 2);

        // Fails if there is no liquidity
        vm.expectRevert(IJoeDexLens.JoeDexLens__PairsNotCreated.selector);
        uint256 tokenPrice = joeDexLens.getTokenPriceUSD(address(token18D));

        // Add liquidity but not enough to meet the lens requirements for a valid price
        ILBRouter.LiquidityParameters memory liquidityParameters =
            getLiquidityParameters(token18D, IERC20(USDC), 0.1e6, 8361297, 67, 15);

        deal(address(token18D), DEV, liquidityParameters.amountX);
        deal(USDC, DEV, liquidityParameters.amountY);
        token18D.approve(address(lbRouter), liquidityParameters.amountX);
        IERC20(USDC).approve(address(lbRouter), liquidityParameters.amountY);

        lbRouter.addLiquidity(liquidityParameters);

        vm.expectRevert(IJoeDexLens.JoeDexLens__PairsNotCreated.selector);
        tokenPrice = joeDexLens.getTokenPriceUSD(address(token18D));

        // Add enough liquidity this time
        liquidityParameters = getLiquidityParameters(token18D, IERC20(USDC), 10e6, 8361297, 3, 0);

        deal(address(token18D), DEV, liquidityParameters.amountX);
        deal(USDC, DEV, liquidityParameters.amountY);
        token18D.approve(address(lbRouter), liquidityParameters.amountX);
        IERC20(USDC).approve(address(lbRouter), liquidityParameters.amountY);

        lbRouter.addLiquidity(liquidityParameters);

        tokenPrice = joeDexLens.getTokenPriceUSD(address(token18D));

        assertApproxEqRel(tokenPrice, 2e6, 3e16);

        // Should also work with the other collateral
        uint256 tokenPriceNative = joeDexLens.getTokenPriceNative(address(token18D));
        uint256 nativePriceUSD = joeDexLens.getTokenPriceUSD(wNative);

        assertApproxEqRel(tokenPriceNative * nativePriceUSD / 1e18, 2e6, 3e16);
    }
}

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (IPair pair);
}

interface IPair {
    function mint(address to) external returns (uint256 liquidity);
}
