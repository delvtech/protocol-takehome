// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.22;

import {IERC20} from "hyperdrive/src/interfaces/IERC20.sol";
import {IHyperdrive} from "hyperdrive/src/interfaces/IHyperdrive.sol";
import {HyperdriveMath} from "hyperdrive/src/libraries/HyperdriveMath.sol";
import {ERC4626} from "solady/tokens/ERC4626.sol";
import './upgrades/BeaconImplementation.sol';
import {IServiceConfiguration} from './interfaces/IServiceConfiguration.sol';
import {IVault} from './interfaces/IVault.sol';
import {IVaultFactory} from './factories/interfaces/IVaultFactory.sol';
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { FixedPointMath, ONE } from "hyperdrive/src/libraries/FixedPointMath.sol";

/// @author DELV
/// @title Momo
/// @notice A principal protected vault powered by Hyperdrive. This vault gives
///         multiplied exposure by taking advantage of fixed rate spreads.
/// @custom:disclaimer The language used in this code is for coding convenience
///                    only, and is not intended to, and does not, have any
///                    particular legal or regulatory significance.
contract LPAndChill is ERC4626, BeaconImplementation {
    using SafeERC20 for IERC20;
    using HyperdriveMath for uint256;
    // ╭─────────────────────────────────────────────────────────╮
    // │ Storage                                                 │
    // ╰─────────────────────────────────────────────────────────╯

    // ───────────────────────── Immutables ──────────────────────

    // ───────────────────────── Constants ──────────────────────
    uint16 public constant MAX_BPS = 10_000;
    uint16 public constant MAX_SERVICE_FEE_BPS = 3_000; // 30%


    // ─────────────────────────── State ────────────────────────

    /// @dev A flag indicating whether or not deposits and withdrawals should
    ///      be processed in base or vault shares.
    bool public asBase;

    /// @dev The asset underlying all of the investments.
    IERC20 internal _asset;

    /// @dev The service fee in basis points.
    uint16 public serviceFeeBps;

    /// @dev The name of the LPAndChill token.
    string internal _name;

    /// @dev The symbol of the LPAndChill token.
    string internal _symbol;

    /// @notice The Hyperdrive pool.
    IHyperdrive public hyperdrive;

    
    /// @dev Reference to the global service configuration.
    IServiceConfiguration private _serviceConfiguration;

    /// @dev A vault holding service fees collected from users.
    IVault private _feeVault;

    /// @notice The different types of tokens in the system.
    enum TokenType {
        LP,
        LONG,
        SHORT,
        WITHDRAWAL_SHARE
    }


    // ╭─────────────────────────────────────────────────────────╮
    // │ Initializer                                             │
    // ╰─────────────────────────────────────────────────────────╯

    /// @notice Initializes the LPAndChill vault.
    /// @param __serviceConfiguration The service configuration.
    /// @param _vaultFactory The vault factory.
    /// @param _serviceFeeBps The service fee in basis points.
    /// @param __name Name of the LPAndChill vault token.
    /// @param __symbol Symbol of the LPAndChill vault token.
    /// @param _hyperdrive The Hyperdrive pool to invest into.
    /// @param _asBase A flag indicating whether to deposit and withdraw using
    ///        base or vault shares.
    function initialize(
        address __serviceConfiguration,
        address _vaultFactory,
        uint16 _serviceFeeBps,
        string memory __name,
        string memory __symbol,
        IHyperdrive _hyperdrive,
        bool _asBase
    ) public initializer {
        require(_serviceFeeBps <= MAX_SERVICE_FEE_BPS, 'LPAndChill: service fee too high');

        // Set the name and symbol.
        _name = __name;
        _symbol = __symbol;

        // Set the Hyperdrive pool.
        hyperdrive = _hyperdrive;

        // Set the asset and asBase.
        if (_asBase) {
            _asset = IERC20(_hyperdrive.baseToken());
        } else {
            _asset = IERC20(_hyperdrive.vaultSharesToken());
        }
        asBase = _asBase;

        _serviceConfiguration = IServiceConfiguration(__serviceConfiguration);

        // Precaucious security measure: Only asset registered in ServiceConfiguration can be used!
        require(_serviceConfiguration.isLiquidityAsset(address(_asset)), 'LPAndChillVault: invalid asset');

        // Create the fee vault
        _feeVault = IVault(IVaultFactory(_vaultFactory).createVault());
        serviceFeeBps = _serviceFeeBps;
    }


    // ╭─────────────────────────────────────────────────────────╮
    // │ Stateful                                                │
    // ╰─────────────────────────────────────────────────────────╯

    // ───────────────────────── ERC4626 ─────────────────────────

    // FIXME: You'll need to implement the appropriate functions for `deposit`
    //        and `mint` to invest their funds into Hyperdrive LP positions and
    //        for `withdraw` and `redeem` to remove funds from the existing LP
    //        positions. Pay special attention to the share price mechanism that
    //        already exists within Hyperdrive. You can use
    //        `hyperdrive.getPoolInfo().lpSharePrice` to get the share price. Be
    //        aware that this share price can slip when there are existing long
    //        and short positions open on Hyperdrive.

    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        require(assets > 0, 'LPAndChill: deposit amount is zero');
        require(assets <= _asset.balanceOf(msg.sender), 'LPAndChill: deposit amount exceeds balance');
        require(assets <= _asset.allowance(msg.sender, address(this)), 'LPAndChill: deposit amount exceeds allowance');
        require(receiver != address(0), 'LPAndChill: receiver is zero address');

        // Calculate the fee
        uint256 fee = (assets * serviceFeeBps) / MAX_BPS;
        uint256 assetsAfterFee = assets - fee;

        // Transfer the fee to the fee vault
        if (fee > 0) {
            require(_asset.transferFrom(msg.sender, address(_feeVault), fee), 'LPAndChill: transfer fee failed');
        }

        // Deposit the remaining assets and mint shares
        shares = super.deposit(assetsAfterFee, receiver);
        require(shares > 0, 'LPAndChill: shares amount rounded to zero');

        // Invest the assets after fee into Hyperdrive
        _investInHyperdrive(assetsAfterFee);
    }

    function mint(uint256 shares, address receiver) public override returns (uint256 assets) {
        require(shares > 0, 'LPAndChill: mint amount is zero');
        require(receiver != address(0), 'LPAndChill: receiver is zero address');

        uint256 previewAssets = super.previewMint(shares);
        require(previewAssets <= _asset.balanceOf(msg.sender), 'LPAndChill: mint amount exceeds balance');
        require(previewAssets <= _asset.allowance(msg.sender, address(this)), 'LPAndChill: mint amount exceeds allowance');

        // Calculate the fee
        uint256 feeShares = (shares * serviceFeeBps) / MAX_BPS;
        uint256 assetsForFee = super.previewMint(feeShares);
        uint256 sharesAfterFee = shares - feeShares;

        // Transfer the fee to the fee vault
        if (assetsForFee > 0) {
            require(_asset.transferFrom(msg.sender, address(_feeVault), assetsForFee), 'LPAndChill: transfer fee failed');
        }

        assets = super.mint(sharesAfterFee, receiver);
        require(assets > 0, 'LPAndChill: assets amount rounded to zero');

        _investInHyperdrive(assets);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256 shares) {
        require(assets > 0, 'LPAndChill: withdraw amount is zero');
        require(receiver != address(0), 'LPAndChill: receiver is zero address');
        require(owner == msg.sender, 'LPAndChill: invalid owner'); // Sean: Not allowing the owner to be someone else

        // Calculate shares to burn without actually burning them yet
        shares = super.previewWithdraw(assets);
        require(shares > 0, 'LPAndChill: shares amount rounded to zero');
        require(shares <= balanceOf(owner), 'LPAndChill: withdraw amount exceeds balance');
        require(shares <= allowance(owner, address(this)), 'LPAndChill: withdraw amount exceeds allowance');

        // Remove liquidity from Hyperdrive first
        uint256 proceeds = _removeFromHyperdrive(assets);

        // Now perform the actual withdrawal using the proceeds
        shares = super.withdraw(proceeds, receiver, owner);

        emit Withdraw(msg.sender, receiver, owner, proceeds, shares);
        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256 assets) {
        require(shares > 0, 'LPAndChill: redeem amount is zero');
        require(receiver != address(0), 'LPAndChill: receiver is zero address');
        require(owner == msg.sender, 'LPAndChill: invalid owner');

        // Calculate assets without actually burning shares yet
        assets = super.previewRedeem(shares);
        require(assets > 0, 'LPAndChill: assets amount rounded to zero');
        require(shares <= balanceOf(owner), 'LPAndChill: redeem amount exceeds balance');
        require(shares <= allowance(owner, address(this)), 'LPAndChill: redeem amount exceeds allowance');

        // Remove liquidity from Hyperdrive first
        uint256 proceeds = _removeFromHyperdrive(assets);

        // Now perform the actual redemption using the proceeds
        // Sean: Still using super.withdraw() with the proceeds amount is OK, instead of
        //      super.redeem() with the shares amount.  
        shares = super.withdraw(proceeds, receiver, owner);

        emit Withdraw(msg.sender, receiver, owner, proceeds, shares);
        return assets;
    }


    // ╭─────────────────────────────────────────────────────────╮
    // │ Getters                                                 │
    // ╰─────────────────────────────────────────────────────────╯

    // ───────────────────────── ERC20 ───────────────────────────

    /// @notice Returns the name of the LPAndChill token.
    /// @return The name of the LPAndChill token.
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @notice Returns the symbol of the LPAndChill token.
    /// @return The symbol of the LPAndChill token.
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /// @notice Returns the decimals places of the LPAndChill token.
    /// @return The LPAndChill token decimals.
    function decimals() public view override returns (uint8) {
        return _asset.decimals();
    }

    // ───────────────────────── ERC4626 ─────────────────────────

    /// @notice Returns the asset underlying all of the investments.
    /// @return The asset.
    function asset() public view override returns (address) {
        return address(_asset);
    }

    /// @notice Returns the total value of LPAndChill's portfolio measured in the
    ///         underlying asset.
    /// @return The total value of LPAndChill's portfolio.
    function totalAssets() public view override returns (uint256) {
        // FIXME: This needs to be updated.

        // Sean: In most of the time, the LPAndChill vault is only holding 1 type of token,
        //      which is the lpShare token. However, there is an edge case like during the
        //      mid of a withdrawal, when the asset token has been moved from Hyperdrive pool
        //      to here but not yet transfered to the user, at this moment the totalAssets()
        //      should account for both types of tokens.

        // Part 1: the balance of the _asset, sometimes it's not zero
        uint256 assetBalance = _asset.balanceOf(address(this));

        // Part 2: calculate the value of the lpShare tokens
        // Sean: when asBase, the totalAssets is in terms of base tokens;
        //      when !asBase, the totalAssets is in terms of vault shares;
        //      Note that the price variables here are all scaled up by 1e18;
        IHyperdrive.PoolInfo memory poolInfo = hyperdrive.getPoolInfo();
        uint256 lpBalance = hyperdrive.balanceOf(uint256(TokenType.LP), address(this));
    
        if (asBase) {
            return FixedPointMath.mulDivDown(lpBalance, poolInfo.lpSharePrice, ONE) + assetBalance;
        } else {
            return FixedPointMath.mulDivDown(lpBalance,poolInfo.lpSharePrice, poolInfo.vaultSharePrice) + assetBalance;
        }
    }

    /// @dev The number of decimals of the underlying asset.
    /// @return The number of underlying decimals.
    function _underlyingDecimals() internal view override returns (uint8) {
        return decimals();
    }

    /// @dev The number of decimals of the virtual shares. This helps to avoid
    ///      inflation attacks.
    function _decimalsOffset() internal view override returns (uint8) {
        uint8 decimals_ = decimals();
        return decimals_ > 6 ? decimals_ - 3 : decimals_;
    }

    // ───────────────────────── Privileged  ──────────────────────

    /// @notice Sets the service fee in basis points.
    /// @param _serviceFeeBps The service fee in basis points.
    function setServiceFeeBps(uint16 _serviceFeeBps) external {
        require(_serviceConfiguration.isOperator(msg.sender), 'LPAndChill: invalid role for the caller');
        require(_serviceFeeBps <= MAX_SERVICE_FEE_BPS, 'LPAndChill: service fee too high');
        serviceFeeBps = _serviceFeeBps;
    }

    // ───────────────────────── Hyperdrive ───────────────────────
    function _investInHyperdrive(uint256 assets) internal {

        // Sean: implement some guards wrt the min/maxApr and LP share price slippage.
        //      Using some simple rule based logic, not ideal but it's a start.
        //      It can be future TODOs.

        uint256 minLpSharePrice = FixedPointMath.mulDivDown(hyperdrive.getPoolInfo().lpSharePrice, 9500, MAX_BPS); // 5% slippage

        // Sean: The min/max APR should be user specified range which deem acceptable to them. Too low apr
        //      means the yield is not attractive enough, too high APR means the utilization in the yield 
        //      source vault is too high so it's riskier. The user should have this min/max in mind and it's
        //      a personal choice, and is not necessarily based on the last checkpoint's Hyperdrive pool 
        //      spot APR with some buffer. Hence, I'm gonna use rule based logic here as well.

        uint256 minApr = 0.01e18; // 1%
        uint256 maxApr = 0.50e18; // 50%

        bytes memory extraData = new bytes(0);

        _asset.approve(address(hyperdrive), assets);
        hyperdrive.addLiquidity(assets, minLpSharePrice, minApr, maxApr, IHyperdrive.Options(address(this), asBase, extraData));
    }

    function _removeFromHyperdrive(uint256 assets) internal returns (uint256 proceeds) {
        IHyperdrive.PoolInfo memory poolInfo = hyperdrive.getPoolInfo();
        uint256 lpShares = asBase
            ? FixedPointMath.mulDivUp(assets,ONE, poolInfo.lpSharePrice)
        : FixedPointMath.mulDivUp(assets, poolInfo.vaultSharePrice, poolInfo.lpSharePrice);

        uint256 minOutputPerShare = asBase ? 
            // minOutputPerShare = 9500/10000 * lpSharePrice
            FixedPointMath.mulDivDown(poolInfo.lpSharePrice, 9500, (MAX_BPS*ONE)) : 
            // minOutputPerShare = 9500/10000 * lpSharePrice / vaultSharePrice
            FixedPointMath.mulDivDown(poolInfo.lpSharePrice, 9500, (MAX_BPS*poolInfo.vaultSharePrice)); //5% slippage

        bytes memory extraData = new bytes(0);
        uint256 withdrawalShares;
        (proceeds, withdrawalShares) = hyperdrive.removeLiquidity(
            lpShares,
            minOutputPerShare,
            IHyperdrive.Options(address(this), asBase, extraData)
        );

        require(withdrawalShares == 0, "LPAndChill: Not enough liquidity at the moment");

        return (proceeds);
    }
}
