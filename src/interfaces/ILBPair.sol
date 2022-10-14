// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin/token/ERC20/IERC20.sol";

import "./ILBFactory.sol";

interface ILBPair {
    function tokenX() external view returns (IERC20);

    function tokenY() external view returns (IERC20);

    function factory() external view returns (ILBFactory);

    function getReservesAndId()
        external
        view
        returns (
            uint256 reserveX,
            uint256 reserveY,
            uint256 activeId
        );

    function swap(bool sentTokenY, address to) external returns (uint256 amountXOut, uint256 amountYOut);

    function getBin(uint24 id) external view returns (uint256 reserveX, uint256 reserveY);

    function totalSupply(uint256 id) external view returns (uint256);
}
