// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "openzeppelin/token/ERC20/IERC20.sol";

interface ITestnetERC20 is IERC20 {
    function mint(address _to, uint256 _amount) external;
}
