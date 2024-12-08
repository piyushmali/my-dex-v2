const { buildModule } = require('@nomicfoundation/hardhat-ignition/modules')

module.exports = buildModule('MyTokensModule', (m) => {
  const initialOwner = m.getParameter(
    'initialOwner',
    '0x87170c5c3b018dd29701fcb4debca1f152d1053d'
  )

  const initialSupplyA = m.getParameter(
    'initialSupplyA',
    ethers.parseUnits('1000000', 18) // 1 million tokens for MyTokenA
  )

  const initialSupplyB = m.getParameter(
    'initialSupplyB',
    ethers.parseUnits('1000000', 18) // 1 million tokens for MyTokenB
  )

  // Deploy MyTokenA
  const myTokenA = m.contract('MyTokenA', [initialSupplyA])

  // Deploy MyTokenB
  const myTokenB = m.contract('MyTokenB', [initialSupplyB])

  return { myTokenA, myTokenB }
})
