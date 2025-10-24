// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@contracts/interfaces/IAavePool.sol";
import "@contracts/interfaces/IAdapter.sol";

contract AaveAdapter is IAdapter {
    IAavePool public pool;
    address public router;

    constructor(address _router, address _pool) {
        router = _router;
        pool = IAavePool(_pool);
    }

    function deposit(address asset, uint256 amount) external {
        require(amount > 0, "zero amount");
        require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "transfer failed");
        IERC20(asset).approve(address(pool), amount);
        pool.supply(asset, amount, address(this), 0);

        emit Deposited(msg.sender, asset, amount);
    }

    function withdraw(address asset, uint256 amount) external {
        uint256 withdrawAmount = pool.withdraw(asset, amount, address(this));
        require(IERC20(asset).transfer(msg.sender, withdrawAmount), "Transfer failed");

        emit Withdrawn(msg.sender, asset, amount);
    }

    /// @notice Calculate APR (simple interest) for comparison
    /// @param asset The asset address
    /// @return apr APR as basis points (e.g., 500 = 5.00%)
    function getAPR(address asset) public view returns (uint256 apr) {
        IAavePool.ReserveData memory data = pool.getReserveData(asset);
        uint256 liquidityRate = uint256(data.currentLiquidityRate);

        // APR = rate * seconds_per_year * 10000 / 1e27
        apr = (liquidityRate * 365 days * 10000) / 1e27;
    }

    /// @notice Calculate APY for an Aave asset (simplified version)
    /// @param asset The asset address
    /// @return apy APY as basis points (e.g., 523 = 5.23%)
    function getAPY(address asset) external view returns (uint256 apy) {
        // Get APR first
        uint256 apr = getAPR(asset);

        // Simple approximation: APY ≈ APR + (APR^2 / 20000)
        // This is accurate for small rates and avoids overflow
        if (apr > 0) {
            uint256 aprSquared = (apr * apr) / 10000; // Convert to proper scale
            apy = apr + (aprSquared / 20000);
        } else {
            apy = 0;
        }
    }
}
