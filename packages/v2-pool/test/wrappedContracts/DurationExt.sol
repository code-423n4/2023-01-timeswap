// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import "../../src/libraries/Duration.sol";

library DurationLibraryExt {
    function init(uint256 duration) public pure returns (uint96) {
        return DurationLibrary.init(duration);
    }
}
