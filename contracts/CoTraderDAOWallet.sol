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
    address public COT;
    address[] public voiters;
    mapping(address => address) public mappingVote;
    address[] public tokens;

    function burn(uint256 amount) private {
      ERC20(COT).transfer(adress(0x0000000000000000000000000000000000000000));
    }


    function stake(uint256 amount) private {
      // TODO send tokens to stake reserve
    }

    function withdraw() onlyOwner {
      // TODO
      // 1/3 to owner address
      // 1/3 burn
      // 1/3 stake
    }

    function addTokenAddress(address _token){
      tokens.push(_token);
    }

    // subscribe wallet for a vote
    function subscribeForVote()public{
       voiters.push(msg.sender);
    }

    // vote for a certain candidate
    function vote(address _wallet)public{
        mappingVote[msg.sender] = _wallet;
    }

    // calculate all vote subscribers
    function calculateVoters(address _candidate)public view returns(uint256){
        uint count;
        for(uint i = 0; i<voiters.length; i++){
            // take into account current vote if this vote compare with current candidate
            if(_candidate == mappingVote[voiters[i]]){
                count ++;
            }
        }
        return count;
    }
}
