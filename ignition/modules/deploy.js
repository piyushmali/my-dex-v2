const { buildModule } = require('@nomicfoundation/hardhat-ignition/modules')

module.exports = buildModule('DexModule', (m) => {
  // Uniswap router and factory addresses
  const uniswapRouterAddress = m.getParameter(
    'uniswapRouterAddress',
    '0x35acf34A82492967a132Ec251B580DCaD7CF067D'
  )
  const uniswapFactoryAddress = m.getParameter(
    'uniswapFactoryAddress',
    '0x997FF200E19870F056b247A7d0B2Cc6F08Ca73c1'
  )

  // Fee collector address
  const feeCollectorAddress = m.getParameter(
    'feeCollectorAddress',
    '0x87170c5c3b018dd29701fcb4debca1f152d1053d'
  )

  // Governance token address
  const governanceTokenAddress = m.getParameter(
    'governanceTokenAddress',
    '0x53A814bCfE0970c528C17BE65BBF4e0d4a646394'
  )

  // Deploy the Dex contract
  const dex = m.contract('Dex', [
    uniswapRouterAddress,
    uniswapFactoryAddress,
    feeCollectorAddress,
    governanceTokenAddress,
  ])

  return { dex }
})
