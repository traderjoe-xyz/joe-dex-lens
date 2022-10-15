// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "src/JoeDexLens.sol";
import "src/interfaces/ILBRouter.sol";
import "src/interfaces/IJoeRouter02.sol";
import "openzeppelin/token/ERC20/IERC20.sol";

import "src/interfaces/ITestnetERC20.sol";

abstract contract TestHelper is Test {
    using Math512Bits for uint256;
    address payable internal constant DEV = payable(0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
    //address public TokenOwner = 0x4f029B3faA0fE6405Ae6eBA5795293688cf69c2e; // before transfer to bad multisig
    address public TokenOwner = 0xFFC08538077a0455E0F4077823b1A0E3e18Faf0b;
    address public LBFactory = 0x2950b9bd19152C91d69227364747b3e6EFC8Ab7F;
    address public LBRouter = 0x0C344c52841d3F8d488E1CcDBafB42CE2C7fdFA9;
    address public LBQuoter = 0x0C926BF1E71725eD68AE3041775e9Ba29142dca9;
    address public FactoryV1 = 0xF5c7d9733e5f53abCC1695820c4818C59B457C2C;
    address public RouterV1 = 0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901;

    address public USDT = 0xAb231A5744C8E6c45481754928cCfFFFD4aa0732;
    address public USDC = 0xB6076C93701D6a07266c31066B298AeC6dd65c2d;
    address public WAVAX = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;

    address public USDCUSDTv1 = 0x8625feb95141008FE48ea5cf8A7dd84A83a72d9E;
    address public AVAXUSDCv1 = 0x9371619C8E2A487D57FB9F8E36Bcb0317Bff0529;

    address public USDCUSDT1bps = 0x0716FBE78331932d0Fd9A284b22F0342a6FD8ee8;
    address public AVAXUSDC10bps = 0x1579647e8cc2338111e131A01AF62d85870A659b;
    address public AVAXUSDC20bps = 0xc8aa3bF8623C35EAc518Ea82B55C2aa46D5A02f6;

    JoeDexLens public lens;
}
