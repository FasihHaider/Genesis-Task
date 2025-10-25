// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICToken {
    function supply(address asset, uint256 amount) external;
    function withdraw(address asset, uint256 amount) external;
    function getUtilization() external returns (uint256);
    function getSupplyRate(uint256 utilization) external returns (uint256);
}
