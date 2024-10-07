// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

/**
 * @title Interface for the VaultFactory.
 */
interface IVaultFactory {
  /**
   * @dev Emitted when a vault is created.
   */
  event VaultCreated(address indexed);

  /**
   * @dev Creates a new vault.
   * @dev Emits a `VaultCreated` event.
   */
  function createVault() external returns (address);
}
