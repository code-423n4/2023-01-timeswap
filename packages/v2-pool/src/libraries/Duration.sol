//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

/// @title A library for The Timeswap V2 Option contract Duration type
library DurationLibrary {
    error DurationOverflow(uint256 duration);

    /// @dev initialize the duration type
    /// @dev Reverts when the duration is too large.
    /// @param duration The duration in seconds which is needed to be converted to the Duration type.
    function init(uint256 duration) internal pure returns (uint96) {
        if (duration > type(uint96).max) revert DurationOverflow(duration);
        return uint96(duration);
    }
}
