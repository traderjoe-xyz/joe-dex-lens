// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "joe-v2/interfaces/ILBRouter.sol";

import "../src/JoeDexLens.sol";
import "./TestHelper.sol";

contract TestJoeDexLens_ is TestHelper {
    ERC20MockDecimals internal token18D;

    function setUp() public override {
        vm.createSelectFork(vm.rpcUrl("fuji"), 14884890);
        super.setUp();

        joeDexLens = new JoeDexLens(lbRouter, USDC);

        token18D = new ERC20MockDecimals(18);
    }

    function test_PriceWithoutDataFeeds_V1() public {
        vm.expectRevert(IJoeDexLens.JoeDexLens__PairsNotCreated.selector);
        joeDexLens.getTokenPriceUSD(address(1));

        uint256 priceUSD = joeDexLens.getTokenPriceNative(WETH);
        uint256 priceNative = joeDexLens.getTokenPriceUSD(WETH);

        assertApproxEqRel(priceUSD, 0.335e18, 3e16);
        assertApproxEqRel(priceNative, 6.68e18, 3e16);
    }

    function test_PriceWithoutDataFeeds_V2() public {
        LBLegacyRouter.createLBPair(token18D, IERC20(USDC), 1 << 23, DEFAULT_BIN_STEP);

        uint256 tokenPrice = joeDexLens.getTokenPriceUSD(address(token18D));

        console.log("tokenPrice: %s", tokenPrice);
    }

    function test_PriceWithoutDataFeeds_V2_1() public {
        lbRouter.createLBPair(token18D, IERC20(USDC), 1 << 23, DEFAULT_BIN_STEP * 2);

        uint256 tokenPrice = joeDexLens.getTokenPriceUSD(address(token18D));

        console.log("tokenPrice: %s", tokenPrice);
    }
}

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (IPair pair);
}

interface IPair {
    function mint(address to) external returns (uint256 liquidity);
}
