//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;
import "../CatchError.sol";

library CatchErrorExt {
    function catchError(bytes memory reason, bytes4 selector) external pure returns (bytes memory) {
        return CatchError.catchError(reason, selector);
    }
}
