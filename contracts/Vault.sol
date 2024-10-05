// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import './interfaces/IVault.sol';
import './interfaces/IServiceConfiguration.sol';
import './upgrades/BeaconImplementation.sol';
import { ERC20Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

/**
 * @title Vault holds a balance, and allows withdrawals to the Vault's owner.
 * @dev Vaults are deployed as beacon proxy contracts.
 */
contract Vault is IVault, BeaconImplementation {
  using SafeERC20 for ERC20Upgradeable;

  /**
   * @dev Reference to the global service configuration
   */
  IServiceConfiguration private _serviceConfiguration;

  /**
   * @dev Modifier to check that the protocol is not paused
   */
  modifier onlyNotPaused() {
    require(!_serviceConfiguration.paused(), 'Vault: Protocol paused');
    _;
  }

  /**
   * @dev Initialize function as a Beacon proxy implementation.
   */
  function initialize(address serviceConfiguration) public initializer {
    _serviceConfiguration = IServiceConfiguration(serviceConfiguration);
  }

  /**
   * @inheritdoc IVault
   */
  function withdrawERC20(address asset, uint256 amount, address receiver) external override onlyNotPaused {
    require(_serviceConfiguration.isOperator(msg.sender), 'LPAndChillFactory: invalid role for the caller');
    require(receiver != address(0), 'Vault: 0 address');
    ERC20Upgradeable(asset).safeTransfer(receiver, amount);
    emit WithdrewERC20(asset, amount, receiver);
  }

}
