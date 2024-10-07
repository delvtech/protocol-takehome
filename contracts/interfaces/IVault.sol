// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

/**
 * @title Interface for the Vault.
 * @dev Vaults simply hold a balance, and allow withdrawals by the Vault's owner.
 */
interface IVault {
  /**
   * @dev Emitted on ERC20 withdrawals
   */
  event WithdrewERC20(address indexed asset, uint256 amount, address indexed receiver);

  /**
   * @dev Withdraws ERC20 of a given asset
   */
  function withdrawERC20(address asset, uint256 amount, address receiver) external;


}
