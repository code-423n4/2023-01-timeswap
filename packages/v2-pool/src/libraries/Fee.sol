//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

/// @title A library for The Timeswap V2 Option contract Fee type
library FeeLibrary {
    error IncorrectFeeInitialization(uint256 fee);

    /// @dev reverts when fee is greater than max of uint16
    /// @param fee The fee which is needed to be checked.
    function check(uint256 fee) internal pure {
        if (fee > type(uint16).max) revert IncorrectFeeInitialization(fee);
    }
}
