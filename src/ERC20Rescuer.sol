// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@contracts/interfaces/IERC20Rescuer.sol";

contract ERC20Rescuer is IERC20Rescuer {
    address public rescuer;

    modifier onlyRescuer() {
        require(msg.sender == rescuer, "only rescuer");
        _;
    }

    constructor(address _rescuer) {
        rescuer = _rescuer;
    }

    function rescueERC20(address token, address to, uint256 amount) external onlyRescuer {
        require(token != address(0), "invalid token");
        require(to != address(0), "invalid recipient");
        require(amount > 0, "zero amount");

        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance >= amount, "insufficient balance");

        bool success = IERC20(token).transfer(to, amount);
        require(success, "token transfer failed");
    }
}
