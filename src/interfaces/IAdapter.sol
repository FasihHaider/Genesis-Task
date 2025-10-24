// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAdapter {
    function router() external returns (address);

    function deposit(address asset, uint256 amount) external;

    function withdraw(address asset, uint256 amount) external returns (uint256);

    function getAPY(address asset) external view returns (uint256);

    event Deposited(address indexed user, address indexed asset, uint256 amount);

    event Withdrawn(address indexed user, address indexed asset, uint256 amount);
}
