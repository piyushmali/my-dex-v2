# MyDex: Decentralized Token Exchange

## Overview

MyDex is a Solidity-based decentralized exchange (DEX) smart contract built on Uniswap V2 infrastructure, providing liquidity management, token swapping, and fee collection functionalities.

## Contract Addresses

- **MyDex Contract:** `0xee007ba8B00621F8AE656E907534dEb2A8556637`
- **MyTokenA:** `0x20332abC85F314bbd327FB59E9133Df507badF52`
- **MyTokenB:** `0x058C176a248F1EEaD1EeB219DF908E44c3c75A63`
- **UniswapV2Factory:** `0x997FF200E19870F056b247A7d0B2Cc6F08Ca73c1`
- **UniswapV2Router02:** `0x35acf34A82492967a132Ec251B580DCaD7CF067D`
- **WETH9:** `0x8bab02D6FF57b9AF6f3c7a013050DB95cc8c2fCC`

## Features

- Liquidity provision and removal
- Token swapping with fee mechanism
- Emergency withdrawal
- Supported token pair management
- Fee collection

## Key Functions

### Liquidity Management

- `addLiquidity()`: Add liquidity to a token pair
- `removeLiquidity()`: Remove liquidity from a token pair

### Token Swapping

- `swapTokensWithFee()`: Swap tokens with a 0.3% fee mechanism

### Administration

- `addSupportedPair()`: Add new token pairs
- `updateFeeCollector()`: Update fee collection address
- `emergencyWithdraw()`: Withdraw tokens in case of emergencies

## Fee Structure

- Fixed fee percentage: 0.3%
- Fee is collected and sent to a designated fee collector address

## Security Considerations

- Uses OpenZeppelin's `Ownable` for access control
- Implements `ReentrancyGuard` to prevent re-entrancy attacks
- External function calls routed through Uniswap V2 Router

## Development Environment

### Prerequisites

- Hardhat
- Node.js
- Solidity ^0.8.20

### Dependencies

- @openzeppelin/contracts: ^5.1.0
- @uniswap/v2-core: ^1.0.1
- @uniswap/v2-periphery: ^1.1.0-beta.0

### Network Configuration

- Default Network: Polygon Amoy Testnet
- Chain ID: 80002

## Deployment

1. Install dependencies

```bash
npm install
```

2. Configure environment variables

- Create a `.env` file with:
  - `POLYGON_AMOY_RPC_URL`
  - `PRIVATE_KEY`
  - `POLYGONSCAN_API_KEY`

3. Deploy contract

```bash
npx hardhat run scripts/deploy.js --network amoy
```

## Testing

```bash
npx hardhat test
```

## Verify on PolygonScan

```bash
npx hardhat verify --network amoy <CONTRACT_ADDRESS>
```

## License

MIT License
