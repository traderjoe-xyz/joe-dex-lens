// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "joe-v2/interfaces/ILBRouter.sol";
import "joe-v2/interfaces/IJoeFactory.sol";
import "joe-v2/interfaces/IPendingOwnable.sol";

import "../JoeDexLensErrors.sol";
import "../interfaces/AggregatorV3Interface.sol";

/// @title Interface of the Joe Dex Lens contract
/// @author Trader Joe
/// @notice The interface needed to interract with the Joe Dex Lens contract
interface IJoeDexLens is IPendingOwnable {
    /// @notice Enumerators of the different data feed types
    enum dfType {
        V1,
        V2,
        CHAINLINK
    }

    /// @notice Structure for data feeds, contains the data feed's address and its type
    struct DataFeed {
        address dfAddress;
        uint88 dfWeight;
        dfType dfType;
    }

    struct DataFeedSet {
        DataFeed[] dataFeeds;
        mapping(address => uint256) indexes;
    }

    event DataFeedAdded(address collateral, address token, DataFeed dataFeed);

    event DataFeedsWeightset(address collateral, address token, address dfAddress, uint256 weight);

    event DataFeedRemoved(address collateral, address token, address dfAddress);

    function getRouterV2() external view returns (ILBRouter routerV2);

    function getFactoryV1() external view returns (IJoeFactory factoryV1);

    function getUSDDataFeeds(address token) external view returns (DataFeed[] memory dataFeeds);

    function getNativeDataFeeds(address token) external view returns (DataFeed[] memory dataFeeds);

    function getTokenPriceUSD(address token) external view returns (uint256 price);

    function getTokenPriceNative(address token) external view returns (uint256 price);

    function getTokensPricesUSD(address[] calldata tokens) external view returns (uint256[] memory prices);

    function getTokensPricesNative(address[] calldata tokens) external view returns (uint256[] memory prices);

    function addUSDDataFeed(address token, DataFeed calldata dataFeed) external;

    function addNativeDataFeed(address token, DataFeed calldata dataFeed) external;

    function setUSDDataFeedWeight(
        address token,
        address dfAddress,
        uint88 newWeight
    ) external;

    function setNativeDataFeedWeight(
        address token,
        address dfAddress,
        uint88 newWeight
    ) external;

    function removeUSDDataFeed(address token, address dfAddress) external;

    function removeNativeDataFeed(address token, address dfAddress) external;

    function addUSDDataFeeds(address[] calldata tokens, DataFeed[] calldata dataFeeds) external;

    function addNativeDataFeeds(address[] calldata tokens, DataFeed[] calldata dataFeeds) external;

    function setUSDDataFeedsWeights(
        address[] calldata _tokens,
        address[] calldata _dfAddresses,
        uint88[] calldata _newWeights
    ) external;

    function setNativeDataFeedsWeights(
        address[] calldata _tokens,
        address[] calldata _dfAddresses,
        uint88[] calldata _newWeights
    ) external;

    function removeUSDDataFeeds(address[] calldata tokens, address[] calldata dfAddresses) external;

    function removeNativeDataFeeds(address[] calldata tokens, address[] calldata dfAddresses) external;
}
