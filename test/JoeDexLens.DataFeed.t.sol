// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "joe-v2/interfaces/ILBRouter.sol";

import "../src/JoeDexLens.sol";
import "./TestHelper.sol";

contract TestJoeDexLens is TestHelper {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("fuji"), 14_541_000);
        joeDexLens = new JoeDexLens(ILBRouter(LBRouter), IJoeFactory(factoryV1), WAVAX, USDC);
    }

    function testAddUSDDataFeeds() public {
        (address[] memory tokens, IJoeDexLens.DataFeed[] memory dataFeeds) = getTokenAndDataFeeds(USDC);

        joeDexLens.addUSDDataFeeds(tokens, dataFeeds);

        IJoeDexLens.DataFeed[] memory USDTDataFeeds = joeDexLens.getUSDDataFeeds(USDT);

        assertEq(USDTDataFeeds.length, 2);

        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(address(1), 1, IJoeDexLens.dfType.CHAINLINK);
        joeDexLens.addUSDDataFeed(WAVAX, df);

        USDTDataFeeds = joeDexLens.getUSDDataFeeds(USDT);

        assertEq(USDTDataFeeds.length, 2);

        assertEq(USDTDataFeeds[0].dfAddress, USDCUSDT1bps);
        assertEq(USDTDataFeeds[0].dfWeight, 10e18);
        assertEq(uint8(USDTDataFeeds[0].dfType), uint8(IJoeDexLens.dfType.V2));

        assertEq(USDTDataFeeds[1].dfAddress, USDCUSDTv1);
        assertEq(USDTDataFeeds[1].dfWeight, 1e18);
        assertEq(uint8(USDTDataFeeds[1].dfType), uint8(IJoeDexLens.dfType.V1));

        IJoeDexLens.DataFeed[] memory WAVAXDataFeeds = joeDexLens.getUSDDataFeeds(WAVAX);

        assertEq(WAVAXDataFeeds[0].dfAddress, address(1));
        assertEq(WAVAXDataFeeds[0].dfWeight, 1);
        assertEq(uint8(WAVAXDataFeeds[0].dfType), uint8(IJoeDexLens.dfType.CHAINLINK));
    }

    function testSetWeightUSDDataFeeds() public {
        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(address(1), 1, IJoeDexLens.dfType.CHAINLINK);
        joeDexLens.addUSDDataFeed(WAVAX, df);

        vm.expectRevert(abi.encodeWithSelector(JoeDexLens__NullWeight.selector));
        joeDexLens.setUSDDataFeedWeight(WAVAX, df.dfAddress, 0);

        joeDexLens.setUSDDataFeedWeight(WAVAX, df.dfAddress, 1e18);

        IJoeDexLens.DataFeed[] memory WAVAXDataFeeds = joeDexLens.getUSDDataFeeds(WAVAX);
        assertEq(WAVAXDataFeeds[0].dfWeight, 1e18);

        address[] memory wavaxSingleton = getAddressSingleton(WAVAX);
        address[] memory dfAddressSingleton = getAddressSingleton(df.dfAddress);
        uint88[] memory uint8Singleton = getUint88Singleton(20);

        joeDexLens.setUSDDataFeedWeights(wavaxSingleton, dfAddressSingleton, uint8Singleton);

        IJoeDexLens.DataFeed[] memory WAVAXDataFeeds2 = joeDexLens.getUSDDataFeeds(WAVAX);
        assertEq(WAVAXDataFeeds2[0].dfWeight, 20);
    }

    function testSetWeightAVAXDataFeeds() public {
        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(address(1), 1, IJoeDexLens.dfType.CHAINLINK);
        joeDexLens.addAVAXDataFeed(USDC, df);

        vm.expectRevert(abi.encodeWithSelector(JoeDexLens__NullWeight.selector));
        joeDexLens.setAVAXDataFeedWeight(USDC, df.dfAddress, 0);

        joeDexLens.setAVAXDataFeedWeight(USDC, df.dfAddress, 1e18);

        IJoeDexLens.DataFeed[] memory USDCDataFeeds = joeDexLens.getAVAXDataFeeds(USDC);
        assertEq(USDCDataFeeds[0].dfWeight, 1e18);

        address[] memory usdcSingleton = getAddressSingleton(USDC);
        address[] memory dfAddressSingleton = getAddressSingleton(df.dfAddress);
        uint88[] memory uint8Singleton = getUint88Singleton(10);

        joeDexLens.setAVAXDataFeedWeights(usdcSingleton, dfAddressSingleton, uint8Singleton);

        IJoeDexLens.DataFeed[] memory USDCDataFeeds2 = joeDexLens.getAVAXDataFeeds(USDC);
        assertEq(USDCDataFeeds2[0].dfWeight, 10);
    }

    function testAddDuplicateUSDDataFeedsReverts() public {
        (address[] memory tokens, IJoeDexLens.DataFeed[] memory dataFeeds) = getTokenAndDataFeeds(USDC);

        joeDexLens.addUSDDataFeeds(tokens, dataFeeds);

        vm.expectRevert(
            abi.encodeWithSelector(JoeDexLens__DataFeedAlreadyAdded.selector, USDC, tokens[0], dataFeeds[0].dfAddress)
        );
        joeDexLens.addUSDDataFeeds(tokens, dataFeeds);

        vm.expectRevert(
            abi.encodeWithSelector(JoeDexLens__DataFeedAlreadyAdded.selector, USDC, tokens[0], dataFeeds[0].dfAddress)
        );
        joeDexLens.addUSDDataFeed(tokens[0], dataFeeds[0]);

        vm.expectRevert(
            abi.encodeWithSelector(JoeDexLens__DataFeedAlreadyAdded.selector, USDC, tokens[1], dataFeeds[1].dfAddress)
        );
        joeDexLens.addUSDDataFeed(tokens[1], dataFeeds[1]);

        joeDexLens.removeUSDDataFeed(tokens[0], dataFeeds[0].dfAddress);
        joeDexLens.addUSDDataFeed(tokens[0], dataFeeds[0]);
    }

    function testRemoveUSDDataFeeds() public {
        (address[] memory tokens, IJoeDexLens.DataFeed[] memory dataFeeds) = getTokenAndDataFeeds(USDC);

        joeDexLens.addUSDDataFeeds(tokens, dataFeeds);

        IJoeDexLens.DataFeed[] memory USDTDataFeeds = joeDexLens.getUSDDataFeeds(USDT);

        assertEq(USDTDataFeeds.length, 2);

        joeDexLens.removeUSDDataFeed(tokens[0], dataFeeds[0].dfAddress);

        vm.expectRevert(
            abi.encodeWithSelector(JoeDexLens__DataFeedNotInSet.selector, USDC, tokens[0], dataFeeds[0].dfAddress)
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

    function testAddAVAXDataFeeds() public {
        (address[] memory tokens, IJoeDexLens.DataFeed[] memory dataFeeds) = getTokenAndDataFeeds(WAVAX);

        joeDexLens.addAVAXDataFeeds(tokens, dataFeeds);

        IJoeDexLens.DataFeed[] memory USDCDataFeeds = joeDexLens.getAVAXDataFeeds(USDC);

        assertEq(USDCDataFeeds.length, 2);

        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(address(1), 1, IJoeDexLens.dfType.CHAINLINK);
        joeDexLens.addAVAXDataFeed(USDT, df);

        USDCDataFeeds = joeDexLens.getAVAXDataFeeds(USDC);

        assertEq(USDCDataFeeds.length, 2);

        assertEq(USDCDataFeeds[0].dfAddress, AVAXUSDCv1);
        assertEq(USDCDataFeeds[0].dfWeight, 5e18);
        assertEq(uint8(USDCDataFeeds[0].dfType), uint8(IJoeDexLens.dfType.V1));

        assertEq(USDCDataFeeds[1].dfAddress, AVAXUSDC10bps);
        assertEq(USDCDataFeeds[1].dfWeight, 15e18);
        assertEq(uint8(USDCDataFeeds[1].dfType), uint8(IJoeDexLens.dfType.V2));

        IJoeDexLens.DataFeed[] memory USDTDataFeeds = joeDexLens.getAVAXDataFeeds(USDT);

        assertEq(USDTDataFeeds[0].dfAddress, address(1));
        assertEq(USDTDataFeeds[0].dfWeight, 1);
        assertEq(uint8(USDTDataFeeds[0].dfType), uint8(IJoeDexLens.dfType.CHAINLINK));
    }

    function testAddDuplicateAVAXDataFeedsReverts() public {
        (address[] memory tokens, IJoeDexLens.DataFeed[] memory dataFeeds) = getTokenAndDataFeeds(WAVAX);

        joeDexLens.addAVAXDataFeeds(tokens, dataFeeds);

        vm.expectRevert(
            abi.encodeWithSelector(JoeDexLens__DataFeedAlreadyAdded.selector, WAVAX, tokens[0], dataFeeds[0].dfAddress)
        );
        joeDexLens.addAVAXDataFeeds(tokens, dataFeeds);

        vm.expectRevert(
            abi.encodeWithSelector(JoeDexLens__DataFeedAlreadyAdded.selector, WAVAX, tokens[0], dataFeeds[0].dfAddress)
        );
        joeDexLens.addAVAXDataFeed(tokens[0], dataFeeds[0]);

        vm.expectRevert(
            abi.encodeWithSelector(JoeDexLens__DataFeedAlreadyAdded.selector, WAVAX, tokens[1], dataFeeds[1].dfAddress)
        );
        joeDexLens.addAVAXDataFeed(tokens[1], dataFeeds[1]);

        joeDexLens.removeAVAXDataFeed(tokens[0], dataFeeds[0].dfAddress);
        joeDexLens.addAVAXDataFeed(tokens[0], dataFeeds[0]);
    }

    function testRemoveAVAXDataFeeds() public {
        (address[] memory tokens, IJoeDexLens.DataFeed[] memory dataFeeds) = getTokenAndDataFeeds(WAVAX);

        joeDexLens.addAVAXDataFeeds(tokens, dataFeeds);

        IJoeDexLens.DataFeed[] memory USDCDataFeeds = joeDexLens.getAVAXDataFeeds(USDC);

        assertEq(USDCDataFeeds.length, 2);

        joeDexLens.removeAVAXDataFeed(USDC, dataFeeds[0].dfAddress);
        USDCDataFeeds = joeDexLens.getAVAXDataFeeds(USDC);

        assertEq(USDCDataFeeds.length, 1);
        assertEq(USDCDataFeeds[0].dfAddress, AVAXUSDC10bps);
        assertEq(USDCDataFeeds[0].dfWeight, 15e18);
        assertEq(uint8(USDCDataFeeds[0].dfType), uint8(IJoeDexLens.dfType.V2));

        joeDexLens.removeAVAXDataFeed(USDC, dataFeeds[1].dfAddress);
        USDCDataFeeds = joeDexLens.getAVAXDataFeeds(USDC);

        assertEq(USDCDataFeeds.length, 0);

        joeDexLens.addAVAXDataFeeds(tokens, dataFeeds);

        address[] memory addresses = new address[](2);
        addresses[0] = AVAXUSDCv1;
        addresses[1] = AVAXUSDC10bps;

        joeDexLens.removeAVAXDataFeeds(tokens, addresses);

        USDCDataFeeds = joeDexLens.getAVAXDataFeeds(USDC);
        assertEq(USDCDataFeeds.length, 0);
    }
}
