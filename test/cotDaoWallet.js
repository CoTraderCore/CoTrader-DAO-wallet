import { BN, fromWei } from 'web3-utils'

import ether from './helpers/ether'
import EVMRevert from './helpers/EVMRevert'
import { duration } from './helpers/duration'
import latestTime from './helpers/latestTime'
import advanceTimeAndBlock from './helpers/advanceTimeAndBlock'
const BigNumber = BN

require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

const CoTraderDAOWallet = artifacts.require('CoTraderDAOWallet')
const Token = artifacts.require('Token')
const Stake = artifacts.require('./Stake')

contract('CoTraderDAOWallet', function([userOne, userTwo]) {
  beforeEach(async function() {
    // Tokens config
    this.name = "TEST"
    this.symbol = "TST"

    this.decimals = 18
    this.totalSupply = 1000000

    // Deploy Token
    this.token = await Token.new(
      this.name,
      this.symbol,
      this.decimals,
      this.totalSupply
    )

    // Deploy Stake
    this.stake = await Stake.new(this.token.address)

    // Deploy daoWallet
    this.daoWallet = await CoTraderDAOWallet.new(this.token.address, this.stake.address)
  })

  describe('Token', function() {
    it('Correct init token', async function() {
      const name = await this.token.name()
      const symbol = await this.token.symbol()
      const decimals = await this.token.decimals()

      assert.equal("TEST", name)
      assert.equal("TST", symbol)
      assert.equal("TST", symbol)
    })
  })

  describe('Stake', function() {
    it('Correct init stake', async function() {
      const reserve = await this.stake.reserve()
      assert.equal(0, reserve)

      const token = await this.daoWallet.COT()
      assert.equal(this.token.address, token)
    })
  })

  describe('Wallet', function() {
    it('Correct init wallet', async function() {
      const COT = await this.daoWallet.COT()
      assert.equal(this.token.address, COT)

      const owner = await this.daoWallet.owner()
      assert.equal(userOne, owner)
    })

    it('Owner get 1/3 and stake get 1/3 and burn address get 1/3 after withdraw', async function() {
      await this.token.transfer(this.daoWallet.address, 999)
      await this.daoWallet.withdraw([this.token.address])
      const burnAddress = await this.daoWallet.zeroAddress()

      const ownerBalance = await this.token.balanceOf(userOne)
      const stakeBalance = await this.token.balanceOf(this.stake.address)
      const burnBalance = await this.token.balanceOf(burnAddress)

      assert.equal(ownerBalance, 999334)
      assert.equal(stakeBalance, 333)
      assert.equal(burnBalance, 333)
    })

    // Vote
    // Burn
    // Change owner
  })
})
