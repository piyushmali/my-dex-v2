const { buildModule } = require('@nomicfoundation/hardhat-ignition/modules')

const tokenA = '0xf361803983295fEF4763182C7e9Bb8014FE7d8e2'
const tokenB = '0x078c197A9a2791c0692a78aa7E939829923a1aac'

module.exports = buildModule('MyDexModule', (m) => {
  const uniswapRouterAddress = m.getParameter(
    'uniswapRouterAddress',
    '0x8a7fD7429aD9131ea9866d6af901d3F81598E081'
  )
  const uniswapFactoryAddress = m.getParameter(
    'uniswapFactoryAddress',
    '0x48e8f8342dC58e28DBd81d1F4d2442CF369D51f1'
  )
  const tokenAAddress = m.getParameter('tokenAAddress', tokenA)
  const tokenBAddress = m.getParameter('tokenBAddress', tokenB)

  // Deploy the MyDex contract
  const myDex = m.contract('MyDex', [
    uniswapRouterAddress,
    uniswapFactoryAddress,
    tokenAAddress,
    tokenBAddress,
  ])

  return { myDex }
})
