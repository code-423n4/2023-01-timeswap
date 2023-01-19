// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import '../../src/libraries/PoolPair.sol';

library PoolPairExt{
    
    function checkNotZeroAddress(address poolPair) public pure {
        PoolPairLibrary.checkNotZeroAddress(poolPair);
    }

    function checkDoesNotExist(address optionPair, address poolPair) public pure {
        PoolPairLibrary.checkDoesNotExist(optionPair, poolPair);
    }

}
