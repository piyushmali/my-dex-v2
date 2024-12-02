const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('MyDex Contract with Deployed Addresses', function () {
  let MyDex, myDex, mockTokenA, mockTokenB
  let owner, addr1

  // Replace these with the actual addresses of deployed contracts
  const UNISWAP_ROUTER_ADDRESS = '0x8a7fD7429aD9131ea9866d6af901d3F81598E081'
  const UNISWAP_FACTORY_ADDRESS = '0x48e8f8342dC58e28DBd81d1F4d2442CF369D51f1'

  beforeEach(async function () {
    ;[owner, addr1] = await ethers.getSigners()

    // Deploy mock tokens for testing
    const MockTokenA = await ethers.getContractFactory('MyTokenA')
    mockTokenA = await MockTokenA.deploy(ethers.parseUnits('10000', 18))

    const MockTokenB = await ethers.getContractFactory('MyTokenB')
    mockTokenB = await MockTokenB.deploy(ethers.parseUnits('10000', 18))

    // Deploy MyDex contract using the actual Uniswap Router and Factory addresses
    MyDex = await ethers.getContractFactory('MyDex')
    myDex = await MyDex.deploy(
      UNISWAP_ROUTER_ADDRESS,
      UNISWAP_FACTORY_ADDRESS,
      mockTokenA.target,
      mockTokenB.target
    )
    // Approve tokens for the MyDex contract
    await mockTokenA
      .connect(owner)
      .approve(myDex.target, ethers.parseUnits('1000', 18))
    await mockTokenB
      .connect(owner)
      .approve(myDex.target, ethers.parseUnits('1000', 18))
  })

  it('should add liquidity using the deployed router', async function () {
    expect(
      await myDex.addLiquidity(
        ethers.parseUnits('100', 18),
        ethers.parseUnits('100', 18),
        ethers.parseUnits('90', 18),
        ethers.parseUnits('90', 18),
        owner.address,
        3600 // deadline
      )
    ).to.not.be.reverted
  })

  it('should swap tokens using the deployed router', async function () {
    await myDex.addLiquidity(
      ethers.parseUnits('100', 18),
      ethers.parseUnits('100', 18),
      ethers.parseUnits('90', 18),
      ethers.parseUnits('90', 18),
      owner.address,
      3600 // deadline
    )

    // Assuming the path from mockTokenA to mockTokenB is set correctly
    expect(
      await myDex.swapTokensForTokens(
        ethers.parseUnits('20', 18),
        ethers.parseUnits('10', 18),
        [mockTokenA.target, mockTokenB.target],
        owner.address,
        3600 // deadline
      )
    ).to.not.be.reverted
  })

  // it('should remove liquidity using the deployed router', async function () {
  //   await myDex.addLiquidity(
  //     ethers.parseUnits('100', 18),
  //     ethers.parseUnits('100', 18),
  //     ethers.parseUnits('90', 18),
  //     ethers.parseUnits('90', 18),
  //     owner.address,
  //     3600 // deadline
  //   )

  //   // Mock liquidity value
  //   const liquidity = 1

  //   await myDex.removeLiquidity(
  //     liquidity,
  //     ethers.parseUnits('90', 18),
  //     ethers.parseUnits('90', 18),
  //     owner.address,
  //     3600 // deadline
  //   )

  //   // Check balances after removing liquidity
  //   expect(await mockTokenA.balanceOf(myDex.target)).to.be.below(
  //     ethers.parseUnits('100', 18)
  //   )
  //   expect(await mockTokenB.balanceOf(myDex.target)).to.be.below(
  //     ethers.parseUnits('100', 18)
  //   )
  // })

  it('should create a pair using the deployed factory', async function () {
    const pairAddress = await myDex.createPair()
    expect(pairAddress).to.not.equal(ethers.AddressZero)
  })

  it('should get pair address using the deployed factory', async function () {
    await myDex.createPair()
    const pairAddress = await myDex.getPair()
    expect(pairAddress).to.not.equal(ethers.AddressZero)
  })
})
