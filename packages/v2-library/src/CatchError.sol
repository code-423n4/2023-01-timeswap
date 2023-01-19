//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {BytesLib} from "./BytesLib.sol";

library CatchError {
    /// @dev Get the data passed from a given custom error.
    /// @dev It checks that the first four bytes of the reason has the same selector.
    /// @notice Will simply revert with the original error if the first four bytes is not the given selector.
    /// @param reason The data being inquired upon.
    /// @param selector The given conditional selector.
    function catchError(bytes memory reason, bytes4 selector) internal pure returns (bytes memory) {
        uint256 length = reason.length;

        if ((length - 4) % 32 == 0 && bytes4(reason) == selector) return BytesLib.slice(reason, 4, length - 4);

        assembly {
            revert(reason, length)
        }
    }
}
