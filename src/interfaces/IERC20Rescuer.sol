// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20Rescuer {
    function rescueERC20(address token, address to, uint256 amount) external;
}
