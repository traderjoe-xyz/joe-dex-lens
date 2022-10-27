// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "joe-v2/interfaces/ILBRouter.sol";

import "../src/JoeDexLens.sol";
import "./TestHelper.sol";

contract TestJoeDexLens2 is TestHelper {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("fuji"), 14884890);
        joeDexLens = new JoeDexLens(ILBRouter(LBRouter), IJoeFactory(factoryV1), wNative, USDC);
    }

    function testPriceOnSameV1Pair() public {
        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(NativeUSDCv1, 1, IJoeDexLens.dfType.V1);
        joeDexLens.addUSDDataFeed(wNative, df);
        joeDexLens.addNativeDataFeed(USDC, df);

        uint256 NativePrice = joeDexLens.getTokenPriceUSD(wNative);
        uint256 usdcPrice = joeDexLens.getTokenPriceNative(USDC);

        (uint8 decimalsUsdc, uint8 decimalsWNative) = (
            IERC20Metadata(USDC).decimals(),
            IERC20Metadata(wNative).decimals()
        );

        assertApproxEqRel(NativePrice * usdcPrice, 10**(decimalsUsdc + decimalsWNative), 1e12);
    }

    function testPriceWithoutDataFeeds() public {
        vm.expectRevert(JoeDexLens__PairsNotCreated.selector);
        joeDexLens.getTokenPriceUSD(address(1));

        uint256 usdcPrice = joeDexLens.getTokenPriceNative(USDC);
        uint256 usdtPrice = joeDexLens.getTokenPriceNative(USDT);
        uint256 NativePrice = joeDexLens.getTokenPriceUSD(wNative);

        assertApproxEqRel(usdcPrice, 5e16, 3e16);
        assertApproxEqRel(usdtPrice, usdcPrice, 1e15);
        assertApproxEqRel((usdcPrice * NativePrice) / 1e6, 1e18, 1e15);
    }

    function testPriceOnSameV2Pair10bp() public {
        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(NativeUSDC10bps, 1, IJoeDexLens.dfType.V2);
        joeDexLens.addUSDDataFeed(wNative, df);
        joeDexLens.addNativeDataFeed(USDC, df);

        uint256 NativePrice = joeDexLens.getTokenPriceUSD(wNative);
        uint256 usdcPrice = joeDexLens.getTokenPriceNative(USDC);

        (uint8 decimalsUsdc, uint8 decimalsWNative) = (
            IERC20Metadata(USDC).decimals(),
            IERC20Metadata(wNative).decimals()
        );

        assertApproxEqRel(NativePrice * usdcPrice, 10**(decimalsUsdc + decimalsWNative), 1e12);
    }

    function testPriceOnSameV2Pair20bp() public {
        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(NativeUSDC20bps, 1, IJoeDexLens.dfType.V2);
        joeDexLens.addUSDDataFeed(wNative, df);
        joeDexLens.addNativeDataFeed(USDC, df);

        uint256 NativePrice = joeDexLens.getTokenPriceUSD(wNative);
        uint256 usdcPrice = joeDexLens.getTokenPriceNative(USDC);

        (uint8 decimalsUsdc, uint8 decimalsWNative) = (
            IERC20Metadata(USDC).decimals(),
            IERC20Metadata(wNative).decimals()
        );

        assertApproxEqRel(NativePrice * usdcPrice, 10**(decimalsUsdc + decimalsWNative), 1e12);
    }

    function testUSDPrice() public {
        (address[] memory tokens, IJoeDexLens.DataFeed[] memory dataFeeds) = getTokenAndDataFeeds(USDC);
        joeDexLens.addUSDDataFeeds(tokens, dataFeeds);

        (address[] memory tokens2, IJoeDexLens.DataFeed[] memory dataFeeds2) = getTokenAndDataFeeds(wNative);
        joeDexLens.addNativeDataFeeds(tokens2, dataFeeds2);

        // Price of USDT in USDC will increase, when selling USDC
        uint256 tokenAmount = 50_000e6;
        uint256 USDTPrice1 = joeDexLens.getTokenPriceUSD(USDT);
        ERC20MockDecimals tokenUSDC = ERC20MockDecimals(USDC);

        vm.prank(TokenOwner);
        tokenUSDC.mint(DEV, tokenAmount);
        tokenUSDC.transfer(USDCUSDT1bps, tokenAmount);

        vm.prank(TokenOwner);
        tokenUSDC.mint(DEV, tokenAmount);
        ILBPair(USDCUSDT1bps).swap(true, DEV);

        uint256 USDTPrice2 = joeDexLens.getTokenPriceUSD(USDT);
        assertGt(USDTPrice2, USDTPrice1);
        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = USDT;
        tokenUSDC.approve(routerV1, tokenAmount);
        IJoeRouter01(routerV1).swapExactTokensForTokens(tokenAmount, 0, path, DEV, block.timestamp);
        uint256 USDTPrice3 = joeDexLens.getTokenPriceUSD(USDT);
        assertGt(USDTPrice3, USDTPrice2);
    }

    function testNativePrice() public {
        (address[] memory tokens, IJoeDexLens.DataFeed[] memory dataFeeds) = getTokenAndDataFeeds(USDC);
        joeDexLens.addUSDDataFeeds(tokens, dataFeeds);

        (address[] memory tokens2, IJoeDexLens.DataFeed[] memory dataFeeds2) = getTokenAndDataFeeds(wNative);
        joeDexLens.addNativeDataFeeds(tokens2, dataFeeds2);

        // Price of USDC in Native will decrease, when selling USDC
        uint256 tokenAmount = 43_000e6;
        uint256 USDCPrice1 = joeDexLens.getTokenPriceNative(USDC);

        ERC20MockDecimals tokenUSDC = ERC20MockDecimals(USDC);

        vm.prank(TokenOwner);
        tokenUSDC.mint(DEV, tokenAmount);
        tokenUSDC.transfer(NativeUSDC10bps, tokenAmount);
        ILBPair(NativeUSDC10bps).swap(false, DEV);

        uint256 USDCPrice2 = joeDexLens.getTokenPriceNative(USDC);
        assertLt(USDCPrice2, USDCPrice1);
        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = wNative;

        vm.prank(TokenOwner);
        tokenAmount = 150_000e6;
        tokenUSDC.mint(DEV, tokenAmount);
        tokenUSDC.approve(routerV1, tokenAmount);
        IJoeRouter01(routerV1).swapExactTokensForTokens(tokenAmount, 0, path, DEV, block.timestamp);

        uint256 USDCPrice3 = joeDexLens.getTokenPriceNative(USDC);
        assertLt(USDCPrice3, USDCPrice2);
    }

    function getPriceFromV1(address pairAddress, address token) internal view returns (uint256) {
        uint256 PRECISION = 1e18;
        IJoePair pair = IJoePair(pairAddress);
        address token0 = pair.token0();
        address token1 = pair.token1();
        uint256 decimals0 = IERC20Metadata(token0).decimals();
        uint256 decimals1 = IERC20Metadata(token1).decimals();

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        if (token == token0) {
            return (PRECISION * reserve1 * 10**decimals0) / (reserve0 * 10**decimals1);
        } else if (token == token1) {
            return (PRECISION * reserve0 * 10**decimals1) / (reserve1 * 10**decimals0);
        } else revert("getPriceFromV1 failed");
    }
}
