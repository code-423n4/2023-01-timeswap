//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {StrikeConversion} from "@timeswap-labs/v2-library/src/StrikeConversion.sol";
import {Math} from "@timeswap-labs/v2-library/src/Math.sol";

import {FeeCalculation} from "./FeeCalculation.sol";
import {Error} from "@timeswap-labs/v2-library/src/Error.sol";

/// @title Constant Sum Library that returns the Constant Sum given certain parameters
library ConstantSum {
    using Math for uint256;

    /// @dev Calculate long amount out.
    /// @param strike The strike of the pool.
    /// @param longAmountIn The long amount to be deposited.
    /// @param transactionFee The fee that will be adjusted in the transaction.
    /// @param isLong0ToLong1 Deposit long0 positions when true. Deposit long1 positions when false.
    function calculateGivenLongIn(uint256 strike, uint256 longAmountIn, uint256 transactionFee, bool isLong0ToLong1) internal pure returns (uint256 longAmountOut, uint256 longFees) {
        longAmountOut = StrikeConversion.convert(longAmountIn, strike, isLong0ToLong1, false);
        longFees = FeeCalculation.getFeesRemoval(longAmountOut, transactionFee);
        longAmountOut = longAmountOut.unsafeSub(longFees);
    }

    /// @dev Calculate long amount in.
    /// @param strike The strike of the pool.
    /// @param longAmountOut The long amount to be withdrawn.
    /// @param transactionFee The fee that will be adjusted in the transaction.
    /// @param isLong0ToLong1 Deposit long0 positions when true. Deposit long1 positions when false.
    function calculateGivenLongOut(uint256 strike, uint256 longAmountOut, uint256 transactionFee, bool isLong0ToLong1) internal pure returns (uint256 longAmountIn, uint256 longFees) {
        longFees = FeeCalculation.getFeesAdditional(longAmountOut, transactionFee);
        longAmountIn = StrikeConversion.convert(longAmountOut + longFees, strike, !isLong0ToLong1, true);
    }

    /// @dev Calculate long amount in without adjusting for fees.
    /// @param strike The strike of the pool.
    /// @param longAmountOut The long amount to be withdrawn.
    /// @param isLong0ToLong1 Deposit long0 positions when true. Deposit long1 positions when false.
    function calculateGivenLongOutAlreadyAdjustFees(uint256 strike, uint256 longAmountOut, bool isLong0ToLong1) internal pure returns (uint256 longAmountIn) {
        longAmountIn = StrikeConversion.convert(longAmountOut, strike, !isLong0ToLong1, true);
    }
}
