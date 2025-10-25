// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@contracts/adapters/AaveAdapter.sol";

contract AaveAdapterTest is Test {
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address user1 = address(0xb6744022C84e96bB4A8304D3BA2474AE9266CfDc);

    AaveAdapter public aaveAdapter;

    IERC20 public asset;

    function setUp() public {
        string memory RPC_URL = vm.envString("RPC_URL_ETH");

        vm.createSelectFork(RPC_URL, 20000000);

        asset = IERC20(DAI);

        deal(address(asset), user1, 10000e6);

        aaveAdapter = new AaveAdapter(user1, AAVE_POOL);

        vm.label(user1, "User1");
        vm.label(address(aaveAdapter), "AaveAdapter");
    }

    function testGetAPR() public view {
        console2.log("Aave USDT APR", aaveAdapter.getAPR(USDT) / 1e16);
        console2.log("Aave USDT APY", aaveAdapter.getAPY(USDT) / 1e16);
        console2.log("Aave USDC APR", aaveAdapter.getAPR(USDC) / 1e16);
        console2.log("Aave USDC APY", aaveAdapter.getAPY(USDC) / 1e16);
    }

    function testDepositOnAave() public {
        vm.startPrank(user1);

        uint256 depositAmount = 1000e6;
        asset.approve(address(aaveAdapter), depositAmount);
        aaveAdapter.deposit(address(asset), depositAmount);

        vm.stopPrank();
    }

    function testWithdrawOnAave() public {
        testDepositOnAave();

        vm.startPrank(user1);

        uint256 withdrawAmount = 500e6;
        aaveAdapter.withdraw(address(asset), withdrawAmount);

        vm.stopPrank();
    }
}
