// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAdapter {
    function router() external returns (address);

    function deposit(address asset, uint256 amount) external returns (uint256);

    function withdraw(address asset, uint256 amount) external returns (uint256);

    function getProfit(uint256 amount, uint256 wrapperAmount) external returns (uint256);

    function getAPR(address asset) external returns (uint256);

    function getAPY(address asset) external returns (uint256);

    event Deposit(address indexed user, address indexed asset, uint256 amount);

    event Withdraw(address indexed user, address indexed asset, uint256 amount);
}
