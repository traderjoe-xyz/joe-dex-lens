// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ILBPair.sol";

interface ILBRouter {
    function getPriceFromId(ILBPair LBPair, uint24 id) external view returns (uint256);

    function createLBPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint24 activeId,
        uint16 binStep
    ) external returns (ILBPair pair);
}
