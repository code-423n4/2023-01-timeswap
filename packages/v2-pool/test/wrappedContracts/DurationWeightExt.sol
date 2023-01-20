// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import "../../src/libraries/DurationWeight.sol";

library DurationWeightExt {
    function update(uint160 liquidity, uint256 shortFeeGrowth, uint256 shortAmount) public pure returns (uint256) {
        return DurationWeight.update(liquidity, shortFeeGrowth, shortAmount);
    }
}
