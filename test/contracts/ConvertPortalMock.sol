pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract ConvertPortalMock {
  address constant private ETH_TOKEN_ADDRESS = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
  address public cotToken;
  uint cotRatio = 3;


  constructor(address _cotToken) public {
    cotToken = _cotToken;
  }

  function isConvertibleToCOT(address _token, uint256 _amount)
  public
  view
  returns(uint256)
  {
    return _amount * cotRatio;
  }


  function isConvertibleToETH(address _token, uint256 _amount)
  public
  view
  returns(uint256)
  {
    return _amount * cotRatio;
  }

  // convert ERC to COT via Bancor network
  // return COT amount
  function convertTokentoCOT(address _token, uint256 _amount)
  public
  payable
  returns (uint256 cotAmount)
  {
     if(_token == ETH_TOKEN_ADDRESS){
       require(msg.value == _amount);
     }else{
       ERC20(_token).transferFrom(msg.sender, address(this), _amount);
     }

     cotAmount = _amount * cotRatio;
     ERC20(cotToken).transfer(msg.sender, cotAmount);
  }

  // convert ERC to ETH and then ETH to COT
  // for case if input token not in Bancor network
  // return COT amount
  function convertTokentoCOTviaETH(address _token, uint256 _amount)
  public
  returns (uint256 cotAmount)
  {
     cotAmount = _amount * cotRatio;
     ERC20(_token).transferFrom(msg.sender, address(this), _amount);
     ERC20(cotToken).transfer(msg.sender, cotAmount);
  }

}
