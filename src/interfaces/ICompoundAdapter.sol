// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICompoundAdapter {
    function addCToken(address asset, address cAsset) external;
}
