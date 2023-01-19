pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../src/wrapped/StrikeConversionExt.sol";

contract StrikeTest is Test {
    function testConvert(uint256 amount, uint256 strike, bool zeroToOne) public {
        vm.assume(strike > 0);
        if (!zeroToOne) {
            vm.assume(amount < (1 << 128));
            (uint256 roundDown, uint256 roundUp) = (StrikeConversionExt.convert(amount, strike, zeroToOne, false), StrikeConversionExt.convert(amount, strike, zeroToOne, true));
            if (roundUp == roundDown) {
                assertEq(amount, StrikeConversionExt.convert(roundDown, strike, !zeroToOne, false));
            }
        } else {
            vm.assume(amount < (1 << 128));
            (uint256 roundDown, uint256 roundUp) = (StrikeConversionExt.convert(amount, strike, !zeroToOne, false), StrikeConversionExt.convert(amount, strike, !zeroToOne, true));
            if (roundUp == roundDown) {
                assertEq(amount, StrikeConversionExt.convert(roundDown, strike, zeroToOne, false));
            }
        }
    }

    function testTurn(uint256 amount, uint256 strike, bool zeroToOne) public {
        vm.assume(strike > 0);
        vm.assume(amount < (1 << 128));

        if (strike > (1 << 128)) {
            if (zeroToOne) {
                assertEq(StrikeConversionExt.convert(amount, strike, true, true), StrikeConversionExt.turn(amount, strike, zeroToOne, true));
            } else {
                assertEq(amount, StrikeConversionExt.turn(amount, strike, zeroToOne, true));
            }
        } else {
            if (zeroToOne) {
                assertEq(amount, StrikeConversionExt.turn(amount, strike, zeroToOne, true));
            } else {
                assertEq(StrikeConversionExt.convert(amount, strike, false, true), StrikeConversionExt.turn(amount, strike, zeroToOne, true));
            }
        }
    }

    function testCombine(uint256 amount0, uint256 amount1, uint256 strike) public {
        vm.assume(strike > 0);
        vm.assume(amount0 < (1 << 128));
        vm.assume(amount1 < (1 << 128));

        if (strike > (1 << 128)) {
            assertEq(amount0 + StrikeConversionExt.convert(amount1, strike, false, true), StrikeConversionExt.combine(amount0, amount1, strike, true));
        } else {
            assertEq(amount1 + StrikeConversionExt.convert(amount0, strike, true, true), StrikeConversionExt.combine(amount0, amount1, strike, true));
        }
    }

    function testDif(uint256 base, uint256 amount, uint256 strike, bool zeroToOne) public {
        vm.assume(strike > 0);
        vm.assume(amount < (1 << 128));
        vm.assume(base < (1 << 128) && base > 0);
        if (strike > (1 << 128)) {
            if (zeroToOne) {
                vm.assume(base > amount);
                assertEq(StrikeConversionExt.convert(base - amount, strike, true, true), StrikeConversionExt.dif(base, amount, strike, zeroToOne, true));
            } else {
                vm.assume(base > StrikeConversionExt.convert(amount, strike, false, false));
                assertEq(base - StrikeConversionExt.convert(amount, strike, false, false), StrikeConversionExt.dif(base, amount, strike, zeroToOne, true));
            }
        } else {
            if (zeroToOne) {
                vm.assume(base > StrikeConversionExt.convert(amount, strike, false, false));
                assertEq(base - StrikeConversionExt.convert(amount, strike, true, false), StrikeConversionExt.dif(base, amount, strike, zeroToOne, true));
            } else {
                vm.assume(base > amount);
                assertEq(StrikeConversionExt.convert(base - amount, strike, false, true), StrikeConversionExt.dif(base, amount, strike, zeroToOne, true));
            }
        }
    }
}
