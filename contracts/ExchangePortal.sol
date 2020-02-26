pragma solidity ^0.4.24;

contract ExchangePortal {

  enum ExchangeType { Paraswap, Bancor }

  /**
  * @dev contructor
  *
  * @param _bancorRegistryWrapper  address of Bancor Registry Wrapper
  * @param _BancorEtherToken       address of Bancor ETH wrapper
  */
  constructor(
    address _bancorRegistryWrapper,
    address _BancorEtherToken,
    )
    public
    {

    bancorRegistry = IGetBancorAddressFromRegistry(_bancorRegistryWrapper);
    BancorEtherToken = _BancorEtherToken;
  }

  /**
  * @dev Facilitates a trade for a SmartFund
  *
  * @param _source            ERC20 token to convert from
  * @param _sourceAmount      Amount to convert from (in _source token)
  * @param _destination       ERC20 token to convert to
  * @param _type              The type of exchange to trade with
  *
  * @return The amount of _destination received from the trade
  */
  function trade(
    ERC20 _source,
    uint256 _sourceAmount,
    ERC20 _destination,
    uint256 _type
  )
    external
    payable
    tokenEnabled(_destination)
    returns (uint256)
  {

    require(_source != _destination);

    uint256 receivedAmount;

    if (_source == ETH_TOKEN_ADDRESS) {
      require(msg.value == _sourceAmount);
    } else {
      require(msg.value == 0);
    }

    if (_type == uint(ExchangeType.Kyber)) {
      receivedAmount = _tradeKyber(
        _source,
        _sourceAmount,
        _destination
      );
    }
    else if (_type == uint(ExchangeType.Bancor)){
      receivedAmount = _tradeBancor(
          _source,
          _destination,
          _sourceAmount
      );
    }
    else {
      // unknown exchange type
      revert();
    }

    // Check if Ether was received
    if (_destination == ETH_TOKEN_ADDRESS) {
      (msg.sender).transfer(receivedAmount);
    } else {
      // transfer tokens received to sender
      _destination.transfer(msg.sender, receivedAmount);
    }

    // After the trade, any _source that exchangePortal holds will be sent back to msg.sender
    uint256 endAmount = (_source == ETH_TOKEN_ADDRESS) ? this.balance : _source.balanceOf(this);

    // Check if we hold a positive amount of _source
    if (endAmount > 0) {
      if (_source == ETH_TOKEN_ADDRESS) {
        (msg.sender).transfer(endAmount);
      } else {
        _source.transfer(msg.sender, endAmount);
      }
    }

    emit Trade(msg.sender, _source, _sourceAmount, _destination, receivedAmount, uint8(_type));

    return receivedAmount;
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


 function tokenBalance(ERC20 _token) private view returns (uint256) {
   if (_token == ETH_TOKEN_ADDRESS)
     return address(this).balance;
   return _token.balanceOf(address(this));
 }
}
