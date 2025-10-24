// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@contracts/interfaces/IAdapter.sol";

contract YieldRouter is Ownable2Step, ReentrancyGuard {
    struct userDeposit {
        address adapter;
        address asset;
        uint256 amount;
    }

    mapping(address => userDeposit) public userDeposits;
    mapping(address => string) public adapterNames;
    mapping(address => mapping(address => bool)) public rebalancers;

    address[] public adapters;

    address public feeReceiver;
    uint256 public protocolFee = 1000; // 10%
    uint256 public constant BASIS_POINTS = 10000; // 100%

    event Deposited(address indexed user, address indexed adapter, uint256 amount);
    event Withdrawn(address indexed user, address indexed adapter, uint256 amount);
    event Rebalanced(
        address indexed user,
        address indexed currentAdapter,
        address indexed newAdapter,
        uint256 oldAmount,
        uint256 newAmount
    );

    constructor() Ownable(msg.sender) {}

    function addAdapter(address adapter, string memory name) external onlyOwner {
        require(adapter != address(0), "zero address");
        require(bytes(adapterNames[adapter]).length == 0, "adapter already added");

        adapters.push(adapter);
        adapterNames[adapter] = name;
    }

    function removeAdapter(address adapter) external onlyOwner {
        require(bytes(adapterNames[adapter]).length != 0, "adapter not found");
        for (uint256 i = 0; i < adapters.length; i++) {
            if (adapters[i] == adapter) {
                if (i != adapters.length - 1) {
                    adapters[i] = adapters[adapters.length - 1];
                }
                adapters.pop();
                break;
            }
        }
        delete adapterNames[adapter];
    }

    function getBestAdapter(address asset) public view returns (address) {
        uint256 highestAPY = 0;
        uint256 adapterIndex;
        for (uint256 i = 0; i < adapters.length; i++) {
            uint256 apy = IAdapter(adapters[i]).getAPY(asset);
            if (apy > highestAPY) {
                highestAPY = apy;
                adapterIndex = i;
            }
        }
        return adapters[adapterIndex];
    }

    function deposit(address asset, uint256 amount) external nonReentrant {
        require(amount > 0, "zero amount");
        address adapter = getBestAdapter(asset);
        if (userDeposits[msg.sender].amount > 0) {
            require(userDeposits[msg.sender].asset == asset, "asset mismatch");
            // rebalance required here
            require(userDeposits[msg.sender].adapter == adapter, "protocol mismatch");
        }
        require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "transfer failed");

        IERC20(asset).approve(address(adapter), amount);

        IAdapter(adapter).deposit(asset, amount);

        userDeposits[msg.sender].adapter = adapter;
        userDeposits[msg.sender].asset = asset;
        userDeposits[msg.sender].amount += amount;

        emit Deposited(msg.sender, adapter, amount);
    }

    function withdraw(address asset, uint256 amount) external nonReentrant {
        require(amount > 0, "zero amount");
        require(userDeposits[msg.sender].amount == amount, "invalid amount");

        address adapter = userDeposits[msg.sender].adapter;
        uint256 withdrawAmount = IAdapter(adapter).withdraw(asset, amount);

        uint256 protocolAmount;
        if (withdrawAmount > userDeposits[msg.sender].amount) {
            protocolAmount = ((withdrawAmount - userDeposits[msg.sender].amount) * protocolFee) / BASIS_POINTS;
            require(IERC20(asset).transferFrom(address(this), feeReceiver, protocolAmount), "fee transfer failed");
        }
        delete userDeposits[msg.sender];

        require(
            IERC20(asset).transferFrom(address(this), msg.sender, withdrawAmount - protocolAmount), "transfer failed"
        );

        emit Withdrawn(msg.sender, adapter, amount);
    }

    function rebalance(address user, address asset) public nonReentrant {
        require(userDeposits[user].amount > 0, "no deposit found");
        require(msg.sender == user || rebalancers[user][msg.sender], "not allowed");
        address currentAdapter = userDeposits[msg.sender].adapter;
        address newAdapter = getBestAdapter(asset);
        _validateRebalancing(asset, currentAdapter, newAdapter);

        uint256 currentAmount = userDeposits[msg.sender].amount;
        uint256 withdrawAmount = IAdapter(currentAdapter).withdraw(asset, currentAmount);

        IAdapter(newAdapter).deposit(asset, withdrawAmount);

        userDeposits[msg.sender].adapter = newAdapter;
        userDeposits[msg.sender].asset = asset;
        userDeposits[msg.sender].amount += withdrawAmount;

        emit Rebalanced(msg.sender, currentAdapter, newAdapter, currentAmount, withdrawAmount);
    }

    function setRebalancer(address rebalancer, bool status) external {
        rebalancers[msg.sender][rebalancer] = status;
    }

    function _validateRebalancing(address asset, address currentAdapter, address newAdapter) internal view {
        require(currentAdapter != newAdapter, "no rebalancing required");
        uint256 currentAPY = IAdapter(currentAdapter).getAPY(asset);
        uint256 newAPY = IAdapter(newAdapter).getAPY(asset);
        require(newAPY > currentAPY && newAPY - currentAPY > 1000, "apy difference negligible");
    }
}
