// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@contracts/YieldRouter.sol";
import "@contracts/adapters/AaveAdapter.sol";

contract YieldRouterTest is Test {

    // ===== Constants =====
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI on mainnet
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2; // Aave V3 mainnet Pool
    address user1 = address(0xb6744022C84e96bB4A8304D3BA2474AE9266CfDc);
    
    YieldRouter public router;
    AaveAdapter public aaveAdapter;

    IERC20 public dai;

    function setUp() public {
        string memory RPC_URL = vm.envString("RPC_URL_ETH");
        
        vm.createSelectFork(RPC_URL, 19500000);

        dai = IERC20(DAI);

        deal(DAI, user1, 10000e6);

        router = new YieldRouter();
        aaveAdapter = new AaveAdapter(address(router), AAVE_POOL);
        router.addAdapter(address(aaveAdapter));
        deal(DAI, user1, 10000e6);

        vm.label(user1, "User1");
        vm.label(address(router), "YieldRouter");
    }

    function testDepositOnAave() public {
        vm.startPrank(user1);
        
        
        uint256 depositAmount = 1000e6; // 1000 DAI
        dai.approve(address(router), depositAmount);

        router.deposit(DAI, depositAmount);

        (, address asset, uint256 storedAmount) = router.userDeposits(user1);
        assertEq(asset, DAI);
        assertEq(storedAmount, depositAmount);

        vm.stopPrank();
    }

}
