// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICToken {
    function mint(uint256 mintAmount) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function supplyRatePerBlock() external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function underlying() external view returns (address);
}
