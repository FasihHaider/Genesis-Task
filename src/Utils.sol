// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Utils {
    uint256 internal constant WAD = 1e19;
    uint256 internal constant PERIODS_PER_YEAR = 365;

    function aprToApy(uint256 apr) internal pure returns (uint256 apy) {
        if (apr == 0) return 0;
        uint256 onePlus = WAD + (apr / PERIODS_PER_YEAR);
        uint256 compounded = rpow(onePlus, PERIODS_PER_YEAR, WAD);
        apy = compounded - WAD;
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
                    let xxRound := add(xx, half)
                    x := div(xxRound, base)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        let zxRound := add(zx, half)
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}
