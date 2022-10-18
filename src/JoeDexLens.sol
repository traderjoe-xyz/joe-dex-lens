// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "joe-v2/libraries/Math512Bits.sol";
import "joe-v2/interfaces/ILBRouter.sol";
import "joe-v2/interfaces/ILBPair.sol";
import "joe-v2/interfaces/IJoePair.sol";
import "joe-v2/interfaces/IJoeFactory.sol";
import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/access/Ownable.sol";

import "./interfaces/AggregatorV3Interface.sol";

error JoeDexLens__PairsNotCreated();
error JoeDexLens__MarketDoesNotExist();
error JoeDexLens__MarketAlreadyExists(address pairAddress);
error JoeDexLens__NoUSDMarketDefined();
error JoeDexLens__AddressZero();
error JoeDexLens__WrongPair();

/**
 * @notice TODO natspec
 */
contract JoeDexLens is Ownable {
    uint256 PRECISION = 1e18;

    ILBRouter V2Router;
    IJoeFactory V1Factory;
    address WAVAX;
    address USDC;

    /// @notice TODO
    enum MarketType {
        V1,
        V2,
        CHAINLINK
    }

    /// @notice TODO
    struct Market {
        address pairAddress;
        MarketType marketType;
    }

    event AggregatorUpdated(address tokenAddress, address source);

    event USDMarketAdded(address tokenAddress, Market market);

    event AVAXMarketAdded(address tokenAddress, Market market);

    event USDMarketRemoved(address tokenAddress, Market market);

    event AVAXMarketRemoved(address tokenAddress, Market market);

    /// @notice Mapping from token address to Chainlink aggregator
    mapping(address => AggregatorV3Interface) public aggregators;

    /// @notice Mapping from token address to markets, that are used to calculate this token's price in USD
    mapping(address => Market[]) private _whitelistedUSDPairs;

    /// @notice Mapping from token address to markets, that are used to calculate this token's price in USD
    mapping(address => Market[]) private _whitelistedAVAXPairs;

    /** Constructor **/

    constructor(
        address _V2router,
        address _V1Factory,
        address _WAVAX,
        address _USDC
    ) {
        V2Router = ILBRouter(_V2router);
        V1Factory = IJoeFactory(_V1Factory);
        WAVAX = _WAVAX;
        USDC = _USDC;
    }

    /** External View Functions **/

    /// @notice Returns list of markets used to calculate price of token in USD
    /// TODO
    function getUSDMarkets(address token) external view returns (Market[] memory) {
        return _whitelistedUSDPairs[token];
    }

    /// @notice Returns list of markets used to calculate price of token in AVAX
    /// TODO
    function getAVAXMarkets(address token) external view returns (Market[] memory) {
        return _whitelistedAVAXPairs[token];
    }

    /// @notice Returns price of token in USD, scaled by PRECISION, calculated based on _whitelistedUSDPairs and weighted by token reserves in these markets
    /// TODO
    function getTokenPriceUSD(address token) external view returns (uint256) {
        Market[] memory markets = _whitelistedUSDPairs[token];
        if (markets.length == 0) revert JoeDexLens__NoUSDMarketDefined();
        uint256[] memory allPrices = new uint256[](markets.length);

        for (uint256 i; i < markets.length; i++) {
            if (markets[i].marketType == MarketType.V1) {
                allPrices[i] = _getPriceFromV1(markets[i].pairAddress, token);
            } else if (markets[i].marketType == MarketType.V2) {
                allPrices[i] = _getPriceFromV2(markets[i].pairAddress, token);
            } else if (markets[i].marketType == MarketType.CHAINLINK) {
                allPrices[i] = _getPriceFromChainlink(token);
            }
        }
        return _calculateWeightedUSDAverage(allPrices, markets);
    }

    /// @notice Returns price of token in AVAX, scaled by PRECISION, calculated based on _whitelistedAVAXPairs and weighted by token reserves in these markets
    /// TODO
    function getTokenPriceAVAX(address token) external view returns (uint256) {
        Market[] memory markets = _whitelistedAVAXPairs[token];
        if (markets.length == 0) {
            return _getPriceInAVAXAnyToken(token);
        }

        uint256[] memory allPrices = new uint256[](markets.length);
        for (uint256 i; i < markets.length; i++) {
            if (markets[i].marketType == MarketType.V1) {
                allPrices[i] = _getPriceFromV1(markets[i].pairAddress, token);
            } else if (markets[i].marketType == MarketType.V2) {
                allPrices[i] = _getPriceFromV2(markets[i].pairAddress, token);
            } else if (markets[i].marketType == MarketType.CHAINLINK) {
                allPrices[i] = _getPriceFromChainlink(token);
            }
        }
        return _calculateWeightedAVAXAverage(allPrices, markets);
    }

    /** External Functions **/

    /// @notice add Chainlink aggregators
    /// TODO
    function setAggregators(address[] calldata tokenAddresses, address[] calldata sources) external onlyOwner {
        require(tokenAddresses.length == sources.length, "mismatched data");

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            aggregators[tokenAddresses[i]] = AggregatorV3Interface(sources[i]);
            emit AggregatorUpdated(tokenAddresses[i], sources[i]);
        }
    }

    /// @notice add USD markets. Pairs have to include USDC
    /// TODO
    function addUSDMarkets(Market[] calldata markets) external onlyOwner {
        address token;
        for (uint256 i; i < markets.length; i++) {
            if (markets[i].marketType == MarketType.V1) {
                IJoePair pair = IJoePair(markets[i].pairAddress);
                address token0 = pair.token0();
                address token1 = pair.token1();
                if (token0 != USDC && token1 != USDC) {
                    revert JoeDexLens__WrongPair();
                }
                token = token0 == USDC ? token1 : token0;
            } else if (markets[i].marketType == MarketType.V2) {
                ILBPair pair = ILBPair(markets[i].pairAddress);
                address tokenX = address(pair.tokenX());
                address tokenY = address(pair.tokenY());
                if (tokenX != USDC && tokenY != USDC) {
                    revert JoeDexLens__WrongPair();
                }
                token = tokenX == USDC ? tokenY : tokenX;
            }

            for (uint j; j < _whitelistedUSDPairs[token].length; j++) {
                if (_whitelistedUSDPairs[token][j].pairAddress == markets[i].pairAddress)
                    revert JoeDexLens__MarketAlreadyExists(markets[i].pairAddress);
            }
            _whitelistedUSDPairs[token].push(markets[i]);
            emit USDMarketAdded(token, markets[i]);
        }
    }

    /// @notice add AVAX markets. Pairs have to include AVAX
    /// TODO
    function addAVAXMarkets(Market[] calldata markets) external onlyOwner {
        address token;
        for (uint256 i = 0; i < markets.length; i++) {
            for (uint j; j < _whitelistedAVAXPairs[token].length; j++) {
                if (_whitelistedAVAXPairs[token][j].pairAddress == markets[i].pairAddress)
                    revert JoeDexLens__MarketAlreadyExists(markets[i].pairAddress);
            }
            if (markets[i].marketType == MarketType.V1) {
                IJoePair pair = IJoePair(markets[i].pairAddress);
                address token0 = pair.token0();
                address token1 = pair.token1();
                if (token0 != WAVAX && token1 != WAVAX) {
                    revert JoeDexLens__WrongPair();
                }
                token = token0 == WAVAX ? token1 : token0;
            } else if (markets[i].marketType == MarketType.V2) {
                ILBPair pair = ILBPair(markets[i].pairAddress);
                address tokenX = address(pair.tokenX());
                address tokenY = address(pair.tokenY());
                if (tokenX != WAVAX && tokenY != WAVAX) {
                    revert JoeDexLens__WrongPair();
                }
                token = tokenX == WAVAX ? tokenY : tokenX;
            }
            _whitelistedAVAXPairs[token].push(markets[i]);
            emit AVAXMarketAdded(token, markets[i]);
        }
    }

    /// @notice remove existing USD market for given token
    /// TODO
    function removeUSDMarket(address token, Market calldata market) external onlyOwner {
        for (uint256 i; i < _whitelistedUSDPairs[token].length; i++) {
            if (_whitelistedUSDPairs[token][i].pairAddress == market.pairAddress) {
                _whitelistedUSDPairs[token][i] = _whitelistedUSDPairs[token][_whitelistedUSDPairs[token].length - 1];
                _whitelistedUSDPairs[token].pop();
                emit USDMarketRemoved(token, market);
                return;
            }
        }
        revert JoeDexLens__MarketDoesNotExist();
    }

    /// @notice remove existing AVAX market for given token
    /// TODO
    function removeAVAXMarket(address token, Market calldata market) external onlyOwner {
        for (uint256 j; j < _whitelistedAVAXPairs[token].length; j++) {
            if (_whitelistedAVAXPairs[token][j].pairAddress == market.pairAddress) {
                _whitelistedAVAXPairs[token][j] = _whitelistedAVAXPairs[token][_whitelistedAVAXPairs[token].length - 1];
                _whitelistedAVAXPairs[token].pop();
                emit AVAXMarketRemoved(token, market);
                return;
            }
        }
        revert JoeDexLens__MarketDoesNotExist();
    }

    /** Internal Functions **/

    /// @notice Get price from ChainLink
    /// @param token token to get the price of
    /// @return The price with 18 decimals
    function _getPriceFromChainlink(address token) internal view returns (uint256) {
        AggregatorV3Interface aggregator = aggregators[token];
        (, int256 price, , , ) = aggregator.latestRoundData();
        require(price > 0, "invalid price");

        // Extend the decimals to 1e18.
        return uint256(price) * 10**(18 - uint256(aggregator.decimals()));
    }

    /// @notice TODO natspec
    /// @return price of token scaled by PRECISION denominated in other token from pairAddress
    function _getPriceFromV1(address pairAddress, address token) internal view returns (uint256) {
        IJoePair pair = IJoePair(pairAddress);
        address token0 = pair.token0();
        address token1 = pair.token1();
        uint256 decimals0 = ERC20(token0).decimals();
        uint256 decimals1 = ERC20(token1).decimals();
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        if (token == token0) {
            return (PRECISION * reserve1 * 10**decimals0) / (reserve0 * 10**decimals1);
        } else if (token == token1) {
            return (PRECISION * reserve0 * 10**decimals1) / (reserve1 * 10**decimals0);
        }
    }

    /// @notice TODO natspec
    /// @return price of token scaled by PRECISION denominated in other token from pairAddress
    function _getPriceFromV2(address pairAddress, address token) internal view returns (uint256) {
        uint256 bitShift = 128;
        ILBPair pair = ILBPair(pairAddress);
        (, , uint256 activeID) = pair.getReservesAndId();
        uint256 priceScaled = V2Router.getPriceFromId(pair, uint24(activeID));

        if (token == address(pair.tokenX())) {
            return (priceScaled * PRECISION) >> bitShift;
        } else if (token == address(pair.tokenY())) {
            return ((type(uint256).max / priceScaled) * PRECISION) >> bitShift;
        }
    }

    /// @notice TODO natspec
    /// @return token price in AVAX scaled by PRECISION as average from AVAX-token&USDC-token
    /// weighted by reserves from Joe V1, when no markets added for given token
    function _getPriceInAVAXAnyToken(address token) internal view returns (uint256) {
        uint256 AVAXPriceInUSD = _getPriceFromChainlink(WAVAX);
        address pairWavax = V1Factory.getPair(token, WAVAX);
        address pairUSDC = V1Factory.getPair(token, USDC);
        uint256 priceInUSDC;
        uint256 priceInAVAX;

        if (pairWavax == address(0) && pairUSDC == address(0)) {
            revert JoeDexLens__PairsNotCreated();
        } else if (pairWavax == address(0)) {
            priceInUSDC = _getPriceFromV1(pairUSDC, token);
            return priceInUSDC / AVAXPriceInUSD;
        } else if (pairUSDC == address(0)) {
            return _getPriceFromV1(WAVAX, token);
        } else {
            priceInUSDC = _getPriceFromV1(pairUSDC, token);
            priceInAVAX = _getPriceFromV1(pairWavax, token);
            uint256 tokenReservesUSDCPair = _getReservesFromV1(pairUSDC, token);
            uint256 tokenReservesAVAXPair = _getReservesFromV1(pairWavax, token);
            uint256 sumTokenReserves = tokenReservesUSDCPair + tokenReservesAVAXPair;
            uint256 weightedAvg = (((tokenReservesUSDCPair * priceInUSDC) / AVAXPriceInUSD) +
                (tokenReservesAVAXPair * priceInAVAX)) / sumTokenReserves;
            return weightedAvg;
        }
    }

    /// @notice TODO natspec
    function _calculateWeightedUSDAverage(uint256[] memory allPrices, Market[] memory markets)
        internal
        view
        returns (uint256)
    {
        return _calculateWeightedAverage(allPrices, markets, USDC);
    }

    /// @notice TODO natspec
    function _calculateWeightedAVAXAverage(uint256[] memory allPrices, Market[] memory markets)
        internal
        view
        returns (uint256)
    {
        return _calculateWeightedAverage(allPrices, markets, WAVAX);
    }

    /// @notice Calculates weighted average based on reserves
    /// TODO
    function _calculateWeightedAverage(
        uint256[] memory allPrices,
        Market[] memory markets,
        address baseToken
    ) internal view returns (uint256) {
        uint256 weight;
        uint256 priceSum;
        uint256 weightSum;
        for (uint256 i; i < allPrices.length; i++) {
            if (markets[i].marketType == MarketType.V1) {
                weight = _getReservesFromV1(markets[i].pairAddress, baseToken);
            } else if (markets[i].marketType == MarketType.V2) {
                weight = _getReservesFromV2(markets[i].pairAddress, baseToken);
            }
            priceSum += allPrices[i] * weight;
            weightSum += weight;
        }

        return priceSum / weightSum;
    }

    /// @notice calculate underlying reserves denominated in baseToken (USDC/WAVAX) from Joe V1
    /// TODO
    function _getReservesFromV1(address pairAddress, address baseToken) internal view returns (uint256) {
        IJoePair pair = IJoePair(pairAddress);
        uint256 reserves;
        if (pair.token0() == baseToken) {
            (uint256 reserves0, , ) = pair.getReserves();
            reserves = reserves0 * 2;
        } else if (pair.token1() == baseToken) {
            (, uint256 reserves1, ) = pair.getReserves();

            reserves = reserves1 * 2;
        }
        return reserves;
    }

    /// @notice calculate underlying reserves denominated in baseToken (USDC/WAVAX) from Joe V2,
    /// including bins around active bin in binsRange
    /// TODO
    function _getReservesFromV2(address pairAddress, address baseToken) internal view returns (uint256) {
        uint256 binsRange = 5;
        uint256 liquidity;
        uint256 sumReserves;

        (, , uint256 activeId) = ILBPair(pairAddress).getReservesAndId();
        if (address(ILBPair(pairAddress).tokenY()) == baseToken) {
            for (uint i = activeId - binsRange; i < activeId + binsRange; i++) {
                liquidity = ILBToken(pairAddress).totalSupply(i);
                sumReserves += liquidity;
            }
        } else if (address(ILBPair(pairAddress).tokenX()) == baseToken) {
            for (uint256 i = activeId - binsRange; i < activeId + binsRange; i++) {
                liquidity = ILBToken(pairAddress).totalSupply(i);
                uint256 wavaxReserves = Math512Bits.mulShiftRoundDown(
                    type(uint256).max / V2Router.getPriceFromId(ILBPair(pairAddress), uint24(i)),
                    liquidity,
                    128
                );
                sumReserves += wavaxReserves;
            }
        }
        return sumReserves;
    }
}
