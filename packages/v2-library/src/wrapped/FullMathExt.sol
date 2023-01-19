//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {FullMath} from "../FullMath.sol";

library FullMathExt {
    function add512(uint256 addendA0, uint256 addendA1, uint256 addendB0, uint256 addendB1) external pure returns (uint256 sum0, uint256 sum1) {
        return FullMath.add512(addendA0, addendA1, addendB0, addendB1);
    }

    function sub512(uint256 minuend0, uint256 minuend1, uint256 subtrahend0, uint256 subtrahend1) external pure returns (uint256 difference0, uint256 difference1) {
        return FullMath.sub512(minuend0, minuend1, subtrahend0, subtrahend1);
    }

    function mul512(uint256 multiplicand, uint256 multiplier) external pure returns (uint256 product0, uint256 product1) {
        return FullMath.mul512(multiplicand, multiplier);
    }

    // function div256(uint256 divisor) external pure returns (uint256 quotient) {
    //     return FullMath.div256(divisor);
    // }

    // function mod256(uint256 value) external pure returns (uint256 result) {
    //     return FullMath.mod256(value);
    // }

    // function div512(uint256 dividend0, uint256 dividend1, uint256 divisor) external pure returns (uint256 quotient0, uint256 quotient1) {
    //     return FullMath.div512(dividend0, dividend1, divisor);
    // }

    function div512To256(uint256 dividend0, uint256 dividend1, uint256 divisor, bool roundUp) external pure returns (uint256 quotient) {
        return FullMath.div512To256(dividend0, dividend1, divisor, roundUp);
    }

    function div512(uint256 dividend0, uint256 dividend1, uint256 divisor, bool roundUp) external pure returns (uint256 quotient0, uint256 quotient1) {
        return FullMath.div512(dividend0, dividend1, divisor, roundUp);
    }

    function mulDiv(uint256 multiplicand, uint256 multiplier, uint256 divisor, bool roundUp) external pure returns (uint256 result) {
        return FullMath.mulDiv(multiplicand, multiplier, divisor, roundUp);
    }

    function sqrt512(uint256 value0, uint256 value1, bool roundUp) external pure returns (uint256 result) {
        return FullMath.sqrt512(value0, value1, roundUp);
    }

    // function sqrt512Estimate(uint256 value0, uint256 value1, uint256 currentEstimate) external pure returns (uint256 estimate) {
    //     return FullMath.sqrt512Estimate(value0, value1, currentEstimate);
    // }
}
