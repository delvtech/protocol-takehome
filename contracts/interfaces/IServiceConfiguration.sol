// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

/**
 * @title The protocol global Service Configuration
 */
interface IServiceConfiguration {


  /**
   * @dev Emitted when a liquidity asset is set.
   */
  event LiquidityAssetSet(address indexed addr, bool value);

  /**
   * @dev Emitted when the protocol is paused.
   */
  event ProtocolPaused(bool paused);






  /**
   * @dev checks if a given address has the Operator role
   */
  function isOperator(address addr) external view returns (bool);

  /**
   * @dev checks if a given address has the Deployer role
   */
  function isDeployer(address addr) external view returns (bool);

  /**
   * @dev Whether the protocol is paused.
   */
  function paused() external view returns (bool);

  /**
   * @dev Whether an address is supported as a liquidity asset.
   */
  function isLiquidityAsset(address addr) external view returns (bool);

  /**
   * @dev Sets supported liquidity assets for the protocol. Callable by the operator.
   * @param addr Address of liquidity asset
   * @param value Whether supported or not
   */
  function setLiquidityAsset(address addr, bool value) external;
  
}
