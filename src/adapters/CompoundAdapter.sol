// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@contracts/interfaces/ICToken.sol";
import "@contracts/interfaces/IComptroller.sol";
import "@contracts/interfaces/IAdapter.sol";
import "@contracts/Utils.sol";
import "@contracts/ERC20Rescuer.sol";

contract CompoundAdapter is IAdapter, ERC20Rescuer {
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    // can add all cTokens that are available over Compound

    mapping(address => address) cToken;
    address public router;

    modifier onlyRouter() {
        require(msg.sender == router, "only router");
        _;
    }

    constructor(address _router) ERC20Rescuer(_router) {
        router = _router;
        cToken[USDC] = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;
        cToken[USDT] = 0x3Afdc9BCA9213A35503b077a6072F3D0d5AB0840;
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

    // function _getCToken(address asset) internal view returns (address _cToken) {
    //     address[] memory markets = IComptroller(comptroller).getAllMarkets();

    //     for (uint256 i = 0; i < markets.length; i++) {
    //         try ICToken(markets[i]).underlying() returns (address underlying) {
    //             if (underlying == asset) {
    //                 return markets[i];
    //             }
    //         } catch {
    //             // some markets (like cETH) don't implement `underlying()`
    //         }
    //     }
    //     revert("Asset not supported on Compound");
    // }

    // function depositOld(address asset, uint256 amount) external onlyRouter {
    //     require(amount > 0, "zero amount");
    //     require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "transfer failed");
    //     address cTokenAddr = _getCToken(asset);

    //     IERC20(asset).approve(address(cTokenAddr), amount);

    //     uint256 result = ICToken(cTokenAddr).mint(amount);
    //     require(result == 0, "compound mint failed");

    //     emit Deposit(msg.sender, asset, amount);
    // }

    // function withdrawOld(address asset, uint256 amount) external onlyRouter returns (uint256) {
    //     require(amount > 0, "zero amount");
    //     address cTokenAddr = _getCToken(asset);

    //     uint256 withdrawAmount = ICToken(cTokenAddr).redeemUnderlying(amount);
    //     require(withdrawAmount == 0, "compound redeem failed");

    //     require(IERC20(asset).transfer(msg.sender, withdrawAmount), "transfer failed");

    //     emit Withdraw(msg.sender, asset, withdrawAmount);

    //     return withdrawAmount;
    // }
}
