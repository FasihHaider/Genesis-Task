// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IComptroller {
    function getAllMarkets() external view returns (address[] memory);
}
