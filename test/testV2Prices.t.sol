// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "joe-v2/LBErrors.sol";
import "joe-v2/interfaces/ILBRouter.sol";

import "../src/JoeDexLens.sol";
import "./mocks/ERC20MockDecimals.sol";

contract TestV2Prices is
    Test,
    JoeDexLens(
        0x0C344c52841d3F8d488E1CcDBafB42CE2C7fdFA9,
        0xF5c7d9733e5f53abCC1695820c4818C59B457C2C,
        0xd00ae08403B9bbb9124bB305C09058E32C39A48c,
        0xB6076C93701D6a07266c31066B298AeC6dd65c2d
    )
{
    ERC20MockDecimals internal token6D;
    ERC20MockDecimals internal token10D;
    ERC20MockDecimals internal token12D;
    ERC20MockDecimals internal token18D;
    ERC20MockDecimals internal token24D;

    address public factoryOwner = 0x4f029B3faA0fE6405Ae6eBA5795293688cf69c2e;
    address public LBFactory = 0x2950b9bd19152C91d69227364747b3e6EFC8Ab7F;

    uint16 internal constant DEFAULT_BIN_STEP = 20;
    uint24 internal constant ID_ONE = 2**23;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("fuji"), 14_541_000);
        token6D = new ERC20MockDecimals(6);
        token10D = new ERC20MockDecimals(10);
        token12D = new ERC20MockDecimals(12);
        token18D = new ERC20MockDecimals(18);
        token24D = new ERC20MockDecimals(24);
        ILBFactory factory = ILBFactory(LBFactory);

        vm.startPrank(factoryOwner);
        factory.setFactoryLockedState(false);
        factory.addQuoteAsset(token6D);
        factory.addQuoteAsset(token10D);
        factory.addQuoteAsset(token12D);
        factory.addQuoteAsset(token18D);
        factory.addQuoteAsset(token24D);
        vm.stopPrank();
    }

    function testV2PriceDecimals() public {
        ILBPair pair610 = V2Router.createLBPair(token6D, token10D, ID_ONE, DEFAULT_BIN_STEP);
        ILBPair pair624 = V2Router.createLBPair(token6D, token24D, ID_ONE, DEFAULT_BIN_STEP);
        uint256 price6din10d = _getPriceFromV2(address(pair610), address(token6D));
        uint256 price10dIn6d = _getPriceFromV2(address(pair610), address(token10D));

        assertEq(price6din10d, price10dIn6d + 1);
        uint256 price6dIn24d = _getPriceFromV2(address(pair624), address(token6D));
        uint256 price24dIn6d = _getPriceFromV2(address(pair624), address(token24D));

        assertEq(price6dIn24d, price24dIn6d + 1);
    }

    function testV2PriceDecimalsReverse() public {
        ILBPair pair610 = V2Router.createLBPair(token10D, token6D, ID_ONE, DEFAULT_BIN_STEP);
        ILBPair pair624 = V2Router.createLBPair(token24D, token6D, ID_ONE, DEFAULT_BIN_STEP);
        uint256 price6din10d = _getPriceFromV2(address(pair610), address(token6D));
        uint256 price10dIn6d = _getPriceFromV2(address(pair610), address(token10D));
        assertEq(price6din10d + 1, price10dIn6d);

        uint256 price6dIn24d = _getPriceFromV2(address(pair624), address(token6D));
        uint256 price24dIn6d = _getPriceFromV2(address(pair624), address(token24D));
        assertEq(price6dIn24d + 1, price24dIn6d);
    }
}
