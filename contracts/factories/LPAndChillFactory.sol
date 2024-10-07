// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import '../LPAndChill.sol';
import '../interfaces/IServiceConfiguration.sol';
import {ILPAndChillFactory} from './interfaces/ILPAndChillFactory.sol';
import { BeaconProxy } from '@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol';
import '../upgrades/BeaconProxyFactory.sol';

/**
 * @title A factory that emits Pool contracts.
 * @dev Acts as a beacon contract, emitting beacon proxies and holding a reference
 * to their implementation contract.
 */
contract LPAndChillFactory is ILPAndChillFactory, BeaconProxyFactory {
  /**
   * @dev Reference to the VaultFactory contract
   */
  address internal _vaultFactory;

  /**
   * @dev Constructor
   * @param serviceConfiguration Reference to the global service configuration.
   * @param vaultFactory Reference to the Vault factory.
   */
  constructor(
    address serviceConfiguration,
    address vaultFactory
  ) {
    _serviceConfiguration = IServiceConfiguration(serviceConfiguration);
    _vaultFactory = vaultFactory;
  }

  /**
   * @inheritdoc ILPAndChillFactory
   */
  function createLPAndChill(
    uint16 _serviceFeeBps,
    string calldata _name,
    string calldata _symbol,
    address _hyperdrive,
    bool _asBase
  ) public virtual returns (address lpAndChillAddress) {
    require(_serviceConfiguration.isOperator(msg.sender), 'LPAndChillFactory: invalid role for the caller');
    require(implementation != address(0), 'LPAndChillFactory: no implementation set');
    require(_serviceConfiguration.paused() == false, 'LPAndChillFactory: Protocol paused');
    

    // Create the lpAndChill
    lpAndChillAddress = initializeLPAndChill(_serviceFeeBps, _name, _symbol, _hyperdrive, _asBase);
    emit LPAndChillCreated(lpAndChillAddress);
    return lpAndChillAddress;
  }

  /**
   * @dev Creates the new Pool contract.
   */
  function initializeLPAndChill(
    uint16 _serviceFeeBps,
    string calldata _name,
    string calldata _symbol,
    address _hyperdrive,
    bool _asBase
  ) internal virtual returns (address) {
    // Create beacon proxy
    BeaconProxy proxy = new BeaconProxy(
      address(this),
      abi.encodeWithSelector(
        LPAndChill.initialize.selector,
        _serviceConfiguration,
        _vaultFactory,
        _serviceFeeBps,
        _name,
        _symbol,
        _hyperdrive,
        _asBase
      )
    );
    return address(proxy);
  }
}
