// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "src/JoeDexLens.sol";
import "src/interfaces/ILBRouter.sol";
import "./TestHelper.sol";

contract TestJoeDexLens2 is TestHelper {
    function setUp() public {
        //vm.createSelectFork(vm.rpcUrl("fuji"), 14_541_000);
        vm.createSelectFork(vm.rpcUrl("fuji"), 14_625_546);
        lens = new JoeDexLens(LBRouter, FactoryV1, WAVAX, USDC);
        JoeDexLens.Market[] memory markets = new JoeDexLens.Market[](2);
        markets[0] = JoeDexLens.Market(USDCUSDT1bps, JoeDexLens.MarketType.V2);
        markets[1] = JoeDexLens.Market(USDCUSDTv1, JoeDexLens.MarketType.V1);
        lens.addUSDMarkets(markets);

        JoeDexLens.Market[] memory USDMarkets = lens.getUSDMarkets(USDT);

        JoeDexLens.Market[] memory markets2 = new JoeDexLens.Market[](2);
        markets2[0] = JoeDexLens.Market(AVAXUSDCv1, JoeDexLens.MarketType.V1);
        markets2[1] = JoeDexLens.Market(AVAXUSDC10bps, JoeDexLens.MarketType.V2);

        lens.addAVAXMarkets(markets2);
        JoeDexLens.Market[] memory AVAXMarkets = lens.getAVAXMarkets(USDC);
    }

    function testUSDPrice() public {
        // Price of USDT in USDC will increase, when selling USDC
        uint256 tokenAmount = 50_000e6;
        uint256 USDTPrice1 = lens.getTokenPriceUSD(USDT);
        console2.log(USDTPrice1);
        ITestnetERC20 tokenUSDC = ITestnetERC20(USDC);

        vm.prank(TokenOwner);
        tokenUSDC.mint(DEV, tokenAmount);
        tokenUSDC.transfer(USDCUSDT1bps, tokenAmount);

        vm.prank(TokenOwner);
        tokenUSDC.mint(DEV, tokenAmount);
        ILBPair(USDCUSDT1bps).swap(true, DEV);

        uint256 USDTPrice2 = lens.getTokenPriceUSD(USDT);
        console2.log(USDTPrice2);
        assertGt(USDTPrice2, USDTPrice1);
        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = USDT;
        tokenUSDC.approve(RouterV1, tokenAmount);
        IJoeRouter01(RouterV1).swapExactTokensForTokens(tokenAmount, 0, path, DEV, block.timestamp);
        uint256 USDTPrice3 = lens.getTokenPriceUSD(USDT);
        console2.log(USDTPrice3);
        assertGt(USDTPrice3, USDTPrice2);
    }

    function testAVAXPrice() public {
        // Price of USDC in AVAX will decrease, when selling USDC
        uint256 tokenAmount = 43_000e6;
        uint256 USDCPrice1 = lens.getTokenPriceAVAX(USDC);
        console2.log("USDCPrice1", USDCPrice1);
        ITestnetERC20 tokenUSDC = ITestnetERC20(USDC);

        vm.prank(TokenOwner);
        tokenUSDC.mint(DEV, tokenAmount);
        tokenUSDC.transfer(AVAXUSDC10bps, tokenAmount);
        ILBPair(AVAXUSDC10bps).swap(false, DEV);

        uint256 USDCPrice2 = lens.getTokenPriceAVAX(USDC);
        console2.log("USDCPrice2", USDCPrice2);
        assertLt(USDCPrice2, USDCPrice1);
        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = WAVAX;
        console2.log("getPriceFromV1", getPriceFromV1(AVAXUSDCv1, USDC));
        vm.prank(TokenOwner);
        tokenAmount = 4e18;
        tokenUSDC.mint(DEV, tokenAmount);
        tokenUSDC.approve(RouterV1, tokenAmount);
        IJoeRouter01(RouterV1).swapExactTokensForTokens(tokenAmount, 0, path, DEV, block.timestamp);
        //IJoeRouter01(RouterV1).swapExactAVAXForTokens{value: tokenAmount}(0, path, DEV, block.timestamp);
        uint256 USDCPrice3 = lens.getTokenPriceAVAX(USDC);
        console2.log("USDCPrice3", USDCPrice3);
        console2.log("getPriceFromV1", getPriceFromV1(AVAXUSDCv1, USDC));
        // fails - no idea why. getPriceFromV1 decreases while getTokenPriceAVAX increases?
        assertLt(USDCPrice3, USDCPrice2);
    }

    function getPriceFromV1(address pairAddress, address token) internal view returns (uint256) {
        uint256 PRECISION = 1e18;
        IJoePair pair = IJoePair(pairAddress);
        address token0 = pair.token0();
        address token1 = pair.token1();
        uint256 decimals0 = ERC20(token0).decimals();
        uint256 decimals1 = ERC20(token1).decimals();

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        if (token == token0) {
            return (PRECISION * reserve1 * 10**decimals0) / (reserve0 * 10**decimals1);
        } else if (token == token1) {
            return (PRECISION * reserve0 * 10**decimals1) / (reserve1 * 10**decimals0);
        }
    }
}
