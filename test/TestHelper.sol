// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "joe-v2/interfaces/ILBRouter.sol";
import "joe-v2/interfaces/ILBFactory.sol";
import "joe-v2/interfaces/IJoeRouter02.sol";
import "joe-v2/LBPair.sol";
import "joe-v2/LBRouter.sol";
import "joe-v2/LBFactory.sol";
import "openzeppelin/token/ERC20/IERC20.sol";

import "../src/JoeDexLens.sol";
import "../src/interfaces/AggregatorV3Interface.sol";
import "./mocks/ERC20MockDecimals.sol";
import "./mocks/MockAggregator.sol";

abstract contract TestHelper is Test {
    using Uint256x256Math for uint256;

    address payable internal immutable DEV = payable(address(this));
    address internal immutable ALICE = makeAddr("alice");

    uint8 internal constant DEFAULT_BIN_STEP = 20;
    uint16 internal constant DEFAULT_BASE_FACTOR = 5_000;
    uint16 internal constant DEFAULT_FILTER_PERIOD = 30;
    uint16 internal constant DEFAULT_DECAY_PERIOD = 600;
    uint16 internal constant DEFAULT_REDUCTION_FACTOR = 5_000;
    uint24 internal constant DEFAULT_VARIABLE_FEE_CONTROL = 40_000;
    uint16 internal constant DEFAULT_PROTOCOL_SHARE = 1_000;
    uint24 internal constant DEFAULT_MAX_VOLATILITY_ACCUMULATOR = 350_000;
    uint256 internal constant DEFAULT_FLASHLOAN_FEE = 8e14;
    uint24 internal constant ID_ONE = 2 ** 23;

    address public constant tokenOwner = 0xFFC08538077a0455E0F4077823b1A0E3e18Faf0b;
    address public constant factoryOwner = 0x2fbB61a10B96254900C03F1644E9e1d2f5E76DD2;
    address public constant avaxDataFeed = 0x0A77230d17318075983913bC2145DB16C7366156;

    LBRouter public lbRouter;
    LBFactory public lbFactory;

    ILBLegacyFactory public constant LBLegacyFactory = ILBLegacyFactory(0x6E77932A92582f504FF6c4BdbCef7Da6c198aEEf);
    ILBLegacyRouter public constant LBLegacyRouter = ILBLegacyRouter(0xE3Ffc583dC176575eEA7FD9dF2A7c65F7E23f4C3);
    IJoeFactory public constant factoryV1 = IJoeFactory(0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10);

    address public constant USDT = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;
    address public constant USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    address public constant WETH = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;
    address public constant wNative = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public constant DAI = 0x1C5db575E2Ff833E46a2E9864C22F4B22E0B37C2;
    address public constant JOE = 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd;
    address public constant ZJOE = 0x769bfeb9fAacD6Eb2746979a8dD0b7e9920aC2A4;

    address public constant AVAX_USDC_V1 = 0xf4003F4efBE8691B60249E6afbD307aBE7758adb;
    address public constant AVAX_USDT_V1 = 0xbb4646a764358ee93c2a9c4a147d5aDEd527ab73;
    address public constant AVAX_ETH_V1 = 0xFE15c2695F1F920da45C30AAE47d11dE51007AF9;

    address public constant AVAX_USDC_20BP = 0xB5352A39C11a81FE6748993D586EC448A01f08b5;
    address public constant AVAX_USDT_20BP = 0xdF3E481a05F58c387Af16867e9F5dB7f931113c9;
    address public constant AVAX_ETH_10BP = 0x42Be75636374dfA0e57EB96fA7F68fE7FcdAD8a3;
    address public constant ETH_USDC_15BP = 0x5851E2d6396bcc26FB9eEE21effbF99e0d2B2148;
    address public constant ZJOE_JOE_5BP = 0xeDdE9c9F9960784870A84Aaafcb77F965DF012aa;
    address public constant JOE_USDC_25BP = 0xf1f4CE5Dd70D4384F9B764020f26E8CABEE39070;
    address public constant DAI_USDC_1BP = 0x855Ee438445075F25C18A125BA6607543052A194;
    address public constant JOE_AVAX_15BP = 0xc01961EdE437Bf0cC41D064B1a3F6F0ea6aa2a40;

    JoeDexLens public joeDexLens;

    bool useLegacyBinStep = true;

    function setUp() public virtual {
        lbFactory = new LBFactory(DEV,  DEFAULT_FLASHLOAN_FEE);
        lbFactory.setLBPairImplementation(address(new LBPair(lbFactory)));

        lbRouter = new LBRouter(lbFactory, factoryV1, LBLegacyFactory, LBLegacyRouter, IWNATIVE(wNative));

        lbFactory.setPreset(
            DEFAULT_BIN_STEP * 2,
            DEFAULT_BASE_FACTOR,
            DEFAULT_FILTER_PERIOD,
            DEFAULT_DECAY_PERIOD,
            DEFAULT_REDUCTION_FACTOR,
            DEFAULT_VARIABLE_FEE_CONTROL,
            DEFAULT_PROTOCOL_SHARE,
            DEFAULT_MAX_VOLATILITY_ACCUMULATOR,
            true
        );

        lbFactory.addQuoteAsset(IERC20(USDC));

        vm.prank(factoryOwner);
        LBLegacyFactory.setFactoryLockedState(false);

        vm.label(address(lbFactory), "factory");
        vm.label(address(lbRouter), "router");
        vm.label(address(LBLegacyFactory), "legacyFactory");
        vm.label(address(factoryV1), "joeFactoryV1");
        vm.label(USDC, "usdc");
        vm.label(USDT, "usdt");
        vm.label(WETH, "weth");
        vm.label(wNative, "wNative");

        vm.label(AVAX_USDC_V1, "avax_usdc_v1");
        vm.label(AVAX_USDT_V1, "avax_usdt_v1");
        vm.label(AVAX_ETH_V1, "avax_eth_v1");

        vm.label(AVAX_USDC_20BP, "avax_usdc_20bp");
        vm.label(AVAX_USDT_20BP, "avax_usdt_20bp");
        vm.label(AVAX_ETH_10BP, "avax_eth_10bp");
        vm.label(ZJOE_JOE_5BP, "zjoe_joe_5bp");
        vm.label(JOE_USDC_25BP, "joe_usdc_25bp");
        vm.label(DAI_USDC_1BP, "dai_usdc_1bp");
    }
}
