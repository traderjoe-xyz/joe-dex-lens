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

abstract contract TestHelper is Test {
    using Utils for ILBRouter.LiquidityParameters;
    using Uint256x256Math for uint256;
    using Utils for uint256[];
    using Utils for int256[];

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
    address public constant factoryOwner = 0x4f029B3faA0fE6405Ae6eBA5795293688cf69c2e;

    LBRouter public lbRouter;
    LBFactory public lbFactory;

    ILBLegacyFactory public constant LBLegacyFactory = ILBLegacyFactory(0x2950b9bd19152C91d69227364747b3e6EFC8Ab7F);
    ILBLegacyRouter public constant LBLegacyRouter = ILBLegacyRouter(0x0C344c52841d3F8d488E1CcDBafB42CE2C7fdFA9);
    IJoeFactory public constant joeFactory = IJoeFactory(0xF5c7d9733e5f53abCC1695820c4818C59B457C2C);

    address public constant LBQuoter = 0x0C926BF1E71725eD68AE3041775e9Ba29142dca9;
    address public constant factoryV1 = 0xF5c7d9733e5f53abCC1695820c4818C59B457C2C;
    address public constant routerV1 = 0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901;

    address public constant USDT = 0xAb231A5744C8E6c45481754928cCfFFFD4aa0732;
    address public constant USDC = 0xB6076C93701D6a07266c31066B298AeC6dd65c2d;
    address public constant WETH = 0x1886D09C9Ade0c5DB822D85D21678Db67B6c2982;
    address public constant wNative = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;

    address public constant USDCUSDTv1 = 0x8625feb95141008FE48ea5cf8A7dd84A83a72d9E;
    address public constant NativeUSDCv1 = 0x9371619C8E2A487D57FB9F8E36Bcb0317Bff0529;

    address public constant USDCUSDT1bps = 0x0716FBE78331932d0Fd9A284b22F0342a6FD8ee8;
    address public constant NativeUSDC10bps = 0x1579647e8cc2338111e131A01AF62d85870A659b;
    address public constant NativeUSDC20bps = 0xc8aa3bF8623C35EAc518Ea82B55C2aa46D5A02f6;

    JoeDexLens public joeDexLens;

    bool useLegacyBinStep = true;

    function setUp() public virtual {
        lbFactory = new LBFactory(DEV,  DEFAULT_FLASHLOAN_FEE);
        lbFactory.setLBPairImplementation(address(new LBPair(lbFactory)));

        lbRouter = new LBRouter(lbFactory, IJoeFactory(factoryV1), LBLegacyFactory, LBLegacyRouter, IWAVAX(wNative));

        lbFactory.setPreset(
            DEFAULT_BIN_STEP * 2,
            DEFAULT_BASE_FACTOR,
            DEFAULT_FILTER_PERIOD,
            DEFAULT_DECAY_PERIOD,
            DEFAULT_REDUCTION_FACTOR,
            DEFAULT_VARIABLE_FEE_CONTROL,
            DEFAULT_PROTOCOL_SHARE,
            DEFAULT_MAX_VOLATILITY_ACCUMULATOR
        );

        lbFactory.setOpenPreset(DEFAULT_BIN_STEP * 2, true);
        lbFactory.addQuoteAsset(IERC20(USDC));

        vm.prank(factoryOwner);
        LBLegacyFactory.setFactoryLockedState(false);

        vm.label(address(lbFactory), "factory");
        vm.label(address(lbRouter), "router");
        vm.label(address(LBLegacyFactory), "legacyFactory");
        vm.label(address(LBLegacyRouter), "legacyRouter");
        vm.label(address(factoryV1), "joeFactoryV1");
        vm.label(USDC, "usdc");
        vm.label(USDT, "usdt");
        vm.label(WETH, "weth");
        vm.label(wNative, "wNative");
    }

    function createPairAndAddToUSDDataFeeds(address tokenX, address tokenY, uint24 id, IJoeDexLens.dfType pairType)
        internal
    {
        if (pairType == IJoeDexLens.dfType.V2) {
            ILBLegacyPair pair = LBLegacyRouter.createLBPair(IERC20(tokenX), IERC20(tokenY), id, DEFAULT_BIN_STEP);

            IJoeDexLens.DataFeed memory dataFeed = IJoeDexLens.DataFeed(address(pair), 1e18, IJoeDexLens.dfType.V2);

            IJoeDexLens.DataFeed[] memory dataFeeds = new IJoeDexLens.DataFeed[](1);
            dataFeeds[0] = dataFeed;

            if (tokenX == USDC || tokenY == USDC) {
                address token = tokenX == USDC ? tokenY : tokenX;

                address[] memory tokens = new address[](1);
                tokens[0] = token;

                joeDexLens.addUSDDataFeeds(tokens, dataFeeds);
            }
        } else {
            ILBPair pair = lbRouter.createLBPair(IERC20(tokenX), IERC20(tokenY), id, DEFAULT_BIN_STEP * 2);

            IJoeDexLens.DataFeed memory dataFeed = IJoeDexLens.DataFeed(address(pair), 1e18, IJoeDexLens.dfType.V2_1);

            IJoeDexLens.DataFeed[] memory dataFeeds = new IJoeDexLens.DataFeed[](1);
            dataFeeds[0] = dataFeed;

            if (tokenX == USDC || tokenY == USDC) {
                address token = tokenX == USDC ? tokenY : tokenX;

                address[] memory tokens = new address[](1);
                tokens[0] = token;

                joeDexLens.addUSDDataFeeds(tokens, dataFeeds);
            }
        }
    }

    function addUSDDataFeed(address token, address pair) internal {
        IJoeDexLens.DataFeed[] memory dataFeeds = new IJoeDexLens.DataFeed[](1);
        address[] memory tokens = new address[](1);

        dataFeeds[0] = IJoeDexLens.DataFeed(address(pair), 1e18, IJoeDexLens.dfType.V2);
        tokens[0] = token;

        joeDexLens.addUSDDataFeeds(tokens, dataFeeds);
    }

    function getTokenAndDataFeeds(address _collateral)
        internal
        pure
        returns (address[] memory tokens, IJoeDexLens.DataFeed[] memory dataFeeds)
    {
        tokens = new address[](2);
        dataFeeds = new IJoeDexLens.DataFeed[](2);

        if (_collateral == USDC) {
            tokens[0] = USDT;
            tokens[1] = USDT;

            dataFeeds[0] = IJoeDexLens.DataFeed(USDCUSDT1bps, 10e18, IJoeDexLens.dfType.V2);
            dataFeeds[1] = IJoeDexLens.DataFeed(USDCUSDTv1, 1e18, IJoeDexLens.dfType.V1);
        } else {
            tokens[0] = USDC;
            tokens[1] = USDC;

            dataFeeds[0] = IJoeDexLens.DataFeed(NativeUSDCv1, 5e18, IJoeDexLens.dfType.V1);
            dataFeeds[1] = IJoeDexLens.DataFeed(NativeUSDC10bps, 15e18, IJoeDexLens.dfType.V2);
        }
    }

    function getTokenAndDataFeedAddressess(address _collateral)
        internal
        pure
        returns (address[] memory tokens, address[] memory dfAddresses)
    {
        tokens = new address[](2);
        dfAddresses = new address[](2);

        if (_collateral == USDC) {
            tokens[0] = USDT;
            tokens[1] = USDT;

            dfAddresses[0] = USDCUSDT1bps;
            dfAddresses[1] = USDCUSDTv1;
        } else {
            tokens[0] = USDC;
            tokens[1] = USDC;

            dfAddresses[0] = NativeUSDCv1;
            dfAddresses[1] = NativeUSDC10bps;
        }
    }

    function getAddressSingleton(address token) public pure returns (address[] memory tokens) {
        tokens = new address[](1);
        tokens[0] = token;
    }

    function getUint88Singleton(uint88 weight) public pure returns (uint88[] memory weights) {
        weights = new uint88[](1);
        weights[0] = weight;
    }

    function getDataFeedSingleton(IJoeDexLens.DataFeed memory df)
        public
        pure
        returns (IJoeDexLens.DataFeed[] memory dfs)
    {
        dfs = new IJoeDexLens.DataFeed[](1);
        dfs[0] = df;
    }

    function getLiquidityParameters(
        IERC20 tokenX,
        IERC20 tokenY,
        uint256 amountYIn,
        uint24 startId,
        uint24 numberBins,
        uint24 gap
    ) internal view returns (ILBRouter.LiquidityParameters memory liquidityParameters) {
        (uint256[] memory ids, uint256[] memory distributionX, uint256[] memory distributionY, uint256 amountXIn) =
            spreadLiquidity(amountYIn, startId, numberBins, gap);

        liquidityParameters = ILBRouter.LiquidityParameters({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: useLegacyBinStep ? DEFAULT_BIN_STEP : DEFAULT_BIN_STEP * 2,
            amountX: amountXIn,
            amountY: amountYIn,
            amountXMin: 0,
            amountYMin: 0,
            activeIdDesired: startId,
            idSlippage: 0,
            deltaIds: ids.convertToRelative(startId),
            distributionX: distributionX,
            distributionY: distributionY,
            to: DEV,
            refundTo: DEV,
            deadline: block.timestamp + 1000
        });
    }

    function spreadLiquidity(uint256 amountYIn, uint24 startId, uint24 numberBins, uint24 gap)
        internal
        view
        returns (
            uint256[] memory ids,
            uint256[] memory distributionX,
            uint256[] memory distributionY,
            uint256 amountXIn
        )
    {
        if (numberBins % 2 == 0) {
            revert("Pls put an uneven number of bins");
        }

        uint24 spread = numberBins / 2;
        ids = new uint256[](numberBins);

        distributionX = new uint256[](numberBins);
        distributionY = new uint256[](numberBins);
        uint256 binDistribution = Constants.PRECISION / (spread + 1);
        uint256 binLiquidity = amountYIn / (spread + 1);

        for (uint256 i; i < numberBins; i++) {
            ids[i] = startId - spread * (1 + gap) + i * (1 + gap);

            if (i <= spread) {
                distributionY[i] = binDistribution;
            }
            if (i >= spread) {
                distributionX[i] = binDistribution;
                amountXIn += binLiquidity > 0
                    ? binLiquidity.shiftDivRoundDown(Constants.SCALE_OFFSET, getPriceFromId(uint24(ids[i])))
                    : 0;
            }
        }
    }

    function getPriceFromId(uint24 id) internal view returns (uint256 price) {
        price = PriceHelper.getPriceFromId(id, useLegacyBinStep ? DEFAULT_BIN_STEP * 2 : DEFAULT_BIN_STEP);
    }
}

