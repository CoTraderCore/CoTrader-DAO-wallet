pragma solidity ^0.4.24;

import "./interfaces/IGetBancorAddressFromRegistry.sol";
import "./interfaces/BancorNetworkInterface.sol";
import "./interfaces/PathFinderInterface.sol";
import "./interfaces/KyberNetworkInterface.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";


contract ConvertPortal {
  address public BancorEtherToken;
  IGetBancorAddressFromRegistry public bancorRegistry;
  KyberNetworkInterface public kyber;
  address public cotToken;

  /**
  * @dev contructor
  *
  * @param _bancorRegistryWrapper  address of Bancor Registry Wrapper
  * @param _BancorEtherToken       address of Bancor ETH wrapper
  * @param _kyber                  address of KyberNetwork
  * @param _cotToken                    address of CoTrader erc20
  */
  constructor(
    address _bancorRegistryWrapper,
    address _BancorEtherToken,
    address _kyber,
    address _cotToken
    )
    public
  {
    bancorRegistry = IGetBancorAddressFromRegistry(_bancorRegistryWrapper);
    BancorEtherToken = _BancorEtherToken;
    kyber = KyberNetworkInterface(_kyber);
    cotToken = _cotToken;
  }

  // check
  function isConvertibleToCOT(address _token, uint256 _amount)
  public
  view
  returns(bool)
  {

  }

  function isConvertibleToETH(address _token, uint256 _amount)
  public
  view
  returns(bool)
  {

  }

  // convert ERC to COT via Bancor network
  // return COT amount
  function convertTokentoCOT(address _token, uint256 _amount)
  public
  returns (uint256 cotAmount)
  {
    // get COT
    cotAmount = _tradeBancor(
        _token,
        _cotToken,
        _amount
    );
    // send COT back to sender
    ERC20(cotToken).transfer(msg.sender, cotAmount);
    // After the trade, any amount of input token will be sent back to msg.sender
    uint256 endAmount = (_token == ETH_TOKEN_ADDRESS)
    ? address(this).balance
    : ERC20(_token).balanceOf(address(this));

    // Check if we hold a positive amount of _source
    if (endAmount > 0) {
      if (_token == ETH_TOKEN_ADDRESS) {
        (msg.sender).transfer(endAmount);
      } else {
        ERC20(_token).transfer(msg.sender, endAmount);
      }
    }
  }

  // convert ERC to ETH and then ETH to COT
  // for case if input token not in Bancor network
  // return COT amount
  function convertTokentoCOTviaETH(address _token, uint256 _amount)
  public
  returns (uint256 cotAmount)
  {
    // convert token to ETH via kyber
    uint256 receivedETH = _tradeKyber(
        _token,
        ETH_TOKEN_ADDRESS,
        _amount
    );

    // convert ETH to COT via bancor
    cotAmount = _tradeBancor(
        ETH_TOKEN_ADDRESS,
        _cotToken,
        receivedETH
    );

    // send COT back to sender
    ERC20(cotToken).transfer(msg.sender, cotAmount);

    // check if there are remains some amount of token and eth, then send back to sender
    uint256 endAmountOfERC = ERC20(_token).balanceOf(address(this));
    uint256 endAmountOfETH = address(this).balance;

    if(endAmountOfETH > 0)
      (msg.sender).transfer(endAmount);
    if(endAmountOfERC > 0)
      ERC20(_token).transfer(msg.sender, endAmount);
  }


 // Facilitates trade with Bancor
 function _tradeKyber(
   ERC20 _source,
   uint256 _sourceAmount,
   ERC20 _destination
 )
   private
   returns (uint256)
 {
   uint256 destinationReceived;
   uint256 _maxDestinationAmount = 2**256-1;
   uint256 _minConversionRate = 1;
   address _walletId = address(0x0000000000000000000000000000000000000000);

   if (_source == ETH_TOKEN_ADDRESS) {
     destinationReceived = kyber.trade.value(_sourceAmount)(
       _source,
       _sourceAmount,
       _destination,
       this,
       _maxDestinationAmount,
       _minConversionRate,
       _walletId
     );
   } else {
     _transferFromSenderAndApproveTo(_source, _sourceAmount, kyber);
     destinationReceived = kyber.trade(
       _source,
       _sourceAmount,
       _destination,
       this,
       _maxDestinationAmount,
       _minConversionRate,
       _walletId
     );
   }

   return destinationReceived;
 }

 // Facilitates trade with Bancor
 function _tradeBancor(
   address sourceToken,
   address destinationToken,
   uint256 sourceAmount
   )
   private
   returns(uint256 returnAmount)
 {
    // get latest bancor contracts
    BancorNetworkInterface bancorNetwork = BancorNetworkInterface(
      bancorRegistry.getBancorContractAddresByName("BancorNetwork")
    );

    PathFinderInterface pathFinder = PathFinderInterface(
      bancorRegistry.getBancorContractAddresByName("BancorNetworkPathFinder")
    );

    // Change source and destination to Bancor ETH wrapper
    address source = ERC20(sourceToken) == ETH_TOKEN_ADDRESS ? BancorEtherToken : sourceToken;
    address destination = ERC20(destinationToken) == ETH_TOKEN_ADDRESS ? BancorEtherToken : destinationToken;

    // Get Bancor tokens path
    address[] memory path = pathFinder.generatePath(source, destination);

    // Convert addresses to ERC20
    ERC20[] memory pathInERC20 = new ERC20[](path.length);
    for(uint i=0; i<path.length; i++){
        pathInERC20[i] = ERC20(path[i]);
    }

    // trade
    if (ERC20(sourceToken) == ETH_TOKEN_ADDRESS) {
      returnAmount = bancorNetwork.convert.value(sourceAmount)(pathInERC20, sourceAmount, 1);
    }
    else {
      _transferFromSenderAndApproveTo(ERC20(sourceToken), sourceAmount, address(bancorNetwork));
      returnAmount = bancorNetwork.claimAndConvert(pathInERC20, sourceAmount, 1);
    }
 }
}
