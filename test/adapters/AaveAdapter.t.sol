// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@contracts/interfaces/IAavePool.sol";
import "@contracts/adapters/AaveAdapter.sol";

contract AaveAdapterTest is Test {

    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address user1 = address(0xb6744022C84e96bB4A8304D3BA2474AE9266CfDc);
    
    AaveAdapter public aaveAdapter;
    
    IERC20 public dai;

    function setUp() public {
        string memory RPC_URL = vm.envString("RPC_URL_ETH");
        
        vm.createSelectFork(RPC_URL, 19500000);

        dai = IERC20(DAI);

        deal(DAI, user1, 10000e6);

        aaveAdapter = new AaveAdapter(address(0), AAVE_POOL);
        deal(DAI, user1, 10000e6);

        vm.label(user1, "User1");
        vm.label(address(aaveAdapter), "AaveAdapter");
    }

    function testDepositOnAave() public {
        vm.startPrank(user1);
                
        uint256 depositAmount = 1000e6;
        dai.approve(address(aaveAdapter), depositAmount);
        aaveAdapter.deposit(DAI, depositAmount);

        vm.stopPrank();
    }

    function testWithdrawOnAave() public {
        testDepositOnAave();

        vm.startPrank(user1);

        uint256 withdrawAmount = 500e6;
        aaveAdapter.withdraw(DAI, withdrawAmount);

        vm.stopPrank();
    }

}
