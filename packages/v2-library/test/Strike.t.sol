pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import '../contracts/StrikeConversion.sol';

contract StrikeTest is Test {
  function testConvert(uint256 amount, uint256 strike, bool zeroToOne) public {
    vm.assume(strike > 0);
    if (!zeroToOne) {
      vm.assume(amount < (1 << 128));
      (uint256 roundDown, uint256 roundUp) = (
        StrikeConversion.convert(amount, strike, zeroToOne, false),
        StrikeConversion.convert(amount, strike, zeroToOne, true)
      );
      if (roundUp == roundDown) {
        assertEq(amount, StrikeConversion.convert(roundDown, strike, !zeroToOne, false));
      }
    } else {
      vm.assume(amount < (1 << 128));
      (uint256 roundDown, uint256 roundUp) = (
        StrikeConversion.convert(amount, strike, !zeroToOne, false),
        StrikeConversion.convert(amount, strike, !zeroToOne, true)
      );
      if (roundUp == roundDown) {
        assertEq(amount, StrikeConversion.convert(roundDown, strike, zeroToOne, false));
      }
    }
  }

  function testTurn(uint256 amount, uint256 strike, bool zeroToOne) public {
    vm.assume(strike > 0);
    vm.assume(amount < (1 << 128));

    if (strike > (1 << 128)) {
      if (zeroToOne) {
        assertEq(
          StrikeConversion.convert(amount, strike, true, true),
          StrikeConversion.turn(amount, strike, zeroToOne, true)
        );
      } else {
        assertEq(amount, StrikeConversion.turn(amount, strike, zeroToOne, true));
      }
    } else {
      if (zeroToOne) {
        assertEq(amount, StrikeConversion.turn(amount, strike, zeroToOne, true));
      } else {
        assertEq(
          StrikeConversion.convert(amount, strike, false, true),
          StrikeConversion.turn(amount, strike, zeroToOne, true)
        );
      }
    }
  }

  function testCombine(uint256 amount0, uint256 amount1, uint256 strike, bool zeroToOne) public {
    vm.assume(strike > 0);
    vm.assume(amount0 < (1 << 128));
    vm.assume(amount1 < (1 << 128));

    if (strike > (1 << 128)) {
      assertEq(
        amount0 + StrikeConversion.convert(amount1, strike, false, true),
        StrikeConversion.combine(amount0, amount1, strike, true)
      );
    } else {
      assertEq(
        amount1 + StrikeConversion.convert(amount0, strike, true, true),
        StrikeConversion.combine(amount0, amount1, strike, true)
      );
    }
  }

  function testDif(uint256 base, uint256 amount, uint256 strike, bool zeroToOne) public {
    vm.assume(strike > 0);
    vm.assume(amount < (1 << 128));
    vm.assume(base < (1 << 128) && base > 0);
    if (strike > (1 << 128)) {
      if (zeroToOne) {
        vm.assume(base > amount);
        assertEq(
          StrikeConversion.convert(base - amount, strike, true, true),
          StrikeConversion.dif(base, amount, strike, zeroToOne, true)
        );
      } else {
        vm.assume(base > StrikeConversion.convert(amount, strike, false, false));
        assertEq(
          base - StrikeConversion.convert(amount, strike, false, false),
          StrikeConversion.dif(base, amount, strike, zeroToOne, true)
        );
      }
    } else {
      if (zeroToOne) {
        vm.assume(base > StrikeConversion.convert(amount, strike, false, false));
        assertEq(
          base - StrikeConversion.convert(amount, strike, true, false),
          StrikeConversion.dif(base, amount, strike, zeroToOne, true)
        );
      } else {
        vm.assume(base > amount);
        assertEq(
          StrikeConversion.convert(base - amount, strike, false, true),
          StrikeConversion.dif(base, amount, strike, zeroToOne, true)
        );
      }
    }
  }
}
