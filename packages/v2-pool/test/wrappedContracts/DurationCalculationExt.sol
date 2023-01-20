// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import "../../src/libraries/DurationCalculation.sol";

library DurationCalculationExt {
    function unsafeDurationFromLastTimestampToNow(uint96 lastTimestamp, uint96 blockTimestamp) public pure returns (uint96) {
        return DurationCalculation.unsafeDurationFromLastTimestampToNow(lastTimestamp, blockTimestamp);
    }

    function unsafeDurationFromNowToMaturity(uint256 maturity, uint96 blockTimestamp) public pure returns (uint96) {
        return DurationCalculation.unsafeDurationFromNowToMaturity(maturity, blockTimestamp);
    }

    function unsafeDurationFromLastTimestampToMaturity(uint96 lastTimestamp, uint256 maturity) public pure returns (uint96) {
        return DurationCalculation.unsafeDurationFromLastTimestampToMaturity(lastTimestamp, maturity);
    }

    function unsafeDurationFromLastTimestampToNowOrMaturity(uint96 lastTimestamp, uint256 maturity, uint96 blockTimestamp) public pure returns (uint96) {
        return DurationCalculation.unsafeDurationFromLastTimestampToNowOrMaturity(lastTimestamp, maturity, blockTimestamp);
    }
}
