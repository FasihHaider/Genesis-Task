## Yield Router

**The Yield Router is a Solidity-based smart contract system that automatically allocates a user’s deposited stablecoins (USDC / DAI) across leading DeFi protocols — Aave, Compound etc — based on real-time yield rates.**

**It continuously monitors APYs across supported protocols, routes new deposits to the one offering the highest yield, and supports profit tracking and instant withdrawals.**

## Features

### 💸 Automatic Allocation
Deposits are automatically directed to the protocol (Aave / Compound) with the highest current yield (APY).

### 📈 Real-time Yield Comparison
Fetches live APY data from Aave and Compound adapters.

### 🧾 Per-User Accounting
Tracks each user’s deposit amount, allocated protocol, and accrued yield.

### 🔄 Rebalancing
Admin or automated bot can trigger rebalancing between protocols when APY difference exceeds a defined threshold (e.g. >1%).

### 💰 Seamless Withdrawals
Users can withdraw their deposits anytime and receive their principal + profit directly in the original stablecoin.

### 🧱 Modular Adapter Architecture
Each DeFi protocol (Aave, Compound, etc.) has its own adapter contract implementing a unified interface for deposit, withdraw, and rate queries.

### 🔐 Security Built-in

- Ownable: Admin privileges restricted to contract owner

- ReentrancyGuard: Prevents reentrancy attacks

- ERC20Rescue: Allows owner to recover stuck tokens safely


### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```