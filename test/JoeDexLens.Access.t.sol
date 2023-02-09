// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "joe-v2/interfaces/ILBRouter.sol";

import "../src/JoeDexLens.sol";
import "./TestHelper.sol";

contract TestJoeDexLens is TestHelper {
    function setUp() public override {
        vm.createSelectFork(vm.rpcUrl("fuji"), 14_541_000);
        super.setUp();

        joeDexLens = new JoeDexLens(lbRouter, USDC);
    }

    function test_RevertOnOwnerFunctions() public {
        vm.startPrank(ALICE);

        address[] memory usdcSingleton = getAddressSingleton(USDC);
        address[] memory wNativeSingleton = getAddressSingleton(wNative);

        // Should pass
        joeDexLens.getLegacyRouterV2();
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

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerable.SafeAccessControlEnumerable__OnlyOwnerOrRole.selector,
                ALICE,
                joeDexLens.DATA_FEED_MANAGER_ROLE()
            )
        );
        joeDexLens.addUSDDataFeed(address1, df);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerable.SafeAccessControlEnumerable__OnlyOwnerOrRole.selector,
                ALICE,
                joeDexLens.DATA_FEED_MANAGER_ROLE()
            )
        );
        joeDexLens.addNativeDataFeed(address1, df);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerable.SafeAccessControlEnumerable__OnlyOwnerOrRole.selector,
                ALICE,
                joeDexLens.DATA_FEED_MANAGER_ROLE()
            )
        );
        joeDexLens.setUSDDataFeedWeight(address1, address1, weight1);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerable.SafeAccessControlEnumerable__OnlyOwnerOrRole.selector,
                ALICE,
                joeDexLens.DATA_FEED_MANAGER_ROLE()
            )
        );
        joeDexLens.setNativeDataFeedWeight(address1, address1, weight1);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerable.SafeAccessControlEnumerable__OnlyOwnerOrRole.selector,
                ALICE,
                joeDexLens.DATA_FEED_MANAGER_ROLE()
            )
        );
        joeDexLens.removeUSDDataFeed(address1, address1);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerable.SafeAccessControlEnumerable__OnlyOwnerOrRole.selector,
                ALICE,
                joeDexLens.DATA_FEED_MANAGER_ROLE()
            )
        );
        joeDexLens.removeNativeDataFeed(address1, address1);

        IJoeDexLens.DataFeed[] memory dfSingleton = getDataFeedSingleton(df);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerable.SafeAccessControlEnumerable__OnlyOwnerOrRole.selector,
                ALICE,
                joeDexLens.DATA_FEED_MANAGER_ROLE()
            )
        );
        joeDexLens.addUSDDataFeeds(usdcSingleton, dfSingleton);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerable.SafeAccessControlEnumerable__OnlyOwnerOrRole.selector,
                ALICE,
                joeDexLens.DATA_FEED_MANAGER_ROLE()
            )
        );
        joeDexLens.addNativeDataFeeds(wNativeSingleton, dfSingleton);

        uint88[] memory uint8Singleton = getUint88Singleton(1);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerable.SafeAccessControlEnumerable__OnlyOwnerOrRole.selector,
                ALICE,
                joeDexLens.DATA_FEED_MANAGER_ROLE()
            )
        );
        joeDexLens.setUSDDataFeedsWeights(usdcSingleton, usdcSingleton, uint8Singleton);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerable.SafeAccessControlEnumerable__OnlyOwnerOrRole.selector,
                ALICE,
                joeDexLens.DATA_FEED_MANAGER_ROLE()
            )
        );
        joeDexLens.setNativeDataFeedsWeights(wNativeSingleton, wNativeSingleton, uint8Singleton);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerable.SafeAccessControlEnumerable__OnlyOwnerOrRole.selector,
                ALICE,
                joeDexLens.DATA_FEED_MANAGER_ROLE()
            )
        );
        joeDexLens.removeUSDDataFeeds(usdcSingleton, usdcSingleton);

        vm.expectRevert(
            abi.encodeWithSelector(
                ISafeAccessControlEnumerable.SafeAccessControlEnumerable__OnlyOwnerOrRole.selector,
                ALICE,
                joeDexLens.DATA_FEED_MANAGER_ROLE()
            )
        );
        joeDexLens.removeNativeDataFeeds(wNativeSingleton, wNativeSingleton);

        vm.stopPrank();
    }

    function test_ReturnRouter() public {
        assertEq(address(joeDexLens.getLegacyRouterV2()), address(LBLegacyRouter));
    }

    function test_ReturnFactory() public {
        assertEq(address(joeDexLens.getFactoryV1()), address(factoryV1));
    }
}
