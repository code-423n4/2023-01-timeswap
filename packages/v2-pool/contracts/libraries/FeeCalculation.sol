//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {Math} from '@timeswap-labs/v2-library/contracts/Math.sol';
import {FullMath} from '@timeswap-labs/v2-library/contracts/FullMath.sol';

///@title library for fees related calculations
library FeeCalculation {
  using Math for uint256;

  /// @dev Reverts when fee overflow.
  error FeeOverflow();

  /// @dev reverts to overflow fee.
  function feeOverflow() private pure {
    revert FeeOverflow();
  }

  /// @dev Updates the new fee growth and protocol fee given the current fee growth and protocol fee.
  /// @param liquidity The current liquidity in the pool.
  /// @param feeGrowth The current feeGrowth in the pool.
  /// @param protocolFees The current protocolFees in the pool.
  /// @param fees The fees to be earned.
  /// @param protocolFee The protocol fee rate.
  /// @return newFeeGrowth The newly updated fee growth.
  /// @return newProtocolFees The newly updated protocol fees.
  function update(
    uint160 liquidity,
    uint256 feeGrowth,
    uint256 protocolFees,
    uint256 fees,
    uint256 protocolFee
  ) internal pure returns (uint256 newFeeGrowth, uint256 newProtocolFees) {
    uint256 protocolFeesToAdd = getFeesRemoval(fees, protocolFee);

    newFeeGrowth = feeGrowth.unsafeAdd(getFeeGrowth(fees.unsafeSub(protocolFeesToAdd), liquidity));

    newProtocolFees = protocolFees + protocolFeesToAdd;
  }

  /// @dev get the fee given the last fee growth and the global fee growth
  /// @notice returns zero if the last fee growth is equal to the global fee growth
  /// @param liquidity The current liquidity in the pool.
  /// @param lastFeeGrowth The previous global fee growth when owner enters.
  /// @param globalFeeGrowth The current global fee growth.
  function getFees(uint160 liquidity, uint256 lastFeeGrowth, uint256 globalFeeGrowth) internal pure returns (uint256) {
    return
      globalFeeGrowth != lastFeeGrowth
        ? FullMath.mulDiv(liquidity, uint256(1) << 128, globalFeeGrowth.unsafeSub(lastFeeGrowth), false)
        : 0;
  }

  /// @dev Adds the fees to the amount.
  /// @param amount The original amount.
  /// @param fee The transaction fee rate.
  function addFees(uint256 amount, uint256 fee) internal pure returns (uint256) {
    return FullMath.mulDiv(amount, (uint256(1) << 16), (uint256(1) << 16).unsafeSub(fee), true);
  }

  /// @dev Removes the fees from the amount.
  /// @param amount The original amount.
  /// @param fee The transaction fee rate.
  function removeFees(uint256 amount, uint256 fee) internal pure returns (uint256) {
    return FullMath.mulDiv(amount, (uint256(1) << 16).unsafeSub(fee), uint256(1) << 16, false);
  }

  /// @dev Get the fees from an amount with fees.
  /// @param amount The amount with fees.
  /// @param fee The transaction fee rate.
  function getFeesRemoval(uint256 amount, uint256 fee) internal pure returns (uint256) {
    return FullMath.mulDiv(amount, fee, uint256(1) << 16, true);
  }

  /// @dev Get the fees from an amount.
  /// @param amount The amount with fees.
  /// @param fee The transaction fee rate.
  function getFeesAdditional(uint256 amount, uint256 fee) internal pure returns (uint256) {
    return FullMath.mulDiv(amount, fee, (uint256(1) << 16).unsafeSub(fee), true);
  }

  /// @dev Get the fee growth.
  /// @param feeAmount The fee amount.
  /// @param liquidity The current liquidity in the pool.
  function getFeeGrowth(uint256 feeAmount, uint160 liquidity) internal pure returns (uint256) {
    return FullMath.mulDiv(feeAmount, uint256(1) << 128, liquidity, false);
  }
}
