// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import './interfaces/IServiceConfiguration.sol';
import './upgrades/DeployerUUPSUpgradeable.sol';

/**
 * @title The ServiceConfiguration contract
 * @dev Implementation of the {IServiceConfiguration} interface.
 */
contract ServiceConfiguration is IServiceConfiguration, AccessControlUpgradeable, DeployerUUPSUpgradeable {
  /**
   * @dev The Operator Role
   */
  bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

  /**
   * @dev The Deployer Role
   */
  bytes32 public constant DEPLOYER_ROLE = keccak256('DEPLOYER_ROLE');

  /**
   * @inheritdoc IServiceConfiguration
   */
  bool public paused;

  /**
   * @inheritdoc IServiceConfiguration
   */
  mapping(address => bool) public isLiquidityAsset;


  /**
   * @dev Modifier that checks that the caller account has the Operator role.
   */
  modifier onlyOperator() {
    require(hasRole(OPERATOR_ROLE, msg.sender), 'ServiceConfiguration: caller is not an operator');
    _;
  }




  /**
   * @dev Constructor for the contract, which sets up the default roles and
   * owners.
   */
  function initialize() public initializer {
    // Initialize values
    paused = false;
    _serviceConfiguration = IServiceConfiguration(address(this));

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /**
   * @dev Set a liquidity asset as valid or not.
   */
  function setLiquidityAsset(address addr, bool value) public override onlyOperator {
    isLiquidityAsset[addr] = value;
    emit LiquidityAssetSet(addr, value);
  }

  /**
   * @dev Pause/unpause the protocol.
   */
  function setPaused(bool paused_) public onlyOperator {
    paused = paused_;
    emit ProtocolPaused(paused);
  }

  /**
   * @inheritdoc IServiceConfiguration
   */
  function isOperator(address addr) external view returns (bool) {
    return hasRole(OPERATOR_ROLE, addr);
  }

  /**
   * @inheritdoc IServiceConfiguration
   */
  function isDeployer(address addr) external view returns (bool) {
    return hasRole(DEPLOYER_ROLE, addr);
  }

}
