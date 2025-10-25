// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@contracts/interfaces/ICToken.sol";
import "@contracts/interfaces/IAdapter.sol";
import "@contracts/Utils.sol";
import "@contracts/ERC20Rescuer.sol";

contract CompoundAdapter is IAdapter, ERC20Rescuer {
    mapping(address => address) public cToken;
    address public router;

    modifier onlyRouter() {
        require(msg.sender == router, "only router");
        _;
    }

    constructor(address _router) ERC20Rescuer(_router) {
        router = _router;
    }

    function addCToken(address asset, address cAsset) external onlyRouter {
        cToken[asset] = cAsset;
    }

    function deposit(address asset, uint256 amount) external onlyRouter {
        require(amount > 0, "zero amount");
        require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "transfer failed");
        address cTokenAddr = cToken[asset];

        IERC20(asset).approve(address(cTokenAddr), amount);

        ICToken(cTokenAddr).supply(asset, amount);

        emit Deposit(msg.sender, asset, amount);
    }

    function withdraw(address asset, uint256 amount) external onlyRouter returns (uint256) {
        require(amount > 0, "zero amount");
        address cTokenAddr = cToken[asset];

        uint256 balanceBefore = IERC20(asset).balanceOf(address(this));
        ICToken(cTokenAddr).withdraw(asset, amount - 1);
        uint256 withdrawAmount = IERC20(asset).balanceOf(address(this)) - balanceBefore;

        require(IERC20(asset).transfer(msg.sender, withdrawAmount), "transfer failed");

        emit Withdraw(msg.sender, asset, withdrawAmount);

        return withdrawAmount;
    }

    function getAPR(address asset) public returns (uint256 apr) {
        address cTokenAddr = cToken[asset];
        uint256 utilization = ICToken(cTokenAddr).getUtilization();
        uint256 ratePerBlock = ICToken(cTokenAddr).getSupplyRate(utilization);
        apr = ratePerBlock * 365 days * 1e2; // convert to 1e18 percent
    }

    function getAPY(address asset) public returns (uint256 apy) {
        uint256 apr = getAPR(asset);
        apy = Utils.aprToApy(apr);
    }
}
