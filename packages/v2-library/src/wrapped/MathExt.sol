// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../Math.sol";

library MathExt {
    function unsafeAdd(uint256 addend1, uint256 addend2) external pure returns (uint256 sum) {
        return Math.unsafeAdd(addend1, addend2);
    }

    function unsafeSub(uint256 minuend, uint256 subtrahend) external pure returns (uint256 difference) {
        return Math.unsafeSub(minuend, subtrahend);
    }

    function unsafeMul(uint256 multiplicand, uint256 multiplier) external pure returns (uint256 product) {
        return Math.unsafeMul(multiplicand, multiplier);
    }

    function div(uint256 dividend, uint256 divisor, bool roundUp) external pure returns (uint256 quotient) {
        return Math.div(dividend, divisor, roundUp);
    }

    function shr(uint256 dividend, uint8 divisorBit, bool roundUp) external pure returns (uint256 quotient) {
        return Math.shr(dividend, divisorBit, roundUp);
    }

    function sqrt(uint256 value, bool roundUp) external pure returns (uint256 result) {
        return Math.sqrt(value, roundUp);
    }

    function min(uint256 value1, uint256 value2) external pure returns (uint256 result) {
        return Math.min(value1, value2);
    }
}
