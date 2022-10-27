// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "joe-v2/interfaces/ILBRouter.sol";
import "joe-v2/interfaces/ILBFactory.sol";
import "joe-v2/interfaces/IJoeRouter02.sol";
import "joe-v2/LBErrors.sol";
import "openzeppelin/token/ERC20/IERC20.sol";

import "../src/JoeDexLens.sol";
import "../src/interfaces/AggregatorV3Interface.sol";
import "./mocks/ERC20MockDecimals.sol";

abstract contract TestHelper is Test {
    using Math512Bits for uint256;

    address payable internal immutable DEV = payable(address(this));
    address internal immutable ALICE = address(bytes20(bytes32(keccak256(bytes("ALICE")))));

    uint16 internal constant DEFAULT_BIN_STEP = 20;
    uint24 internal constant ID_ONE = 2**23;

    address public constant TokenOwner = 0xFFC08538077a0455E0F4077823b1A0E3e18Faf0b;
    address public constant factoryOwner = 0x4f029B3faA0fE6405Ae6eBA5795293688cf69c2e;

    ILBFactory public constant LBFactory = ILBFactory(0x2950b9bd19152C91d69227364747b3e6EFC8Ab7F);
    ILBRouter public constant LBRouter = ILBRouter(0x0C344c52841d3F8d488E1CcDBafB42CE2C7fdFA9);
    IJoeFactory public constant joeFactory = IJoeFactory(0xF5c7d9733e5f53abCC1695820c4818C59B457C2C);

    address public constant LBQuoter = 0x0C926BF1E71725eD68AE3041775e9Ba29142dca9;
    address public constant factoryV1 = 0xF5c7d9733e5f53abCC1695820c4818C59B457C2C;
    address public constant routerV1 = 0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901;

    address public constant USDT = 0xAb231A5744C8E6c45481754928cCfFFFD4aa0732;
    address public constant USDC = 0xB6076C93701D6a07266c31066B298AeC6dd65c2d;
    address public constant wNative = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;

    address public constant USDCUSDTv1 = 0x8625feb95141008FE48ea5cf8A7dd84A83a72d9E;
    address public constant NativeUSDCv1 = 0x9371619C8E2A487D57FB9F8E36Bcb0317Bff0529;

    address public constant USDCUSDT1bps = 0x0716FBE78331932d0Fd9A284b22F0342a6FD8ee8;
    address public constant NativeUSDC10bps = 0x1579647e8cc2338111e131A01AF62d85870A659b;
    address public constant NativeUSDC20bps = 0xc8aa3bF8623C35EAc518Ea82B55C2aa46D5A02f6;

    JoeDexLens public joeDexLens;

    function createPairAndAddToUSDDataFeeds(
        address tokenX,
        address tokenY,
        uint24 id
    ) internal {
        ILBPair pair = LBRouter.createLBPair(IERC20(tokenX), IERC20(tokenY), id, DEFAULT_BIN_STEP);

        IJoeDexLens.DataFeed memory dataFeed = IJoeDexLens.DataFeed(address(pair), 1e18, IJoeDexLens.dfType.V2);

        IJoeDexLens.DataFeed[] memory dataFeeds = new IJoeDexLens.DataFeed[](1);
        dataFeeds[0] = dataFeed;

        if (tokenX == USDC || tokenY == USDC) {
            address token = tokenX == USDC ? tokenY : tokenX;

            address[] memory tokens = new address[](1);
            tokens[0] = token;

            joeDexLens.addUSDDataFeeds(tokens, dataFeeds);
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
}
