// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@contracts/interfaces/IAavePool.sol";
import "@contracts/interfaces/IAdapter.sol";
import "@contracts/Utils.sol";
import "@contracts/ERC20Rescuer.sol";

contract AaveAdapter is IAdapter, ERC20Rescuer {
    IAavePool public pool;
    address public router;

    modifier onlyRouter() {
        require(msg.sender == router, "only router");
        _;
    }

    constructor(address _router, address _pool) ERC20Rescuer(_router) {
        router = _router;
        pool = IAavePool(_pool);
    }

    function deposit(address asset, uint256 amount) external onlyRouter {
        require(amount > 0, "zero amount");
        require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "transfer failed");
        IERC20(asset).approve(address(pool), amount);
        pool.supply(asset, amount, address(this), 0);

        emit Deposit(msg.sender, asset, amount);
    }

    function withdraw(address asset, uint256 amount) external onlyRouter returns (uint256) {
        uint256 withdrawAmount = pool.withdraw(asset, amount, address(this));
        require(IERC20(asset).transfer(msg.sender, withdrawAmount), "Transfer failed");

        emit Withdraw(msg.sender, asset, amount);

        return withdrawAmount;
    }

    function getAPR(address asset) public view returns (uint256 apr) {
        IAavePool.ReserveData memory data = pool.getReserveData(asset);
        uint256 liquidityRate = uint256(data.currentLiquidityRate);
        apr = (liquidityRate * 365 days) / 1e15; // convert into 1e18
    }

    function getAPY(address asset) public view returns (uint256 apy) {
        uint256 apr = getAPR(asset);
        apy = Utils.aprToApy(apr);
    }
}
