// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import '../../interfaces/IVault.sol';

/**
 * @title Interface for the PoolFactory.
 */
interface ILPAndChillFactory {
  /**
   * @dev Emitted when an LPAndChill vault is created.
   */
  event LPAndChillCreated(address indexed addr);

  /**
   * @dev Creates an LPAndChill vault.
   * @dev Emits `LPAndChillCreated` event.
   */
  function createLPAndChill(uint16, string calldata, string calldata, address, bool) external returns (address);
}
