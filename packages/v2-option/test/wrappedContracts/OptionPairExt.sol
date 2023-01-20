//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import "../../src/libraries/OptionPair.sol";

library OptionPairExt {
    function checkNotZeroAddress(address optionPair) public pure {
        return OptionPairLibrary.checkNotZeroAddress(optionPair);
    }

    function checkCorrectFormat(address token0, address token1) public pure {
        return OptionPairLibrary.checkCorrectFormat(token0, token1);
    }

    function checkDoesNotExist(address token0, address token1, address optionPair) public pure {
        return OptionPairLibrary.checkDoesNotExist(token0, token1, optionPair);
    }
}
