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
import "./interfaces/IConvertPortal.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract CoTraderDAOWallet is Ownable{
  using SafeMath for uint256;
  ERC20 public COT;
  address[] public voters;
  IConvertPortal public convertPortal;
  mapping(address => address) public candidatesMap;
  ERC20 constant private ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

  address public deadAddress = address(0x000000000000000000000000000000000000dEaD);

  IStake public stake;

  constructor(address _COT, address _stake, address _convertPortal) public {
    COT = ERC20(_COT);
    stake = IStake(_stake);
    convertPortal = IConvertPortal()
  }

  function _burn(ERC20 _token, uint256 _amount) private {
    uint256 cotAmount = convertTokenToCOT(_token, _amount);
    COT.transfer(deadAddress, cotAmount);
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
     // get current token balance
     uint256 curentTokenTotalBalance = getTokenBalance(tokens[i]);
     // check if current token can be converted to COT or ETH
     bool isConvertibleToCOT = convertPortal.isConvertibleToCOT(tokens[i], curentTokenTotalBalance);
     bool isConvertibleToETH = convertPortal.isConvertibleToETH(tokens[i], curentTokenTotalBalance);
     // continue if current token can be converted to COT or ETH
     if(isConvertibleToCOT || isConvertibleToETH){
        // get a third of the balance
        uint256 thirdOfBalance = curentTokenTotalBalance.div(3);
        // continue if cur balance can be div by 3
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
  }

  function getTokenBalance(ERC20 _token) public view returns(uint256){
    if(_token == ETH_TOKEN_ADDRESS){
      return address(this).balance;
    }else{
      return _token.balanceOf(address(this));
    }
  }

  // for case if contract get some token,
  // which can't be converted to COT directly or to COT via ETH
  function withdrawNotConvertibleERC(ERC20 _token, uint256 _amount) public onlyOwner{
    require(); // this token not a ETH
    require(); // token can't be converted to COT
    require(); // token can't be converted to ETH
    _token.transfer(owner, _amount);
  }

  function convertTokenToCOT(address _token, uint256 _amount)
  private
  returns(uint256 cotAmount){
  // TODO convert token to COT via Bancor
  // step 1 check via convert portal if this token can be converted to COT
  // step 2 if can, convert
  // step 3 if can't check convert via kyber
  // if can't via kyber return 0
  return _amount;
  }

  function changeConvertPortal(address _newConvertPortal)
  public
  onlyOwner
  {
    convertPortal = IConvertPortal(_newConvertPortal);
  }


  /*
  ** VOTE LOGIC
  *
  *  users can change owner if total balance of COT for all users more than 50%
  *  of total supply COT
  */

  // register a new wallet for a vote
  function voterRegister() public {
    voters.push(msg.sender);
  }

  // vote for a certain candidate
  function vote(address _candidate) public {
    candidatesMap[msg.sender] = _candidate;
  }

  // return half of (total supply - burned balance)
  function calculateCOTSupply() public view returns(uint256){
    uint256 supply = COT.totalSupply();
    uint256 burned = COT.balanceOf(deadAddress);
    return supply.sub(burned).div(2);
  }

  // calculate all vote subscribers
  // return balance of COT for all voters of current candidate
  function calculateVoters(address _candidate)public view returns(uint256){
    uint256 count;
    for(uint i = 0; i<voters.length; i++){
      // take into account current vote balance
      // if this vote compare with current candidate
      if(_candidate == candidatesMap[voters[i]]){
          count = count.add(COT.balanceOf(voters[i]));
      }
    }
    return count;
  }

  function changeOwner(address _newOwner) public {
    uint256 totalVoters = calculateVoters(_newOwner);
    uint256 totalCOT = calculateCOTSupply();
    // require 51% COT on voters balance
    require(totalVoters > totalCOT);
    super._transferOwnership(_newOwner);
  }

}
