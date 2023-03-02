// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./TestHelper.sol";

contract TestSkippingVersions is TestHelper {
    ERC20MockDecimals internal token10D;

    uint24 SHIFT_ID_ONE_1e4 = 4_609; // The result of `log( 1e10/1e6 ) / log(1.002)`, when 1 token6D is equal to 1 token10D

    function setUp() public override {
        vm.createSelectFork(vm.rpcUrl("fuji"), 14_541_000);
        super.setUp();

        token10D = new ERC20MockDecimals(10);

        lbFactory.addQuoteAsset(token10D);

        vm.prank(factoryOwner);
        LBLegacyFactory.addQuoteAsset(token10D);
    }

    function test_revert_Constructor() public {
        vm.expectRevert(IJoeDexLens.JoeDexLens__ZeroAddress.selector);
        new JoeDexLens(ILBRouter(address(0)), ILBFactory(address(0)), ILBLegacyRouter(address(0)), ILBLegacyFactory(address(0)), IJoeFactory(address(0)), wNative, USDC);

        ILBRouter mockRouter =
            new LBRouter(ILBFactory(address(0)), joeFactory, LBLegacyFactory, LBLegacyRouter, IWAVAX(wNative));

        vm.expectRevert(IJoeDexLens.JoeDexLens__LBV2_1AddressMismatch.selector);
        joeDexLens = new JoeDexLens(mockRouter, lbFactory, LBLegacyRouter, LBLegacyFactory, joeFactory, wNative, USDC);

        mockRouter = new LBRouter(lbFactory, IJoeFactory(address(0)), LBLegacyFactory, LBLegacyRouter, IWAVAX(wNative));

        vm.expectRevert(IJoeDexLens.JoeDexLens__JoeV1AddressMismatch.selector);
        joeDexLens = new JoeDexLens(mockRouter, lbFactory, LBLegacyRouter, LBLegacyFactory, joeFactory, wNative, USDC);

        mockRouter = new LBRouter(lbFactory, joeFactory, ILBLegacyFactory(address(0)), LBLegacyRouter, IWAVAX(wNative));

        vm.expectRevert(IJoeDexLens.JoeDexLens__LBV2AddressMismatch.selector);
        joeDexLens = new JoeDexLens(mockRouter, lbFactory, LBLegacyRouter, LBLegacyFactory, joeFactory, wNative, USDC);

        mockRouter = new LBRouter(lbFactory, joeFactory, LBLegacyFactory, ILBLegacyRouter(address(0)), IWAVAX(wNative));

        vm.expectRevert(IJoeDexLens.JoeDexLens__LBV2AddressMismatch.selector);
        joeDexLens = new JoeDexLens(mockRouter, lbFactory, LBLegacyRouter, LBLegacyFactory, joeFactory, wNative, USDC);

        mockRouter = new LBRouter(lbFactory, joeFactory, LBLegacyFactory, LBLegacyRouter, IWAVAX(address(0)));

        vm.expectRevert(IJoeDexLens.JoeDexLens__WNativeMismatch.selector);
        joeDexLens = new JoeDexLens(mockRouter, lbFactory, LBLegacyRouter, LBLegacyFactory, joeFactory, wNative, USDC);

        vm.expectRevert(IJoeDexLens.JoeDexLens__LBV2_1AddressMismatch.selector);
        joeDexLens =
            new JoeDexLens(ILBRouter(address(0)), lbFactory, LBLegacyRouter, LBLegacyFactory, joeFactory, wNative, USDC);

        vm.expectRevert(IJoeDexLens.JoeDexLens__LBV2_1AddressMismatch.selector);
        joeDexLens =
            new JoeDexLens(lbRouter, ILBFactory(address(0)), LBLegacyRouter, LBLegacyFactory, joeFactory, wNative, USDC);

        vm.expectRevert(IJoeDexLens.JoeDexLens__LBV2AddressMismatch.selector);
        joeDexLens =
            new JoeDexLens(lbRouter, lbFactory, ILBLegacyRouter(address(0)), LBLegacyFactory, joeFactory, wNative, USDC);

        vm.expectRevert();
        joeDexLens =
            new JoeDexLens(lbRouter, lbFactory, ILBLegacyRouter(address(1)), LBLegacyFactory, joeFactory, wNative, USDC);

        vm.expectRevert();
        joeDexLens =
            new JoeDexLens(lbRouter, lbFactory, LBLegacyRouter, ILBLegacyFactory(address(0)), joeFactory, wNative, USDC);

        vm.expectRevert();
        joeDexLens =
            new JoeDexLens(lbRouter, lbFactory, LBLegacyRouter, ILBLegacyFactory(address(1)), joeFactory, wNative, USDC);

        vm.expectRevert();
        joeDexLens =
            new JoeDexLens(lbRouter, lbFactory, LBLegacyRouter, LBLegacyFactory, IJoeFactory(address(1)), wNative, USDC);

        vm.expectRevert(IJoeDexLens.JoeDexLens__ZeroAddress.selector);
        joeDexLens =
        new JoeDexLens(ILBRouter(address(0)), ILBFactory(address(0)), LBLegacyRouter, LBLegacyFactory, joeFactory, address(0), USDC);

        vm.expectRevert(IJoeDexLens.JoeDexLens__ZeroAddress.selector);
        joeDexLens =
        new JoeDexLens(ILBRouter(address(0)), ILBFactory(address(0)), LBLegacyRouter, LBLegacyFactory, joeFactory, wNative, address(0));
    }

    function test_AddressZero() public {
        new JoeDexLens(ILBRouter(address(0)), ILBFactory(address(0)), LBLegacyRouter, LBLegacyFactory, joeFactory, wNative, USDC);
        new JoeDexLens(lbRouter, lbFactory, ILBLegacyRouter(address(0)), ILBLegacyFactory(address(0)), joeFactory, wNative, USDC);
        new JoeDexLens(lbRouter, lbFactory, LBLegacyRouter, LBLegacyFactory, IJoeFactory(address(0)), wNative, USDC);

        new JoeDexLens(ILBRouter(address(0)), ILBFactory(address(0)), ILBLegacyRouter(address(0)), ILBLegacyFactory(address(0)), joeFactory, wNative, USDC);
        new JoeDexLens(lbRouter, lbFactory, ILBLegacyRouter(address(0)), ILBLegacyFactory(address(0)), IJoeFactory(address(0)), wNative, USDC);
    }

    function test_revert_AddDataFeedFromUnsetVersion() public {
        joeDexLens =
        new JoeDexLens(ILBRouter(address(0)), ILBFactory(address(0)), LBLegacyRouter, LBLegacyFactory, joeFactory, wNative, USDC);
        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(address(0), 1, IJoeDexLens.dfType.V2_1);

        vm.expectRevert(IJoeDexLens.JoeDexLens__V2_1ContractNotSet.selector);
        joeDexLens.addUSDDataFeed(wNative, df);

        vm.expectRevert(IJoeDexLens.JoeDexLens__V2_1ContractNotSet.selector);
        joeDexLens.addNativeDataFeed(USDC, df);

        joeDexLens =
        new JoeDexLens(lbRouter, lbFactory, ILBLegacyRouter(address(0)), ILBLegacyFactory(address(0)), joeFactory, wNative, USDC);
        df = IJoeDexLens.DataFeed(address(0), 1, IJoeDexLens.dfType.V2);

        vm.expectRevert(IJoeDexLens.JoeDexLens__V2ContractNotSet.selector);
        joeDexLens.addUSDDataFeed(wNative, df);

        vm.expectRevert(IJoeDexLens.JoeDexLens__V2ContractNotSet.selector);
        joeDexLens.addNativeDataFeed(USDC, df);

        joeDexLens =
            new JoeDexLens(lbRouter, lbFactory, LBLegacyRouter, LBLegacyFactory, IJoeFactory(address(0)), wNative, USDC);
        df = IJoeDexLens.DataFeed(address(0), 1, IJoeDexLens.dfType.V1);

        vm.expectRevert(IJoeDexLens.JoeDexLens__V1ContractNotSet.selector);
        joeDexLens.addUSDDataFeed(wNative, df);

        vm.expectRevert(IJoeDexLens.JoeDexLens__V1ContractNotSet.selector);
        joeDexLens.addNativeDataFeed(USDC, df);
    }

    function test_GetPriceFromV2_1WithV2Zero() public {
        joeDexLens =
        new JoeDexLens(lbRouter, lbFactory, ILBLegacyRouter(address(0)), ILBLegacyFactory(address(0)), joeFactory, wNative, USDC);

        createPairAndAddToUSDDataFeeds(USDC, address(token10D), ID_ONE + SHIFT_ID_ONE_1e4, IJoeDexLens.dfType.V2_1);

        uint256 priceT10D = joeDexLens.getTokenPriceUSD(address(token10D));

        // uint256(DEFAULT_BIN_STEP) * 1e14 = 0.2%
        assertApproxEqRel(priceT10D, 1e6, uint256(DEFAULT_BIN_STEP) * 1e14);
    }

    function test_GetPriceFromV2_1WithV1Zero() public {
        joeDexLens =
            new JoeDexLens(lbRouter, lbFactory, LBLegacyRouter, LBLegacyFactory, IJoeFactory(address(0)), wNative, USDC);

        createPairAndAddToUSDDataFeeds(USDC, address(token10D), ID_ONE + SHIFT_ID_ONE_1e4, IJoeDexLens.dfType.V2_1);

        uint256 priceT10D = joeDexLens.getTokenPriceUSD(address(token10D));

        // uint256(DEFAULT_BIN_STEP) * 1e14 = 0.2%
        assertApproxEqRel(priceT10D, 1e6, uint256(DEFAULT_BIN_STEP) * 1e14);
    }

    function test_GetPriceFromV2_1WithV1AndV2Zero() public {
        joeDexLens =
        new JoeDexLens(lbRouter, lbFactory, ILBLegacyRouter(address(0)), ILBLegacyFactory(address(0)), IJoeFactory(address(0)), wNative, USDC);

        createPairAndAddToUSDDataFeeds(USDC, address(token10D), ID_ONE + SHIFT_ID_ONE_1e4, IJoeDexLens.dfType.V2_1);

        uint256 priceT10D = joeDexLens.getTokenPriceUSD(address(token10D));

        // uint256(DEFAULT_BIN_STEP) * 1e14 = 0.2%
        assertApproxEqRel(priceT10D, 1e6, uint256(DEFAULT_BIN_STEP) * 1e14);
    }

    function test_GetPriceFromV2WithV2_1Zero() public {
        joeDexLens =
        new JoeDexLens(ILBRouter(address(0)), ILBFactory(address(0)), LBLegacyRouter, LBLegacyFactory, joeFactory, wNative, USDC);

        createPairAndAddToUSDDataFeeds(USDC, address(token10D), ID_ONE + SHIFT_ID_ONE_1e4, IJoeDexLens.dfType.V2);

        uint256 priceT10D = joeDexLens.getTokenPriceUSD(address(token10D));

        // uint256(DEFAULT_BIN_STEP) * 1e14 = 0.2%
        assertApproxEqRel(priceT10D, 1e6, uint256(DEFAULT_BIN_STEP) * 1e14);
    }

    function test_GetPriceFromV2WithV1Zero() public {
        joeDexLens =
            new JoeDexLens(lbRouter, lbFactory, LBLegacyRouter, LBLegacyFactory, IJoeFactory(address(0)), wNative, USDC);

        createPairAndAddToUSDDataFeeds(USDC, address(token10D), ID_ONE + SHIFT_ID_ONE_1e4, IJoeDexLens.dfType.V2);

        uint256 priceT10D = joeDexLens.getTokenPriceUSD(address(token10D));

        // uint256(DEFAULT_BIN_STEP) * 1e14 = 0.2%
        assertApproxEqRel(priceT10D, 1e6, uint256(DEFAULT_BIN_STEP) * 1e14);
    }

    function test_GetPriceFromV2WithV1AndV2_1Zero() public {
        joeDexLens =
        new JoeDexLens(ILBRouter(address(0)), ILBFactory(address(0)), LBLegacyRouter, LBLegacyFactory, IJoeFactory(address(0)), wNative, USDC);

        createPairAndAddToUSDDataFeeds(USDC, address(token10D), ID_ONE + SHIFT_ID_ONE_1e4, IJoeDexLens.dfType.V2);

        uint256 priceT10D = joeDexLens.getTokenPriceUSD(address(token10D));

        // uint256(DEFAULT_BIN_STEP) * 1e14 = 0.2%
        assertApproxEqRel(priceT10D, 1e6, uint256(DEFAULT_BIN_STEP) * 1e14);
    }

    function test_GetPriceFromV1WithV2_1Zero() public {
        joeDexLens =
        new JoeDexLens(ILBRouter(address(0)), ILBFactory(address(0)), LBLegacyRouter, LBLegacyFactory, joeFactory, wNative, USDC);

        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(NativeUSDCv1, 1, IJoeDexLens.dfType.V1);
        joeDexLens.addUSDDataFeed(wNative, df);

        uint256 priceNative = joeDexLens.getTokenPriceUSD(wNative);

        assertEq(priceNative, 20e6);
    }

    function test_GetPriceFromV1WithV2Zero() public {
        joeDexLens =
        new JoeDexLens(lbRouter, lbFactory, ILBLegacyRouter(address(0)), ILBLegacyFactory(address(0)), joeFactory, wNative, USDC);

        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(NativeUSDCv1, 1, IJoeDexLens.dfType.V1);
        joeDexLens.addUSDDataFeed(wNative, df);

        uint256 priceNative = joeDexLens.getTokenPriceUSD(wNative);

        assertEq(priceNative, 20e6);
    }

    function test_GetPriceFromV1WithV2AndV2_1Zero() public {
        joeDexLens =
        new JoeDexLens(ILBRouter(address(0)), ILBFactory(address(0)), ILBLegacyRouter(address(0)), ILBLegacyFactory(address(0)), joeFactory, wNative, USDC);

        IJoeDexLens.DataFeed memory df = IJoeDexLens.DataFeed(NativeUSDCv1, 1, IJoeDexLens.dfType.V1);
        joeDexLens.addUSDDataFeed(wNative, df);

        uint256 priceNative = joeDexLens.getTokenPriceUSD(wNative);

        assertEq(priceNative, 20e6);
    }
}
