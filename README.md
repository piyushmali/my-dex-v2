# MyDex: Decentralized Exchange with Advanced Features

## Overview

MyDex is a decentralized exchange (DEX) built on the Polygon blockchain, leveraging Uniswap's infrastructure for secure and efficient token swaps and liquidity management. The platform introduces enhanced features such as governance, staking rewards, whitelisting, and advanced safety mechanisms to provide a robust DeFi experience.

## Deployed Contracts (Polygon Amoy Testnet)

- **Dex Contract**: [`0xe984806f981b5172C7fC0DC68975c7FeEd806cA8`](https://amoy.polygonscan.com/address/0xe984806f981b5172C7fC0DC68975c7FeEd806cA8#code)
- **Governance Token**: [`0x53A814bCfE0970c528C17BE65BBF4e0d4a646394`](https://amoy.polygonscan.com/address/0x53A814bCfE0970c528C17BE65BBF4e0d4a646394#code)
- **Test Token A**: [`0xc740c093Da28593aB39ec39253aF63d896d4c03F`](https://amoy.polygonscan.com/address/0xc740c093Da28593aB39ec39253aF63d896d4c03F#code)
- **Test Token B**: [`0xeDeD090AA514493b1cf54d19A48830Aa5aB70EBd`](https://amoy.polygonscan.com/address/0xeDeD090AA514493b1cf54d19A48830Aa5aB70EBd#code)

## Key Features

### 1. Advanced Liquidity Management

- **Token Whitelisting**: Only pre-approved tokens can be added to liquidity pools, ensuring security and quality control.
- **Liquidity Tracking**:
  - Precisely tracks liquidity providers for each token pair.
  - Records the amount of liquidity provided by each user
  - Enables fair distribution of staking rewards
- **Staking Rewards System**
  - Automatically calculates rewards based on liquidity contribution
  - Reward rate of 0.1% of liquidity provided
  - Users can claim rewards for specific token pairs

### 2. Token Swapping Mechanism

- **Fee-Based Swapping**
  - 0.3% fee on every token swap
  - Fees collected and transferred to a designated fee collector
  - Supports multi-hop token swaps through different trading paths
- **Whitelist Protection**
  - Ensures only whitelisted tokens can be swapped
  - Prevents potential scam or malicious token interactions
- **Slippage and Deadline Control**
  - Users can specify minimum output amounts
  - Set transaction deadline to prevent long-pending transactions

### 3. Price Oracle and Manipulation Prevention

- **Price Tracking**
  - Tracks token prices between pairs
  - Updates allowed only once per hour to prevent frequent manipulation
  - Uses Uniswap's price calculation mechanism
- **Price Check Cooldown**
  - 1-hour cooldown between price updates
  - Provides stability and prevents rapid price fluctuations

### 4. Governance and Access Control

- **Ownership Management**
  - Contract owner can perform critical operations
  - Whitelist/delist tokens
  - Pause/unpause contract in emergencies
- **Governance Token Integration**
  - Requires governance token balance for certain operations
  - Fee percentage updates controlled by token holders
  - Minimum token balance required for proposal creation

### 5. Security Features

- **ReentrancyGuard**
  - Prevents recursive call attacks
  - Protects critical functions like liquidity addition and withdrawal
- **Emergency Mechanisms**
  - Contract pause functionality
  - Emergency token withdrawal
  - Flexible fee collector updates
- **Safe Token Transfers**
  - Uses OpenZeppelin's SafeERC20 for secure token interactions
  - Checks and validates token transfers

### 6. Transparency and Accessibility

- **View Functions**
  - Retrieve supported token pairs
  - Check staking rewards
  - Get real-time token prices
- **Event Logging**
  - Comprehensive event emission for all critical actions
  - Enables easy tracking of liquidity, swaps, and governance actions

### 7. Flexible Token Pair Management

- **Dynamic Pair Creation**
  - Automatically create token pairs if they don't exist
  - Add and track supported token pairs
  - Extensible architecture for future token integrations

### 8. Customizable Fee Structure

- **Configurable Fee Percentage**
  - Owner and high-stake governance token holders can update fees
  - Maximum fee limit of 1% to prevent excessive charges
- **Transparent Fee Collection**
  - Dedicated fee collector address
  - Ability to update fee collector by contract owner

## Smart Contracts

### Dex Contract

- Integrates with Uniswap V2 Router and Factory
- Supports liquidity provision and token swapping
- Implements fee collection and distribution
- Provides emergency withdraw mechanism

### GovernanceToken Contract

- ERC20 token with advanced vesting
- Token allocation with custom vesting schedules
- Governance proposal creation
- Cliff and linear vesting implementation

## Getting Started

### Prerequisites

- Node.js
- Hardhat
- Polygon Wallet with Amoy testnet MATIC

### Installation

```bash
git clone https://github.com/yourusername/my-dex-v2.git
cd my-dex-v2
npm install
```

### Deployment

Ensure you have configured your `.env` file with:

- `POLYGON_AMOY_RPC_URL`
- `PRIVATE_KEY`
- `POLYGONSCAN_API_KEY`

Deploy using Hardhat Ignition:

```bash
npx hardhat ignition deploy ignition/modules/deploy.js --network amoy
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License.

## Disclaimer

This is a testnet project and should not be used with real assets. Always do your own research and understand the risks involved in decentralized finance.
