// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@contracts/interfaces/IAdapter.sol";

contract YieldRouter {
    
    struct userDeposit {
        address adapter;
        address asset;
        uint256 amount;
    }
    
    mapping(address => userDeposit) public userDeposits;

    address[] public adapters;

    event Deposited(address indexed user, uint256 amount, uint256 apy, uint256 apr);
    event Withdrawn(address indexed user, uint256 amount);
    
    constructor() {
    }

    function addAdapter(address adapter) external {
        adapters.push(adapter);
    }

    function getAdapter() public view returns (address) {
        return adapters[0];
    }

    function deposit(address asset, uint256 amount) external {
        require(amount > 0, "zero amount");
        address adapter = getAdapter();
        if (userDeposits[msg.sender].amount > 0) {
            require(userDeposits[msg.sender].asset == asset, "asset mismatch");
            require(userDeposits[msg.sender].adapter == adapter, "protocol mismatch");
        }
        require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "transfer failed");
        // optimize this
        IERC20(asset).approve(address(adapter), amount);

        IAdapter(adapter).deposit(asset, amount);

        // Update internal accounting
        userDeposits[msg.sender].adapter = adapter;
        userDeposits[msg.sender].asset = asset;
        userDeposits[msg.sender].amount += amount;
    }

}