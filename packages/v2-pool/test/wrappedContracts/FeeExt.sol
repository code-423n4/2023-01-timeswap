// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import '../../src/libraries/Fee.sol';

library FeeExt{
    
    function check(uint256 fee) public pure {
        FeeLibrary.check(fee);
    }

}