// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@contracts/interfaces/ICToken.sol";
import "@contracts/interfaces/IComptroller.sol";
import "@contracts/interfaces/IAdapter.sol";

contract CompoundAdapter is IAdapter {
    uint256 public constant BLOCKS_PER_YEAR = 2_300_000;
    uint256 public constant EXP_SCALE = 1e18;

    address public comptroller;
    address public router;

    constructor(address _router, address _comptroller) {
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

    function deposit(address asset, uint256 amount) external {
        require(amount > 0, "zero amount");
        require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "transfer failed");
        address cTokenAddr = _getCToken(asset);

        IERC20(asset).approve(address(cTokenAddr), amount);

        uint256 result = ICToken(cTokenAddr).mint(amount);
        require(result == 0, "compound mint failed");

        emit Deposited(msg.sender, asset, amount);
    }

    function withdraw(address asset, uint256 amount) external returns (uint256) {
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
        apr = ratePerBlock * BLOCKS_PER_YEAR; // ~annualized, 1e18 scale
    }

    function getAPY(address asset) external view returns (uint256 apy) {
        address cTokenAddr = _getCToken(asset);
        uint256 ratePerBlock = ICToken(cTokenAddr).supplyRatePerBlock();
        uint256 onePlusRate = EXP_SCALE + ratePerBlock;
        uint256 power = rpow(onePlusRate, BLOCKS_PER_YEAR, EXP_SCALE);
        apy = power - EXP_SCALE;
    }

    function rpow(uint256 x, uint256 n, uint256 base) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 { z := base }
                default { z := 0 }
            }
            default {
                switch mod(n, 2)
                case 0 { z := base }
                default { z := x }
                let half := div(base, 2)
                for { n := div(n, 2) } n { n := div(n, 2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0, 0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0, 0) }
                    x := div(xxRound, base)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if iszero(eq(div(zx, x), z)) { revert(0, 0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0, 0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}
