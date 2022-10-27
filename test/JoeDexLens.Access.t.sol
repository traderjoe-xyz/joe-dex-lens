// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "joe-v2/interfaces/ILBRouter.sol";

import "../src/JoeDexLens.sol";
import "./TestHelper.sol";

contract TestJoeDexLens is TestHelper {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("fuji"), 14_541_000);
        joeDexLens = new JoeDexLens(ILBRouter(LBRouter), IJoeFactory(factoryV1), wNative, USDC);
    }

    function testRevertOnOwnerFunctions() public {
        vm.startPrank(ALICE);

        address[] memory usdcSingleton = getAddressSingleton(USDC);
        address[] memory wNativeSingleton = getAddressSingleton(wNative);

        // Should pass
        joeDexLens.getRouterV2();
        joeDexLens.getFactoryV1();
        joeDexLens.getUSDDataFeeds(USDC);
        joeDexLens.getNativeDataFeeds(wNative);
        joeDexLens.getTokenPriceUSD(USDC);
        joeDexLens.getTokenPriceNative(wNative);
        joeDexLens.getTokensPricesUSD(usdcSingleton);
        joeDexLens.getTokensPricesNative(wNativeSingleton);

        // Should revert
        address address1 = address(1);
        uint88 weight1 = 1;
        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(address1, weight1, IJoeDexLens.dfType.V1);

        vm.expectRevert(PendingOwnable__NotOwner.selector);
        joeDexLens.addUSDDataFeed(address1, df);

        vm.expectRevert(PendingOwnable__NotOwner.selector);
        joeDexLens.addNativeDataFeed(address1, df);

        vm.expectRevert(PendingOwnable__NotOwner.selector);
        joeDexLens.setUSDDataFeedWeight(address1, address1, weight1);

        vm.expectRevert(PendingOwnable__NotOwner.selector);
        joeDexLens.setNativeDataFeedWeight(address1, address1, weight1);

        vm.expectRevert(PendingOwnable__NotOwner.selector);
        joeDexLens.removeUSDDataFeed(address1, address1);

        vm.expectRevert(PendingOwnable__NotOwner.selector);
        joeDexLens.removeNativeDataFeed(address1, address1);

        IJoeDexLens.DataFeed[] memory dfSingleton = getDataFeedSingleton(df);

        vm.expectRevert(PendingOwnable__NotOwner.selector);
        joeDexLens.addUSDDataFeeds(usdcSingleton, dfSingleton);

        vm.expectRevert(PendingOwnable__NotOwner.selector);
        joeDexLens.addNativeDataFeeds(wNativeSingleton, dfSingleton);

        uint88[] memory uint8Singleton = getUint88Singleton(1);

        vm.expectRevert(PendingOwnable__NotOwner.selector);
        joeDexLens.setUSDDataFeedsWeights(usdcSingleton, usdcSingleton, uint8Singleton);

        vm.expectRevert(PendingOwnable__NotOwner.selector);
        joeDexLens.setNativeDataFeedsWeights(wNativeSingleton, wNativeSingleton, uint8Singleton);

        vm.expectRevert(PendingOwnable__NotOwner.selector);
        joeDexLens.removeUSDDataFeeds(usdcSingleton, usdcSingleton);

        vm.expectRevert(PendingOwnable__NotOwner.selector);
        joeDexLens.removeNativeDataFeeds(wNativeSingleton, wNativeSingleton);

        vm.stopPrank();
    }

    function testReturnRouter() public {
        assertEq(address(joeDexLens.getRouterV2()), address(LBRouter));
    }

    function testReturnFactory() public {
        assertEq(address(joeDexLens.getFactoryV1()), address(factoryV1));
    }
}
