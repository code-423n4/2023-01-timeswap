//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract.
contract NoDelegateCall {
  /* ===== ERROR ===== */

  /// @dev Reverts when called using delegatecall.
  error CannotBeDelegateCalled();

  /* ===== MODEL ===== */

  /// @dev The original address of this contract.
  address private immutable original;

  /* ===== INIT ===== */

  constructor() {
    // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
    // In other words, this variable won't change when it's checked at runtime.
    original = address(this);
  }

  /* ===== MODIFIER ===== */

  /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
  /// and the use of immutable means the address bytes are copied in every place the modifier is used.
  function checkNotDelegateCall() private view {
    if (address(this) != original) revert CannotBeDelegateCalled();
  }

  /// @notice Prevents delegatecall into the modified method
  modifier noDelegateCall() {
    checkNotDelegateCall();
    _;
  }
}
