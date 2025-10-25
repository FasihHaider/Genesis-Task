// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@contracts/adapters/CompoundAdapter.sol";

contract CompoundAdapterTest is Test {
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address user1 = address(0xb6744022C84e96bB4A8304D3BA2474AE9266CfDc);

    CompoundAdapter public compoundAdapter;

    IERC20 public asset;

    function setUp() public {
        string memory RPC_URL = vm.envString("RPC_URL_ETH");

        vm.createSelectFork(RPC_URL);

        asset = IERC20(USDC);

        deal(address(asset), user1, 10000e6);

        compoundAdapter = new CompoundAdapter(user1);

        vm.label(user1, "User1");
        vm.label(address(compoundAdapter), "CompoundAdapter");
    }

    function testGetAPR() public {
        console2.log("Compound USDT APR", compoundAdapter.getAPR(USDT) / 1e16);
        console2.log("Compound USDT APY", compoundAdapter.getAPY(USDT) / 1e16);
        console2.log("Compound USDC APR", compoundAdapter.getAPR(USDC) / 1e16);
        console2.log("Compound USDC APY", compoundAdapter.getAPY(USDC) / 1e16);
    }

    // function testDepositOnCompound() public {
    //     vm.startPrank(user1);

    //     uint256 depositAmount = 1000e6;
    //     asset.approve(address(compoundAdapter), depositAmount);
    //     compoundAdapter.deposit(address(asset), depositAmount);

    //     vm.stopPrank();
    // }

    // function testWithdrawOnCompound() public {
    //     vm.startPrank(user1);

    //     uint256 depositAmount = 1000e6;
    //     asset.approve(address(compoundAdapter), depositAmount);
    //     compoundAdapter.deposit(address(asset), depositAmount);

    //     uint256 withdrawAmount = 500e6;
    //     compoundAdapter.withdraw(address(asset), withdrawAmount);

    //     vm.stopPrank();
    // }
}
