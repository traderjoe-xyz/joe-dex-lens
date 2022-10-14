// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ILBPair.sol";

interface ILBRouter {
    function getPriceFromId(ILBPair LBPair, uint24 id) external view returns (uint256);
}
