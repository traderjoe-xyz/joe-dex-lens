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

    uint8 internal constant DEFAULT_BIN_STEP = 25;
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

    ILBRouter public constant lbRouter = ILBRouter(0xb4315e873dBcf96Ffd0acd8EA43f689D8c20fB30);
    ILBFactory public lbFactory = ILBFactory(0x8e42f2F4101563bF679975178e880FD87d3eFd4e);
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

    address public constant AVAX_USDC_20BP = 0xD446eb1660F766d533BeCeEf890Df7A69d26f7d1;
    address public constant AVAX_USDT_20BP = 0x87EB2F90d7D0034571f343fb7429AE22C1Bd9F72;
    address public constant AVAX_ETH_10BP = 0x1901011a39B11271578a1283D620373aBeD66faA;
    address public constant ETH_USDC_15BP = 0x51146e0bF2dCC368DE6F5201FE7c427DA28D05De;
    address public constant JOE_USDC_25BP = 0x9A0A97D8005d9f783A054aa5CD8878bB0CCF414D;
    address public constant DAI_USDC_1BP = 0x2f1DA4bafd5f2508EC2e2E425036063A374993B6;
    address public constant JOE_AVAX_15BP = 0x9f8973FB86b35C307324eC31fd81Cf565E2F4a63;

    JoeDexLens public joeDexLens;

    function setUp() public virtual {
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
        vm.label(JOE_USDC_25BP, "joe_usdc_25bp");
        vm.label(DAI_USDC_1BP, "dai_usdc_1bp");
    }

    function createLBPairV2_1(address tokenA, address quoteToken, uint24 id) internal returns (address) {
        return address(lbFactory.createLBPair(IERC20(tokenA), IERC20(quoteToken), id, DEFAULT_BIN_STEP));
    }

    function addLiquidityV2_1(address pair, uint256 amountX, uint256 amountY) internal {
        require(amountX > 0 && amountY > 0, "TestHelper: amount must be greater than 0");

        IERC20 tokenX = ILBPair(pair).getTokenX();
        IERC20 tokenY = ILBPair(pair).getTokenY();
        uint24 activeId = ILBPair(pair).getActiveId();

        tokenX.approve(address(lbRouter), amountX);
        tokenY.approve(address(lbRouter), amountY);

        deal(address(tokenX), pair, tokenX.balanceOf(pair) + amountX);
        deal(address(tokenY), pair, tokenY.balanceOf(pair) + amountY);

        bytes32[] memory config = new bytes32[](9);

        for (uint24 i = 0; i < 9; i++) {
            uint24 id = activeId - 4 + i;

            uint64 distribX = id >= activeId ? 0.2e18 : 0;
            uint64 distribY = id <= activeId ? 0.2e18 : 0;

            config[i] = LiquidityConfigurations.encodeParams(distribX, distribY, id);
        }

        ILBPair(pair).mint(DEV, config, DEV);
    }
}
