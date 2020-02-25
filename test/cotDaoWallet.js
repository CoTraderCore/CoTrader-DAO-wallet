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

contract('CoTraderDAOWallet', function([_, userOne, userTwo]) {
  beforeEach(async function() {
    // Tokens config
    this.name = "TEST"
    this.symbol = "TST"

    this.decimals = 18
    this.totalSupply = ether(1000000000000)

    // Deploy Token
    this.token = await Token.new(
      this.name,
      this.symbol,
      this.decimals,
      this.totalSupply
    )

    // Deploy Exchange
    this.daoWallet = await CoTraderDAOWallet.new(this.token.address)

    // Send some tokens to users
    await this.token.transfer(userOne, ether(10000000))
    await this.token.transfer(userTwo, ether(10000))
  })

  describe('Token', function() {
    it('Test token', async function() {
      const name = await this.token.name()
      const symbol = await this.token.symbol()
      const decimals = await this.token.decimals()

      assert.equal("TEST", name)
      assert.equal("TST", symbol)
      assert.equal("TST", symbol)
    })
  })

  describe('Wallet', function() {
    // Stake
    // Burn
    // Withdraw
    // Vote
  })


  // END
  })
})
