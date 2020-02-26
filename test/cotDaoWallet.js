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
const ConvertPortal = artifacts.require('./ConvertPortalMock.sol')

contract('CoTraderDAOWallet', function([userOne, userTwo, userThree]) {
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

    // Deploy ConvertPortal
    this.convertPortal await ConvertPortal.new(this.token.address)

    // Deploy daoWallet
    this.daoWallet = await CoTraderDAOWallet.new(
      this.token.address,
      this.stake.address,
      this.convertPortal)
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

    it('Owner get 1/3 and stake get 1/3 and burn address get 1/3 after destribute', async function() {
      await this.token.transfer(this.daoWallet.address, 999)
      await this.daoWallet.destribute([this.token.address])
      const burnAddress = await this.daoWallet.deadAddress()

      const ownerBalance = await this.token.balanceOf(userOne)
      const stakeBalance = await this.token.balanceOf(this.stake.address)
      const burnBalance = await this.token.balanceOf(burnAddress)

      assert.equal(ownerBalance, 999334)
      assert.equal(stakeBalance, 333)
      assert.equal(burnBalance, 333)
    })

    // Vote
    it('User can not change owner if there are no 51%', async function() {
      await this.daoWallet.changeOwner(userTwo).should.be.rejectedWith(EVMRevert)
    })

    it('User can not change owner if vote, but then transfer balance', async function() {
      await this.daoWallet.voterRegister({from: userOne})
      await this.daoWallet.vote(userTwo, {from: userOne})
      const userOneBalance = await this.token.balanceOf(userOne)
      await this.token.transfer(userTwo, userOneBalance)
      await this.daoWallet.changeOwner(userTwo, {from: userTwo}).should.be.rejectedWith(EVMRevert)
    })

    it('User can not change owner if there are only 50% voters', async function() {
      await this.daoWallet.voterRegister({from: userThree})
      await this.daoWallet.vote(userTwo, {from: userThree})
      await this.daoWallet.changeOwner(userTwo, {from: userTwo}).should.be.fulfilled
    })

    it('User can change owner if there are 51% voters', async function() {
      await this.daoWallet.voterRegister({from: userOne})
      await this.daoWallet.vote(userTwo, {from: userOne})
      await this.daoWallet.changeOwner(userTwo, {from: userTwo}).should.be.fulfilled
    })

    it('new owner get 1/3 after destribute', async function() {
      // Change owner
      await this.daoWallet.voterRegister({from: userOne})
      await this.daoWallet.vote(userTwo, {from: userOne})
      await this.daoWallet.changeOwner(userTwo, {from: userTwo}).should.be.fulfilled
      const newOwner = await this.daoWallet.owner()
      assert.equal(newOwner, userTwo)
      // Transfer assets
      await this.token.transfer(this.daoWallet.address, 999)
      // Balance before
      const newOwnerBalanceBefore = await this.token.balanceOf(userTwo)
      assert.equal(newOwnerBalanceBefore, 0)
      // destribute
      await this.daoWallet.destribute([this.token.address])
      // Balance after
      const newOwnerBalanceAfter = await this.token.balanceOf(userTwo)

      assert.equal(newOwnerBalanceAfter, 333)
      assert.isTrue(newOwnerBalanceAfter > newOwnerBalanceBefore)
    })

    // TODO
    // 1 destribute ether (convert to cot)
    // 1 destribute few erc
  })
})
