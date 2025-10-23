// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@contracts/interfaces/IAavePool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AaveAdapter {
    
    IAavePool public pool;
    address public router;
    
    constructor(address _router, address _pool) {
        pool = IAavePool(_pool);
        router = _router;
    }

    function deposit(address asset, uint256 amount) external {
        require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "transfer failed");
        IERC20(asset).approve(address(pool), amount);
        pool.supply(asset, amount, address(this), 0);
    }

    function withdraw(address asset, uint256 amount) external {
        uint256 withdrawAmount = pool.withdraw(asset, amount, address(this));
        require(IERC20(asset).transfer(msg.sender, withdrawAmount), "Transfer failed");
    }

    /// @notice Calculate APY for an Aave asset (simplified version)
    /// @param asset The asset address
    /// @return apy APY as basis points (e.g., 523 = 5.23%)
    function calculateAPY(address asset) public view returns (uint256 apy) {
        // Get APR first
        uint256 apr = calculateAPR(asset);
        
        // Simple approximation: APY ≈ APR + (APR^2 / 20000)
        // This is accurate for small rates and avoids overflow
        if (apr > 0) {
            uint256 aprSquared = (apr * apr) / 10000; // Convert to proper scale
            apy = apr + (aprSquared / 20000);
        } else {
            apy = 0;
        }
    }
    
    /// @notice Calculate APR (simple interest) for comparison
    /// @param asset The asset address
    /// @return apr APR as basis points (e.g., 500 = 5.00%)
    function calculateAPR(address asset) public view returns (uint256 apr) {
        IAavePool.ReserveData memory data = pool.getReserveData(asset);
        uint256 liquidityRate = uint256(data.currentLiquidityRate);
        
        // APR = rate * seconds_per_year * 10000 / 1e27
        apr = (liquidityRate * 365 days * 10000) / 1e27;
    }
}