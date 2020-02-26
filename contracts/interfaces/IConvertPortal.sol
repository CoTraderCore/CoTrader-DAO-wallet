contract IConvertPortal {
  function isConvertibleToCOT(address _token, uint256 _amount)
  public
  view
  returns(bool)

  function isConvertibleToETH(address _token, uint256 _amount)
  public
  view
  returns(bool)
  
  function convertTokentoCOT(address _token, uint256 _amount)
  public
  returns (uint256 cotAmount);

  function convertTokentoCOTviaETH(address _token, uint256 _amount)
  public
  returns (uint256 cotAmount);
}
