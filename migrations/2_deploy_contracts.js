const CoTraderDAOWallet = artifacts.require("CoTraderDAOWallet");
const Token = artifacts.require('Token');
const Stake = '0xF0089381815ED89B52FC9531bC2569c4f945079F'

module.exports = async (deployer) => {
  await deployer.deploy(Token, "TEST", "TST", 18, 100000000000)
  await deployer.deploy(CoTraderDAOWallet, Token.address, Stake);
}
