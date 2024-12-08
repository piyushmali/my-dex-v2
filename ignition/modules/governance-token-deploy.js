const { buildModule } = require('@nomicfoundation/hardhat-ignition/modules')

module.exports = buildModule('GovernanceTokenModule', (m) => {
  const initialOwner = m.getParameter(
    'initialOwner',
    '0x87170c5c3b018dd29701fcb4debca1f152d1053d'
  )

  // Deploy the GovernanceToken
  const governanceToken = m.contract('GovernanceToken')

  return { governanceToken }
})
