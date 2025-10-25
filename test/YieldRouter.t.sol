// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@contracts/YieldRouter.sol";
import "@contracts/adapters/AaveAdapter.sol";
import "@contracts/adapters/CompoundAdapter.sol";

contract YieldRouterTest is Test {
    // ===== Constants =====
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant COMPOUND_COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address user1 = address(0xb6744022C84e96bB4A8304D3BA2474AE9266CfDc);

    YieldRouter public router;
    AaveAdapter public aaveAdapter;
    CompoundAdapter public compoundAdapter;

    IERC20 public asset;

    function setUp() public {
        string memory RPC_URL = vm.envString("RPC_URL_ETH");

        vm.createSelectFork(RPC_URL, 19500000);

        asset = IERC20(USDC);

        router = new YieldRouter();
        aaveAdapter = new AaveAdapter(address(router), AAVE_POOL);
        compoundAdapter = new CompoundAdapter(address(router));
        router.addAdapter(address(aaveAdapter), "Aave");
        // router.addAdapter(address(compoundAdapter), "Compound");

        deal(address(asset), user1, 1000e6);

        vm.label(user1, "User1");
        vm.label(address(router), "YieldRouter");
    }

    function testDeposit() public {
        vm.startPrank(user1);

        uint256 depositAmount = 500e6;
        asset.approve(address(router), 1000e6);
        router.deposit(address(asset), depositAmount);
        // deposit again
        router.deposit(address(asset), depositAmount);

        (address adapter, address token, uint256 storedAmount) = router.userDeposits(user1);
        assertEq(token, address(asset));
        assertEq(storedAmount, depositAmount * 2);
        console2.log("Adapter", router.adapterNames(adapter));
        console2.log("Asset", token);
        console2.log("Amount", storedAmount);

        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(user1);

        uint256 depositAmount = 1000e6;
        asset.approve(address(router), depositAmount);
        router.deposit(address(asset), depositAmount);

        uint256 withdrawAmount = 1000e6;
        router.withdraw(address(asset), withdrawAmount);
        console2.log("User Balance", asset.balanceOf(user1));
        console2.log("Router Balance", asset.balanceOf(address(router)));

        vm.stopPrank();
    }
}
