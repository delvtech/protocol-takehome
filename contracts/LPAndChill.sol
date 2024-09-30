// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.22;

import {IERC20} from "hyperdrive/src/interfaces/IERC20.sol";
import {IHyperdrive} from "hyperdrive/src/interfaces/IHyperdrive.sol";
import {HyperdriveMath} from "hyperdrive/src/libraries/HyperdriveMath.sol";
import {ERC4626} from "solady/tokens/ERC4626.sol";

/// @author DELV
/// @title Momo
/// @notice A principal protected vault powered by Hyperdrive. This vault gives
///         multiplied exposure by taking advantage of fixed rate spreads.
/// @custom:disclaimer The language used in this code is for coding convenience
///                    only, and is not intended to, and does not, have any
///                    particular legal or regulatory significance.
contract LPAndChill is ERC4626 {
    // ╭─────────────────────────────────────────────────────────╮
    // │ Storage                                                 │
    // ╰─────────────────────────────────────────────────────────╯

    // ───────────────────────── Immutables ──────────────────────

    /// @dev A flag indicating whether or not deposits and withdrawals should
    ///      be processed in base or vault shares.
    bool public immutable asBase;

    /// @dev The asset underlying all of the investments.
    IERC20 internal immutable _asset;

    // ─────────────────────────── State ────────────────────────

    /// @dev The name of the LPAndChill token.
    string internal _name;

    /// @dev The symbol of the LPAndChill token.
    string internal _symbol;

    /// @notice The Hyperdrive pool.
    IHyperdrive public immutable hyperdrive;

    // ╭─────────────────────────────────────────────────────────╮
    // │ Constructor                                             │
    // ╰─────────────────────────────────────────────────────────╯

    /// @notice Instantiates the Momo vault.
    /// @param __name Name of the Momo vault token.
    /// @param __symbol Symbol of the Momo vault token.
    /// @param _hyperdrive The Hyperdrive pool to invest into.
    /// @param _asBase A flag indicating whether to deposit and withdraw using
    ///        base or vault shares.
    constructor(
        string memory __name,
        string memory __symbol,
        IHyperdrive _hyperdrive,
        bool _asBase
    ) {
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
        return _asset.balanceOf(address(this));
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
}
