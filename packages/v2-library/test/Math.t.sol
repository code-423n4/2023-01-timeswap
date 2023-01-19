// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../src/wrapped/MathExt.sol";

contract MathTest is Test {
    function testUnsafeAdd(uint256 addend1, uint256 addend2) public pure {
        MathExt.unsafeAdd(addend1, addend2);
    }

    function testUnsafeSub(uint256 minuend, uint256 subtrahend) public pure {
        MathExt.unsafeAdd(minuend, subtrahend);
    }

    function unsafeMul(uint256 multiplicand, uint256 multiplier) public pure {
        MathExt.unsafeMul(multiplicand, multiplier);
    }

    function testDiv(uint256 dividend, uint256 divisor, bool roundUp) public pure {
        vm.assume(divisor != 0);
        MathExt.div(dividend, divisor, roundUp);
    }

    function testShr(uint256 dividend, uint8 divisorBit, bool roundUp) public pure {
        MathExt.shr(dividend, divisorBit, roundUp);
    }

    function testSqrt(uint256 value, bool roundUp) public pure {
        MathExt.sqrt(value, roundUp);
    }

    function testMin(uint256 value1, uint256 value2) public pure {
        MathExt.min(value1, value2);
    }
}
