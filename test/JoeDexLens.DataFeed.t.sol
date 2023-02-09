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

    function test_AddUSDDataFeeds() public {
        (address[] memory tokens, IJoeDexLens.DataFeed[] memory dataFeeds) = getTokenAndDataFeeds(USDC);

        joeDexLens.addUSDDataFeeds(tokens, dataFeeds);

        IJoeDexLens.DataFeed[] memory USDTDataFeeds = joeDexLens.getUSDDataFeeds(USDT);

        assertEq(USDTDataFeeds.length, 2);

        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(address(1), 1, IJoeDexLens.dfType.CHAINLINK);
        joeDexLens.addUSDDataFeed(wNative, df);

        USDTDataFeeds = joeDexLens.getUSDDataFeeds(USDT);

        assertEq(USDTDataFeeds.length, 2);

        assertEq(USDTDataFeeds[0].dfAddress, USDCUSDT1bps);
        assertEq(USDTDataFeeds[0].dfWeight, 10e18);
        assertEq(uint8(USDTDataFeeds[0].dfType), uint8(IJoeDexLens.dfType.V2));

        assertEq(USDTDataFeeds[1].dfAddress, USDCUSDTv1);
        assertEq(USDTDataFeeds[1].dfWeight, 1e18);
        assertEq(uint8(USDTDataFeeds[1].dfType), uint8(IJoeDexLens.dfType.V1));

        IJoeDexLens.DataFeed[] memory wNativeDataFeeds = joeDexLens.getUSDDataFeeds(wNative);

        assertEq(wNativeDataFeeds[0].dfAddress, address(1));
        assertEq(wNativeDataFeeds[0].dfWeight, 1);
        assertEq(uint8(wNativeDataFeeds[0].dfType), uint8(IJoeDexLens.dfType.CHAINLINK));
    }

    function test_SetWeightUSDDataFeeds() public {
        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(address(1), 1, IJoeDexLens.dfType.CHAINLINK);
        joeDexLens.addUSDDataFeed(wNative, df);

        vm.expectRevert(abi.encodeWithSelector(IJoeDexLens.JoeDexLens__NullWeight.selector));
        joeDexLens.setUSDDataFeedWeight(wNative, df.dfAddress, 0);

        joeDexLens.setUSDDataFeedWeight(wNative, df.dfAddress, 1e18);

        IJoeDexLens.DataFeed[] memory wNativeDataFeeds = joeDexLens.getUSDDataFeeds(wNative);
        assertEq(wNativeDataFeeds[0].dfWeight, 1e18);

        address[] memory wNativeSingleton = getAddressSingleton(wNative);
        address[] memory dfAddressSingleton = getAddressSingleton(df.dfAddress);
        uint88[] memory uint8Singleton = getUint88Singleton(20);

        joeDexLens.setUSDDataFeedsWeights(wNativeSingleton, dfAddressSingleton, uint8Singleton);

        IJoeDexLens.DataFeed[] memory wNativeDataFeeds2 = joeDexLens.getUSDDataFeeds(wNative);
        assertEq(wNativeDataFeeds2[0].dfWeight, 20);
    }

    function test_SetWeightNativeDataFeeds() public {
        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(address(1), 1, IJoeDexLens.dfType.CHAINLINK);
        joeDexLens.addNativeDataFeed(USDC, df);

        vm.expectRevert(abi.encodeWithSelector(IJoeDexLens.JoeDexLens__NullWeight.selector));
        joeDexLens.setNativeDataFeedWeight(USDC, df.dfAddress, 0);

        joeDexLens.setNativeDataFeedWeight(USDC, df.dfAddress, 1e18);

        IJoeDexLens.DataFeed[] memory USDCDataFeeds = joeDexLens.getNativeDataFeeds(USDC);
        assertEq(USDCDataFeeds[0].dfWeight, 1e18);

        address[] memory usdcSingleton = getAddressSingleton(USDC);
        address[] memory dfAddressSingleton = getAddressSingleton(df.dfAddress);
        uint88[] memory uint8Singleton = getUint88Singleton(10);

        joeDexLens.setNativeDataFeedsWeights(usdcSingleton, dfAddressSingleton, uint8Singleton);

        IJoeDexLens.DataFeed[] memory USDCDataFeeds2 = joeDexLens.getNativeDataFeeds(USDC);
        assertEq(USDCDataFeeds2[0].dfWeight, 10);
    }

    function test_AddDuplicateUSDDataFeedsReverts() public {
        (address[] memory tokens, IJoeDexLens.DataFeed[] memory dataFeeds) = getTokenAndDataFeeds(USDC);

        joeDexLens.addUSDDataFeeds(tokens, dataFeeds);

        vm.expectRevert(
            abi.encodeWithSelector(
                IJoeDexLens.JoeDexLens__DataFeedAlreadyAdded.selector, USDC, tokens[0], dataFeeds[0].dfAddress
            )
        );
        joeDexLens.addUSDDataFeeds(tokens, dataFeeds);

        vm.expectRevert(
            abi.encodeWithSelector(
                IJoeDexLens.JoeDexLens__DataFeedAlreadyAdded.selector, USDC, tokens[0], dataFeeds[0].dfAddress
            )
        );
        joeDexLens.addUSDDataFeed(tokens[0], dataFeeds[0]);

        vm.expectRevert(
            abi.encodeWithSelector(
                IJoeDexLens.JoeDexLens__DataFeedAlreadyAdded.selector, USDC, tokens[1], dataFeeds[1].dfAddress
            )
        );
        joeDexLens.addUSDDataFeed(tokens[1], dataFeeds[1]);

        joeDexLens.removeUSDDataFeed(tokens[0], dataFeeds[0].dfAddress);
        joeDexLens.addUSDDataFeed(tokens[0], dataFeeds[0]);
    }

    function test_RemoveUSDDataFeeds() public {
        (address[] memory tokens, IJoeDexLens.DataFeed[] memory dataFeeds) = getTokenAndDataFeeds(USDC);

        joeDexLens.addUSDDataFeeds(tokens, dataFeeds);

        IJoeDexLens.DataFeed[] memory USDTDataFeeds = joeDexLens.getUSDDataFeeds(USDT);

        assertEq(USDTDataFeeds.length, 2);

        joeDexLens.removeUSDDataFeed(tokens[0], dataFeeds[0].dfAddress);

        vm.expectRevert(
            abi.encodeWithSelector(
                IJoeDexLens.JoeDexLens__DataFeedNotInSet.selector, USDC, tokens[0], dataFeeds[0].dfAddress
            )
        );
        joeDexLens.removeUSDDataFeed(tokens[0], dataFeeds[0].dfAddress);
        USDTDataFeeds = joeDexLens.getUSDDataFeeds(USDT);

        assertEq(USDTDataFeeds.length, 1);
        assertEq(USDTDataFeeds[0].dfAddress, USDCUSDTv1);
        assertEq(USDTDataFeeds[0].dfWeight, 1e18);
        assertEq(uint8(USDTDataFeeds[0].dfType), uint8(IJoeDexLens.dfType.V1));

        joeDexLens.removeUSDDataFeed(tokens[1], dataFeeds[1].dfAddress);
        USDTDataFeeds = joeDexLens.getUSDDataFeeds(USDT);

        assertEq(USDTDataFeeds.length, 0);

        joeDexLens.addUSDDataFeeds(tokens, dataFeeds);

        address[] memory addresses = new address[](2);
        addresses[0] = USDCUSDT1bps;
        addresses[1] = USDCUSDTv1;

        joeDexLens.removeUSDDataFeeds(tokens, addresses);

        USDTDataFeeds = joeDexLens.getUSDDataFeeds(USDT);
        assertEq(USDTDataFeeds.length, 0);
    }

    function test_AddNativeDataFeeds() public {
        (address[] memory tokens, IJoeDexLens.DataFeed[] memory dataFeeds) = getTokenAndDataFeeds(wNative);

        joeDexLens.addNativeDataFeeds(tokens, dataFeeds);

        IJoeDexLens.DataFeed[] memory USDCDataFeeds = joeDexLens.getNativeDataFeeds(USDC);

        assertEq(USDCDataFeeds.length, 2);

        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(address(1), 1, IJoeDexLens.dfType.CHAINLINK);
        joeDexLens.addNativeDataFeed(USDT, df);

        USDCDataFeeds = joeDexLens.getNativeDataFeeds(USDC);

        assertEq(USDCDataFeeds.length, 2);

        assertEq(USDCDataFeeds[0].dfAddress, NativeUSDCv1);
        assertEq(USDCDataFeeds[0].dfWeight, 5e18);
        assertEq(uint8(USDCDataFeeds[0].dfType), uint8(IJoeDexLens.dfType.V1));

        assertEq(USDCDataFeeds[1].dfAddress, NativeUSDC10bps);
        assertEq(USDCDataFeeds[1].dfWeight, 15e18);
        assertEq(uint8(USDCDataFeeds[1].dfType), uint8(IJoeDexLens.dfType.V2));

        IJoeDexLens.DataFeed[] memory USDTDataFeeds = joeDexLens.getNativeDataFeeds(USDT);

        assertEq(USDTDataFeeds[0].dfAddress, address(1));
        assertEq(USDTDataFeeds[0].dfWeight, 1);
        assertEq(uint8(USDTDataFeeds[0].dfType), uint8(IJoeDexLens.dfType.CHAINLINK));
    }

    function test_AddDuplicateNativeDataFeedsReverts() public {
        (address[] memory tokens, IJoeDexLens.DataFeed[] memory dataFeeds) = getTokenAndDataFeeds(wNative);

        joeDexLens.addNativeDataFeeds(tokens, dataFeeds);

        vm.expectRevert(
            abi.encodeWithSelector(
                IJoeDexLens.JoeDexLens__DataFeedAlreadyAdded.selector, wNative, tokens[0], dataFeeds[0].dfAddress
            )
        );
        joeDexLens.addNativeDataFeeds(tokens, dataFeeds);

        vm.expectRevert(
            abi.encodeWithSelector(
                IJoeDexLens.JoeDexLens__DataFeedAlreadyAdded.selector, wNative, tokens[0], dataFeeds[0].dfAddress
            )
        );
        joeDexLens.addNativeDataFeed(tokens[0], dataFeeds[0]);

        vm.expectRevert(
            abi.encodeWithSelector(
                IJoeDexLens.JoeDexLens__DataFeedAlreadyAdded.selector, wNative, tokens[1], dataFeeds[1].dfAddress
            )
        );
        joeDexLens.addNativeDataFeed(tokens[1], dataFeeds[1]);

        joeDexLens.removeNativeDataFeed(tokens[0], dataFeeds[0].dfAddress);
        joeDexLens.addNativeDataFeed(tokens[0], dataFeeds[0]);
    }

    function test_RemoveNativeDataFeeds() public {
        (address[] memory tokens, IJoeDexLens.DataFeed[] memory dataFeeds) = getTokenAndDataFeeds(wNative);

        joeDexLens.addNativeDataFeeds(tokens, dataFeeds);

        IJoeDexLens.DataFeed[] memory USDCDataFeeds = joeDexLens.getNativeDataFeeds(USDC);

        assertEq(USDCDataFeeds.length, 2);

        joeDexLens.removeNativeDataFeed(USDC, dataFeeds[0].dfAddress);
        USDCDataFeeds = joeDexLens.getNativeDataFeeds(USDC);

        assertEq(USDCDataFeeds.length, 1);
        assertEq(USDCDataFeeds[0].dfAddress, NativeUSDC10bps);
        assertEq(USDCDataFeeds[0].dfWeight, 15e18);
        assertEq(uint8(USDCDataFeeds[0].dfType), uint8(IJoeDexLens.dfType.V2));

        joeDexLens.removeNativeDataFeed(USDC, dataFeeds[1].dfAddress);
        USDCDataFeeds = joeDexLens.getNativeDataFeeds(USDC);

        assertEq(USDCDataFeeds.length, 0);

        joeDexLens.addNativeDataFeeds(tokens, dataFeeds);

        address[] memory addresses = new address[](2);
        addresses[0] = NativeUSDCv1;
        addresses[1] = NativeUSDC10bps;

        joeDexLens.removeNativeDataFeeds(tokens, addresses);

        USDCDataFeeds = joeDexLens.getNativeDataFeeds(USDC);
        assertEq(USDCDataFeeds.length, 0);
    }
}
