/**
* This contract get 10% from CoTrader managers profit and then distributes assets
*
* 1/3 to owner of this contract (CoTrtader team)
* 1/3 convert to COT and burn
* 1/3 convert to COT and send to stake reserve
*
* NOTE: 51% CoTrader token holders can change owner of this contract
*/

pragma solidity ^0.4.24;
import "./interfaces/IStake.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract CoTraderDAOWallet is Ownable{
  using SafeMath for uint256;
  ERC20 public COT;
  address[] public voiters;
  mapping(address => address) public mappingVote;
  ERC20 constant private ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

  /* NOTE */
  // UNCOMMENT THIS AFTER UNIT TEST
  // address zeroAddress = address(0x0000000000000000000000000000000000000000);
  address public zeroAddress = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

  IStake public stake;

  constructor(address _COT, address _stake) public {
    COT = ERC20(_COT);
    stake = IStake(_stake);
  }

  function _burn(ERC20 _token, uint256 _amount) private {
    uint256 cotAmount = convertTokenToCOT(_token, _amount);
    COT.transfer(zeroAddress, cotAmount);
  }

  function _stake(ERC20 _token, uint256 _amount) private {
    uint256 cotAmount = convertTokenToCOT(_token, _amount);
    COT.approve(address(stake), cotAmount);
    stake.addReserve(cotAmount);
  }

  function _withdraw(ERC20 _token, uint256 _amount) private {
    if(_token == ETH_TOKEN_ADDRESS){
      address(owner).transfer(_amount);
    }else{
      _token.transfer(owner, _amount);
    }
  }

  function withdraw(ERC20[] tokens) {
   for(uint i = 0; i < tokens.length; i++){
     uint256 curentTokenTotalBalance = getTokenBalance(tokens[i]);
     // get a third of the balance
     uint256 thirdOfBalance = curentTokenTotalBalance.div(3);
     // do actions if cur balance can be div by 3
     if(thirdOfBalance > 0){
       // 1/3 to owner address
       _withdraw(tokens[i], thirdOfBalance);
       // 1/3 burn
       _stake(tokens[i], thirdOfBalance);
       // 1/3 stake
       _burn(tokens[i], thirdOfBalance);
     }
    }
  }

  function getTokenBalance(ERC20 _token) public view returns(uint256){
    if(_token == ETH_TOKEN_ADDRESS){
      return address(this).balance;
    }else{
      return _token.balanceOf(address(this));
    }
  }

  function convertTokenToCOT(address _token, uint256 _amount)
  private
  returns(uint256 cotAmount){
  // TODO convert token to COT via Bancor
  return _amount;
  }

  function convertTokenToETH(address _token, uint256 _amount)
  private
  returns(uint256 ethAmount){
  // TODO convert token to ETH for case if token can't be converted to COT
  return _amount;
  }

  /*
  ** VOTE LOGIC
  *
  *  users can change owner if total balance of COT for all users more then 50%
  *  of total supply COT
  */

  // subscribe wallet for a vote
  function subscribeForVote()public{
    voiters.push(msg.sender);
  }

  // vote for a certain candidate
  function vote(address _candidate)public{
    mappingVote[msg.sender] = _candidate;
  }

  // return total supply - burned balance
  function calculateCOTSupply() public view returns(uint256){
    uint256 supply = COT.totalSupply();
    uint256 burned = COT.balanceOf(zeroAddress);
    return supply.sub(burned);
  }

  // calculate all vote subscribers
  // return balance of COT for all voters of current candidate
  function calculateVoters(address _candidate)public view returns(uint256){
    uint256 count;
    for(uint i = 0; i<voiters.length; i++){
      // take into account current vote balance
      // if this vote compare with current candidate
      if(_candidate == mappingVote[voiters[i]]){
          count = count.add(COT.balanceOf(voiters[i]));
      }
    }
    return count;
  }

  function changeOwner(address _newOwner) public {
    uint256 totalVoiters = calculateVoters(_newOwner);
    uint256 totalCOT = calculateCOTSupply();
    // require 51%
    require(totalVoiters > totalCOT);
    super._transferOwnership(_newOwner);
  }

}
