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

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract COTDAOVote is Ownable{
    using SafeMath for uint256;
    ERC20 public COT;
    address[] public voiters;
    mapping(address => address) public mappingVote;

    function burn(uint256 amount) private {
      COT.transfer(adress(0x0000000000000000000000000000000000000000));
    }

    function stake(uint256 amount) private {
      // TODO send tokens to stake reserve
    }

    function withdraw(ERC20[] tokens) onlyOwner {
      // TODO
      // 1/3 to owner address
      // 1/3 burn
      // 1/3 stake
    }

    function convertTokenToCOT(address _token, uint256 _amount)
    private
    returns(uint256 cotAmount){
      // TODO convert token to COT via Bancor
      return 0;
    }

    function convertTokenToETH(address _token, uint256 _amount)
    private
    returns(uint256 ethAmount){
      // TODO convert token to ETH for case if token can't be converted to COT
      return 0;
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
      uint256 burned = COT.balanceOf(adress(0x0000000000000000000000000000000000000000));
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
