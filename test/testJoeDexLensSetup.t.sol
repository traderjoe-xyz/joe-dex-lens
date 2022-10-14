// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "src/JoeDexLens.sol";
import "src/interfaces/ILBRouter.sol";
import "./TestHelper.sol";

contract TestJoeDexLens is TestHelper {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("fuji"), 14_541_000);
        lens = new JoeDexLens(LBRouter, FactoryV1, WAVAX, USDC);
    }

    function testAddUSDMarkets() public {
        JoeDexLens.Market[] memory markets = new JoeDexLens.Market[](2);
        markets[0] = JoeDexLens.Market(USDCUSDT1bps, JoeDexLens.MarketType.V2);
        markets[1] = JoeDexLens.Market(USDCUSDTv1, JoeDexLens.MarketType.V1);
        lens.addUSDMarkets(markets);

        JoeDexLens.Market[] memory USDMarkets = lens.getUSDMarkets(USDT);

        assertEq(USDMarkets.length, 2);

        assertEq(USDMarkets[0].pairAddress, USDCUSDT1bps);
        assert(USDMarkets[0].marketType == JoeDexLens.MarketType.V2);

        assertEq(USDMarkets[1].pairAddress, USDCUSDTv1);
        assert(USDMarkets[1].marketType == JoeDexLens.MarketType.V1);
    }

    function testAddDuplicateUSDMarketsReverts() public {
        JoeDexLens.Market[] memory markets = new JoeDexLens.Market[](2);
        markets[0] = JoeDexLens.Market(USDCUSDT1bps, JoeDexLens.MarketType.V2);
        markets[1] = JoeDexLens.Market(USDCUSDTv1, JoeDexLens.MarketType.V1);

        lens.addUSDMarkets(markets);

        JoeDexLens.Market[] memory duplicateMarkets = new JoeDexLens.Market[](1);

        duplicateMarkets[0] = JoeDexLens.Market(USDCUSDT1bps, JoeDexLens.MarketType.V2);
        vm.expectRevert(abi.encodeWithSelector(JoeDexLens__MarketAlreadyExists.selector, USDCUSDT1bps));
        lens.addUSDMarkets(duplicateMarkets);

        duplicateMarkets[0] = JoeDexLens.Market(USDCUSDTv1, JoeDexLens.MarketType.V1);
        vm.expectRevert(abi.encodeWithSelector(JoeDexLens__MarketAlreadyExists.selector, USDCUSDTv1));
        lens.addUSDMarkets(duplicateMarkets);

        lens.removeUSDMarket(USDT, duplicateMarkets[0]);
        lens.addUSDMarkets(duplicateMarkets);
    }

    function testRemoveUSDMarkets() public {
        JoeDexLens.Market[] memory markets = new JoeDexLens.Market[](2);
        markets[0] = JoeDexLens.Market(USDCUSDT1bps, JoeDexLens.MarketType.V2);
        markets[1] = JoeDexLens.Market(USDCUSDTv1, JoeDexLens.MarketType.V1);
        lens.addUSDMarkets(markets);

        JoeDexLens.Market[] memory USDMarkets = lens.getUSDMarkets(USDT);

        assertEq(USDMarkets.length, 2);

        lens.removeUSDMarket(USDT, markets[0]);
        USDMarkets = lens.getUSDMarkets(USDT);
        assertEq(USDMarkets.length, 1);
        assertEq(USDMarkets[0].pairAddress, USDCUSDTv1);
        assert(USDMarkets[0].marketType == JoeDexLens.MarketType.V1);

        lens.removeUSDMarket(USDT, markets[1]);
        USDMarkets = lens.getUSDMarkets(USDT);
        assertEq(USDMarkets.length, 0);
    }

    function testRemoveAVAXMarkets() public {
        JoeDexLens.Market[] memory markets = new JoeDexLens.Market[](2);
        markets[0] = JoeDexLens.Market(AVAXUSDC10bps, JoeDexLens.MarketType.V2);
        markets[1] = JoeDexLens.Market(AVAXUSDCv1, JoeDexLens.MarketType.V1);
        lens.addAVAXMarkets(markets);

        JoeDexLens.Market[] memory AVAXMarkets = lens.getAVAXMarkets(USDC);

        assertEq(AVAXMarkets.length, 2);

        lens.removeAVAXMarket(USDC, markets[0]);
        AVAXMarkets = lens.getAVAXMarkets(USDC);
        assertEq(AVAXMarkets.length, 1);
        assertEq(AVAXMarkets[0].pairAddress, AVAXUSDCv1);
        assert(AVAXMarkets[0].marketType == JoeDexLens.MarketType.V1);

        lens.removeAVAXMarket(USDC, markets[1]);
        AVAXMarkets = lens.getAVAXMarkets(USDC);
        assertEq(AVAXMarkets.length, 0);
    }

    function testAddAVAXMarkets() public {
        JoeDexLens.Market[] memory markets = new JoeDexLens.Market[](2);
        markets[0] = JoeDexLens.Market(AVAXUSDC10bps, JoeDexLens.MarketType.V2);
        markets[1] = JoeDexLens.Market(AVAXUSDCv1, JoeDexLens.MarketType.V1);

        lens.addAVAXMarkets(markets);
        JoeDexLens.Market[] memory AVAXMarkets = lens.getAVAXMarkets(USDC);

        assertEq(AVAXMarkets.length, 2);

        assertEq(AVAXMarkets[0].pairAddress, AVAXUSDC10bps);
        assert(AVAXMarkets[0].marketType == JoeDexLens.MarketType.V2);

        assertEq(AVAXMarkets[1].pairAddress, AVAXUSDCv1);
        assert(AVAXMarkets[1].marketType == JoeDexLens.MarketType.V1);
    }
}
