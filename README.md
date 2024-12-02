# My DEX v2

**My DEX v2** is a decentralized exchange (DEX) built on top of Uniswap V2, enabling users to interact with token pairs, add/remove liquidity, and perform token swaps. This project utilizes Uniswap V2's core and periphery contracts while adding custom features and token integrations.

---

## Features

- **Liquidity Management**
  - Add liquidity to token pairs.
  - Remove liquidity and withdraw corresponding token amounts.
- **Token Swapping**
  - Swap tokens using a customizable path via Uniswap's `swapExactTokensForTokens`.
- **Pair Creation and Management**
  - Create new token pairs.
  - Retrieve pair addresses for existing token pairs.

---

## Deployed Addresses

| **Component**         | **Address**                                                                                                                        |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **MyDex**             | [0x8043950ba6555505ef2C894fCf02623E51Eb24a4](https://amoy.polygonscan.com/address/0x8043950ba6555505ef2C894fCf02623E51Eb24a4#code) |
| **MyTokenA**          | [0xf361803983295fEF4763182C7e9Bb8014FE7d8e2](https://amoy.polygonscan.com/address/0xf361803983295fEF4763182C7e9Bb8014FE7d8e2#code) |
| **MyTokenB**          | [0x078c197A9a2791c0692a78aa7E939829923a1aac](https://amoy.polygonscan.com/address/0x078c197A9a2791c0692a78aa7E939829923a1aac#code) |
| **UniswapV2Factory**  | [0x48e8f8342dC58e28DBd81d1F4d2442CF369D51f1](https://amoy.polygonscan.com/address/0x48e8f8342dC58e28DBd81d1F4d2442CF369D51f1#code) |
| **UniswapV2Router02** | [0x8a7fD7429aD9131ea9866d6af901d3F81598E081](https://amoy.polygonscan.com/address/0x8a7fD7429aD9131ea9866d6af901d3F81598E081#code) |
| **WETH9**             | [0x90852dF4AB41364d82d9BaBae3EF4109cDE01825](https://amoy.polygonscan.com/address/0x90852dF4AB41364d82d9BaBae3EF4109cDE01825#code) |

---

## Setup and Deployment

### Prerequisites

- [Node.js](https://nodejs.org/)
- [Hardhat](https://hardhat.org/)
- Installed dependencies using:

  ```bash
  npm install
  ```

---

### Environment Setup

Create a `.env` file in the root directory with the following details:

```plaintext
PRIVATE_KEY=<your-wallet-private-key>
INFURA_PROJECT_ID=<your-infura-project-id>
NETWORK=<network-name>
```

---

### Deploying Contracts

To deploy the `MyDex` contract on your configured network, run:

```bash
npx hardhat ignition deploy ./ignition/modules/deploy.js --network <network-name> --verify
```

---

### Testing

Run the tests using:

```bash
npx hardhat test
```

---

### Verifying Contracts

To verify deployed contracts, run:

```bash
npx hardhat verify <contract-address> --network <network-name>
```

---

## Acknowledgments

- **[OpenZeppelin](https://openzeppelin.com/):** For secure contract standards.
- **[Uniswap V2](https://uniswap.org/):** For the foundational DEX infrastructure.

---

## License

This project is licensed under the **MIT License**. See the `LICENSE` file for details.

---
