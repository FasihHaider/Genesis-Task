// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAdapter {
    function router() external returns (address);

    function deposit(address asset, uint256 amount) external;

    function withdraw(address asset, uint256 amount) external;
}