library Utils {
    function convertToAbsolute(int256[] memory relativeIds, uint24 startId)
        internal
        pure
        returns (uint256[] memory absoluteIds)
    {
        absoluteIds = new uint256[](relativeIds.length);
        for (uint256 i = 0; i < relativeIds.length; i++) {
            int256 id = int256(uint256(startId)) + relativeIds[i];
            require(id >= 0, "Id conversion: id must be positive");
            absoluteIds[i] = uint256(id);
        }
    }

    function convertToRelative(uint256[] memory absoluteIds, uint24 startId)
        internal
        pure
        returns (int256[] memory relativeIds)
    {
        relativeIds = new int256[](absoluteIds.length);
        for (uint256 i = 0; i < absoluteIds.length; i++) {
            relativeIds[i] = int256(absoluteIds[i]) - int256(uint256(startId));
        }
    }

    function toLegacy(ILBRouter.LiquidityParameters memory liquidityParameters)
        internal
        pure
        returns (ILBLegacyRouter.LiquidityParameters memory legacyLiquidityParameters)
    {
        legacyLiquidityParameters = ILBLegacyRouter.LiquidityParameters({
            tokenX: liquidityParameters.tokenX,
            tokenY: liquidityParameters.tokenY,
            binStep: liquidityParameters.binStep,
            amountX: liquidityParameters.amountX,
            amountY: liquidityParameters.amountY,
            amountXMin: liquidityParameters.amountXMin,
            amountYMin: liquidityParameters.amountYMin,
            activeIdDesired: liquidityParameters.activeIdDesired,
            idSlippage: liquidityParameters.idSlippage,
            deltaIds: liquidityParameters.deltaIds,
            distributionX: liquidityParameters.distributionX,
            distributionY: liquidityParameters.distributionY,
            to: liquidityParameters.to,
            deadline: liquidityParameters.deadline
        });
    }
}
