// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@contracts/interfaces/ICToken.sol";
import "@contracts/interfaces/IComptroller.sol";
import "@contracts/interfaces/IAdapter.sol";
import "@contracts/Utils.sol";
import "@contracts/ERC20Rescuer.sol";

contract CompoundAdapter is IAdapter, ERC20Rescuer {
    uint256 public constant BLOCKS_PER_YEAR = 2_300_000;

    address public comptroller;
    address public router;

    modifier onlyRouter() {
        require(msg.sender == router, "only router");
        _;
    }

    constructor(address _router, address _comptroller) ERC20Rescuer(_router) {
        router = _router;
        comptroller = _comptroller;
    }

    function _getCToken(address asset) internal view returns (address cToken) {
        address[] memory markets = IComptroller(comptroller).getAllMarkets();

        for (uint256 i = 0; i < markets.length; i++) {
            try ICToken(markets[i]).underlying() returns (address underlying) {
                if (underlying == asset) {
                    return markets[i];
                }
            } catch {
                // some markets (like cETH) don't implement `underlying()`
            }
        }
        revert("Asset not supported on Compound");
    }

    function deposit(address asset, uint256 amount) external onlyRouter {
        require(amount > 0, "zero amount");
        require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "transfer failed");
        address cTokenAddr = _getCToken(asset);

        IERC20(asset).approve(address(cTokenAddr), amount);

        uint256 result = ICToken(cTokenAddr).mint(amount);
        require(result == 0, "compound mint failed");

        emit Deposited(msg.sender, asset, amount);
    }

    function withdraw(address asset, uint256 amount) external onlyRouter returns (uint256) {
        require(amount > 0, "zero amount");
        address cTokenAddr = _getCToken(asset);

        uint256 withdrawAmount = ICToken(cTokenAddr).redeemUnderlying(amount);
        require(withdrawAmount == 0, "compound redeem failed");

        require(IERC20(asset).transfer(msg.sender, withdrawAmount), "transfer failed");

        emit Withdrawn(msg.sender, asset, amount);

        return withdrawAmount;
    }

    function getAPR(address asset) public view returns (uint256 apr) {
        address cTokenAddr = _getCToken(asset);
        uint256 ratePerBlock = ICToken(cTokenAddr).supplyRatePerBlock();
        apr = ratePerBlock * BLOCKS_PER_YEAR * 1e2; // convert to 1e18 percent
    }

    function getAPY(address asset) public view returns (uint256 apy) {
        uint256 apr = getAPR(asset);
        apy = Utils.aprToApy(apr);
    }
}
