import { BN, fromWei, toWei } from 'web3-utils'

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
const TokenMock = artifacts.require('./TokenMock')
const Stake = artifacts.require('./Stake')
const ConvertPortal = artifacts.require('./ConvertPortalMock.sol')

contract('CoTraderDAOWallet', function([userOne, userTwo, userThree]) {
  beforeEach(async function() {
    this.ETH_TOKEN_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'

    // Deploy COT Token
    this.cot = await Token.new(
      "CoTrader",
      "COT",
      18,
      toWei(String(5000000))
    )

    // Deploy COT Token
    this.testToken = await TokenMock.new(
      "TEST",
      "TST",
      18,
      toWei(String(5000000))
    )

    // Deploy Stake
    this.stake = await Stake.new(this.cot.address)

    // Deploy ConvertPortal
    this.convertPortal = await ConvertPortal.new(this.cot.address)

    // Send some amount of COT to convertPortalMock
    await this.cot.transfer(this.convertPortal.address, toWei(String(1000000)))

    // Deploy daoWallet
    this.daoWallet = await CoTraderDAOWallet.new(
      this.cot.address,
      this.stake.address,
      this.convertPortal.address)
  })

  describe('INIT', function() {
    it('Correct init CoTrader token', async function() {
      const name = await this.cot.name()
      const symbol = await this.cot.symbol()
      const decimals = await this.cot.decimals()

      assert.equal("CoTrader", name)
      assert.equal("COT", symbol)
      assert.equal(18, decimals)
    })

    it('Correct init TEST token', async function() {
      const name = await this.testToken.name()
      const symbol = await this.testToken.symbol()
      const decimals = await this.testToken.decimals()

      assert.equal("TEST", name)
      assert.equal("TST", symbol)
      assert.equal(18, decimals)
    })

    it('Correct init stake', async function() {
      const reserve = await this.stake.reserve()
      assert.equal(0, reserve)

      const token = await this.daoWallet.COT()
      assert.equal(this.cot.address, token)
    })
  })


  describe('Wallet', function() {
    it('Correct init wallet', async function() {
      const COT = await this.daoWallet.COT()
      assert.equal(this.cot.address, COT)

      const owner = await this.daoWallet.owner()
      assert.equal(userOne, owner)
    })

    it('Owner get 25% COT, stake get 25% COT, burn address get 50% COT after destribute', async function() {
      await this.cot.transfer(this.daoWallet.address, toWei(String(100)))
      // balance before destribute
      const ownerBalanceBefore = await this.cot.balanceOf(userOne)
      await this.daoWallet.destribute([this.cot.address])
      // balance after destribute
      const ownerBalanceAfter = await this.cot.balanceOf(userOne)

      const burnAddress = await this.daoWallet.deadAddress()
      const stakeBalance = await this.cot.balanceOf(this.stake.address)
      const burnBalance = await this.cot.balanceOf(burnAddress)

      const ownerEarn = ownerBalanceAfter - ownerBalanceBefore

      assert.equal(parseInt(fromWei(String(ownerEarn)), 10), 25)
      assert.equal(parseInt(fromWei(String(stakeBalance)), 10), 25)
      assert.equal(parseInt(fromWei(String(burnBalance)), 10), 50)
    })

    it('Owner get 25% COT, stake get 25% COT, burn address get 50% COT after destribute not equal amount', async function() {
      await this.cot.transfer(this.daoWallet.address, toWei(String(99)))
      // balance before destribute
      const ownerBalanceBefore = await this.cot.balanceOf(userOne)
      await this.daoWallet.destribute([this.cot.address])
      // balance after destribute
      const ownerBalanceAfter = await this.cot.balanceOf(userOne)

      const burnAddress = await this.daoWallet.deadAddress()
      const stakeBalance = await this.cot.balanceOf(this.stake.address)
      const burnBalance = await this.cot.balanceOf(burnAddress)

      const ownerEarn = ownerBalanceAfter - ownerBalanceBefore

      assert.equal(parseInt(fromWei(String(ownerEarn)), 10), 24)
      assert.equal(parseInt(fromWei(String(stakeBalance)), 10), 24)
      assert.equal(parseInt(fromWei(String(burnBalance)), 10), 49)
    })

    it('Owner get 25% ETH, stake get 25% COT from ETH, burn address get 50% COT from ETH after destribute', async function() {
      const ownerBalanceBefore = await web3.eth.getBalance(userOne)

      // send ETH to DAO wallet from userTwo
      await this.daoWallet.sendTransaction({
        value: toWei(String(10)),
        from: userTwo
      });

      let DaoWalletBalance = await web3.eth.getBalance(this.daoWallet.address);
      assert.equal(fromWei(String(DaoWalletBalance)), 10)

      await this.daoWallet.destribute([this.ETH_TOKEN_ADDRESS], { from:userTwo })

      DaoWalletBalance = await web3.eth.getBalance(this.daoWallet.address)
      assert.equal(DaoWalletBalance, 0)

      const ownerBalanceAfter = await web3.eth.getBalance(userOne)

      // owner get 25% ETH
      assert.equal(fromWei(String(ownerBalanceAfter)) - fromWei(String(ownerBalanceBefore)), 2.5)
      // stake get 25% ETH in COT (1 ETH = 3 COT)
      assert.equal(fromWei(await this.cot.balanceOf(this.stake.address)), 2.5 * 3)

      const burnAddress = await this.daoWallet.deadAddress()
      // burn get 50% ETH in COT
      assert.equal(fromWei(await this.cot.balanceOf(burnAddress)), 5 * 3)
    })

    it('Owner get 25% TST, stake get 25% COT from TST and burn address get 50% COT from TST after destribute', async function() {
      await this.testToken.transfer(this.daoWallet.address, toWei(String(500)))
      // balance before destribute
      const ownerBalanceBefore = await this.testToken.balanceOf(userOne)
      await this.daoWallet.destribute([this.testToken.address])
      // balance after destribute
      const ownerBalanceAfter = await this.testToken.balanceOf(userOne)

      const burnAddress = await this.daoWallet.deadAddress()
      const stakeBalance = await this.cot.balanceOf(this.stake.address)
      const burnBalance = await this.cot.balanceOf(burnAddress)

      const ownerEarn = ownerBalanceAfter - ownerBalanceBefore

      assert.equal(parseInt(fromWei(String(ownerEarn)), 10), 125)
      assert.equal(parseInt(fromWei(String(stakeBalance)), 10), 125 * 3) // 1 TST = 3 COT
      assert.equal(parseInt(fromWei(String(burnBalance)) ,10), 250 * 3) // 1 TST = 3 COT
    })

    it('destribute COT, ETH, and TST token', async function() {
      // transfer COT token to DAO wallet
      await this.cot.transfer(this.daoWallet.address, toWei(String(10)))
      // transfer test token to DAO wallet
      await this.testToken.transfer(this.daoWallet.address, toWei(String(10)))
      // transfer ETH to DAO wallet
      // transfer from user two for correct calcualte owner wei
      await this.daoWallet.sendTransaction({
        value: toWei(String(10)),
        from: userTwo
      });

      // Owner balance before destribute
      const ownerBalanceTSTBefore = await this.testToken.balanceOf(userOne)
      const ownerBalanceCOTBefore = await this.cot.balanceOf(userOne)
      const ownerBalanceETHBefore = await web3.eth.getBalance(userOne)

      const burnAddress = await this.daoWallet.deadAddress()

      // destribute
      // NOTE: any user can execude destribute
      await this.daoWallet.destribute(
         [this.cot.address,
         this.testToken.address,
         this.ETH_TOKEN_ADDRESS], {from:userTwo})

      // check stake and burn address
      const stakeBalanceAfter = await this.cot.balanceOf(this.stake.address)
      const burnBalanceAfter = await this.cot.balanceOf(burnAddress)

      // calculate stake and burn
      // 25% COT = 2.5, 25% ETH = 2.5 * 3, 25% TST = 2.5 * 3
      assert.equal(fromWei(String(stakeBalanceAfter)), 2.5+7.5+7.5)
      // 50% COT = 5, 50% ETH = 5 * 3, 50% TST = 5 * 3
      assert.equal(fromWei(String(burnBalanceAfter)), 5+5*3+5*3)

      // check owner balance after distribute
      const ownerBalanceTSTAfter = await this.testToken.balanceOf(userOne)
      const ownerBalanceCOTAfter = await this.cot.balanceOf(userOne)
      const ownerBalanceETHAfter = await web3.eth.getBalance(userOne)

      const ownerTSTEarn = ownerBalanceTSTAfter - ownerBalanceTSTBefore
      const ownerCOTEarn = ownerBalanceCOTAfter - ownerBalanceCOTBefore
      const ownerETHEarn = ownerBalanceETHAfter - ownerBalanceETHBefore

      // calculate owner earn (for owner we not convert assets to COT)
      // TST
      assert.equal(Number(fromWei(String(ownerTSTEarn))).toFixed(8), 2.5)
      // COT
      assert.equal(Number(fromWei(String(ownerCOTEarn))).toFixed(8), 2.5)
      // ETH
      assert.isTrue(ownerBalanceETHAfter > ownerBalanceETHBefore)

      // DAO wallet balance should be 0 after distribute
      const DAOCOTBalance = await this.cot.balanceOf(this.daoWallet.address)
      const DAOTSTBalance = await this.testToken.balanceOf(this.daoWallet.address)
      const DAOETHBalance = await await web3.eth.getBalance(this.daoWallet.address)

      assert.equal(DAOCOTBalance, 0)
      assert.equal(DAOTSTBalance, 0)
      assert.equal(DAOETHBalance, 0)
    })
  })


  describe('Vote', function() {
    it('User can not register the same wallet address for vote twice', async function() {
      await this.daoWallet.voterRegister({from: userOne}).should.be.fulfilled
      await this.daoWallet.voterRegister({from: userOne}).should.be.rejectedWith(EVMRevert)
    })


    it('User can not change owner if there are no 51% COT supply', async function() {
      await this.daoWallet.voterRegister({from: userTwo})
      await this.daoWallet.vote(userTwo, {from: userTwo})
      await this.daoWallet.changeOwner(userTwo).should.be.rejectedWith(EVMRevert)
    })

    it('User can not change owner if user vote, but then transfer balance', async function() {
      await this.daoWallet.voterRegister({from: userOne})
      await this.daoWallet.vote(userTwo, {from: userOne})
      const userOneBalance = await this.cot.balanceOf(userOne)
      await this.cot.transfer(userTwo, userOneBalance)
      await this.daoWallet.changeOwner(userTwo, {from: userTwo}).should.be.rejectedWith(EVMRevert)
    })

    it('User can not change owner if there are only 50% COT supply', async function() {
      // transfer 50% tokens
      const totalSupply = await this.cot.totalSupply()
      const halfSupply = fromWei(String(totalSupply)) / 2
      await this.cot.transfer(userThree, toWei(String(halfSupply)))

      // vote from userThree with 50% balance
      await this.daoWallet.voterRegister({from: userThree})
      await this.daoWallet.vote(userTwo, {from: userThree})
      await this.daoWallet.changeOwner(userTwo, {from: userTwo}).should.be.rejectedWith(EVMRevert)
    })

    it('User can change owner if there are 51% of COT supply', async function() {
      assert.equal(await await this.daoWallet.owner(), userOne)
      // transfer 50% tokens to userTwo
      const totalSupply = await this.cot.totalSupply()
      const halfSupply = fromWei(String(totalSupply)) / 2
      await this.cot.transfer(userTwo, toWei(String(halfSupply)))

      // vote from user two
      await this.daoWallet.voterRegister({from: userTwo})
      await this.daoWallet.vote(userTwo, {from: userTwo})

      // execude change owner
      // should fails because there are no 51%
      await this.daoWallet.changeOwner(userTwo, {from: userTwo}).should.be.rejectedWith(EVMRevert)

      // transfer 1 wei to userThree for make 51%
      await this.cot.transfer(userThree, 1)
      // vote from user three
      await this.daoWallet.voterRegister({from: userThree})
      await this.daoWallet.vote(userTwo, {from: userThree})

      // execude change owner
      await this.daoWallet.changeOwner(userTwo, {from: userTwo}).should.be.fulfilled
      assert.equal(await await this.daoWallet.owner(), userTwo)
    })

    it('new owner get 25% after destribute', async function() {
      // Change owner
      await this.daoWallet.voterRegister({from: userOne})
      await this.daoWallet.vote(userTwo, {from: userOne})
      await this.daoWallet.changeOwner(userTwo, {from: userTwo}).should.be.fulfilled
      const newOwner = await this.daoWallet.owner()
      assert.equal(newOwner, userTwo)
      // Transfer assets
      await this.cot.transfer(this.daoWallet.address, 100)
      // Balance before
      const newOwnerBalanceBefore = await this.cot.balanceOf(userTwo)
      assert.equal(newOwnerBalanceBefore, 0)
      // destribute
      await this.daoWallet.destribute([this.cot.address])
      // Balance after
      const newOwnerBalanceAfter = await this.cot.balanceOf(userTwo)

      assert.equal(newOwnerBalanceAfter, 25)
      assert.isTrue(newOwnerBalanceAfter > newOwnerBalanceBefore)
    })

    it('Owner can not call withdrawNonConvertibleERC if this ERC convertible', async function() {
      await this.testToken.transfer(this.daoWallet.address, 5000000)
      await this.daoWallet.withdrawNonConvertibleERC(this.testToken.address, 5000000)
      .should.be.rejectedWith(EVMRevert)
    })

    it('Owner can call withdrawNonConvertibleERC and get this ERC if this ERC non convertible', async function() {
      await this.convertPortal.disallowConvertToCOT()
      await this.convertPortal.disallowConvertToETH()
      const tstSupply = await this.testToken.totalSupply()
      // transfer ALL TST tokens to DAO wallet
      await this.testToken.transfer(this.daoWallet.address, tstSupply)
      assert.equal(await this.testToken.balanceOf(userOne), 0)

      // get back tokens
      await this.daoWallet.withdrawNonConvertibleERC(this.testToken.address, tstSupply)
      .should.be.fulfilled
      const ownerBalance = await this.testToken.balanceOf(userOne)
      assert.equal(fromWei(String(ownerBalance)), fromWei(String(tstSupply)))
    })

    it('Not owner can NOT call withdrawNonConvertibleERC and get this ERC if this ERC non convertible', async function() {
      await this.convertPortal.disallowConvertToCOT()
      await this.convertPortal.disallowConvertToETH()
      await this.testToken.transfer(this.daoWallet.address, 5000000)
      await this.daoWallet.withdrawNonConvertibleERC(this.testToken.address, 5000000, {from: userTwo})
      .should.be.rejectedWith(EVMRevert)
    })
  })
})
