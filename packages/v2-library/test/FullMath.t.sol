// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import '../src/FullMath.sol';
import '../src/Math.sol';

// import "../../../contracts/utils/math/SafeMath.sol";

contract MathTest is Test {
  //ADD512
  function testAdd512(uint256 a0, uint256 a1, uint256 b0, uint256 b1) public {
    vm.assume(checkAdd512Overflow(a0, a1, b0, b1) == true);
    (uint256 r0, uint256 r1) = FullMath.add512(a0, a1, b0, b1);
    (uint256 rPrime0, uint256 carry) = _addCarry(a0, b0);
    uint256 rPrime1 = carry + a1 + b1;
    assertGe(rPrime1, a1 + b1);
    if (carry == 0) {
      assertGe(rPrime0, a0 + b0);
    }
  }

  //SUB512
  function testSub512(uint256 a0, uint256 a1, uint256 b0, uint256 b1) public {
    vm.assume(checkSub512Underflow(a0, a1, b0, b1) == true);
    (uint256 r0, uint256 r1) = FullMath.sub512(a0, a1, b0, b1);
    assertLe(r1, a1);
    if (b0 > a0) {
      assertGe(r0, a0);
    } else {
      assertLe(r0, a0);
    }
  }

  //DIV512
  // function testDiv512to256(uint256 a0, uint256 a1, uint256 b) public {
  //   vm.assume(b != 0);
  //   (uint256 quotient, uint256 quotient1) = div512(a0, a1, b);
  //   vm.assume(quotient1 == 0 && (quotient < (1 << 255)));
  //   (uint256 resDown, uint256 resUp) = (FullMath.div512To256(a0, a1, b, false), FullMath.div512To256(a0, a1, b, true));
  //   assertGe(1, resUp - resDown);
  // }

  function testSqrt512(uint256 a0, uint256 a1) public {
    vm.assume((a1 == 1 && a0 == 0) || a1 == 0);
    uint256 resultDown = FullMath.sqrt512(a0, a1, false);
    uint256 resultUp = FullMath.sqrt512(a0, a1, true);

    assertGe(1, resultUp - resultDown);
  }

  // MULDIV512
  function testMulDiv(uint256 x, uint256 y, uint256 d) public {
    // Full precision for x * y
    (uint256 xyHi, uint256 xyLo) = _mulHighLow(x, y);

    // Assume result won't overflow (see {testMulDivDomain})
    // This also checks that `d` is positive
    vm.assume(xyHi < d);

    // Perform muldiv
    uint256 q = FullMath.mulDiv(x, y, d, false);

    // Full precision for q * d
    (uint256 qdHi, uint256 qdLo) = _mulHighLow(q, d);
    // Add remainder of x * y / d (computed as rem = (x * y % d))
    (uint256 qdRemLo, uint256 c) = _addCarry(qdLo, _mulmod(x, y, d));
    uint256 qdRemHi = qdHi + c;

    // Full precision check that x * y = q * d + rem
    assertEq(xyHi, qdRemHi);
    assertEq(xyLo, qdRemLo);
  }

  function checkAdd512Overflow(uint256 a0, uint256 a1, uint256 b0, uint256 b1) public pure returns (bool) {
    uint256 r0;
    uint256 r1;
    (r0, r1) = _addCarry(a0, b0);
    assembly {
      r1 := add(r1, add(b1, a1))
    }
    if (r1 < a1 || r1 < b1) {
      return false;
    } else if (r1 == a1 || r1 == b1) {
      if (r0 < a0 || r0 < b0) {
        return false;
      }
    }
    return true;
  }

  function checkSub512Underflow(uint256 a0, uint256 a1, uint256 b0, uint256 b1) public pure returns (bool) {
    if (b1 > a1 || ((b1 == a1) && (b0 > a0))) return false;
    return true;
  }

  function _mulmod(uint256 x, uint256 y, uint256 z) private pure returns (uint256 r) {
    assembly {
      r := mulmod(x, y, z)
    }
  }

  function _mulHighLow(uint256 x, uint256 y) private pure returns (uint256 high, uint256 low) {
    (uint256 x0, uint256 x1) = (x & type(uint128).max, x >> 128);
    (uint256 y0, uint256 y1) = (y & type(uint128).max, y >> 128);

    // Karatsuba algorithm
    // https://en.wikipedia.org/wiki/Karatsuba_algorithm
    uint256 z2 = x1 * y1;
    uint256 z1a = x1 * y0;
    uint256 z1b = x0 * y1;
    uint256 z0 = x0 * y0;

    uint256 carry = ((z1a & type(uint128).max) + (z1b & type(uint128).max) + (z0 >> 128)) >> 128;

    high = z2 + (z1a >> 128) + (z1b >> 128) + carry;

    unchecked {
      low = x * y;
    }
  }

  function _addCarry(uint256 x, uint256 y) private pure returns (uint256 res, uint256 carry) {
    unchecked {
      res = x + y;
    }
    carry = res < x ? 1 : 0;
  }

  function mul512(uint256 multiplicand, uint256 multiplier) internal pure returns (uint256 product0, uint256 product1) {
    assembly {
      let mm := mulmod(multiplicand, multiplier, not(0))
      product0 := mul(multiplicand, multiplier)
      product1 := sub(sub(mm, product0), lt(mm, product0))
    }
  }

  function div512(uint256 a0, uint256 a1, uint256 b) internal view returns (uint256 x0, uint256 x1) {
    if (b == 1) {
      (x0, x1) = (a0, a1);
    } else {
      uint256 q = div256(b);
      uint256 r = mod256(b);
      while (a1 != 0) {
        (uint256 t0, uint256 t1) = mul512(a1, q);
        (x0, x1) = FullMath.add512(x0, x1, t0, t1);
        (t0, t1) = FullMath.mul512(a1, r);
        (a0, a1) = FullMath.add512(t0, t1, a0, 0);
      }
      (x0, x1) = FullMath.add512(x0, x1, a0 / b, 0);
    }
  }

  function div256(uint256 divisor) private pure returns (uint256 quotient) {
    if (divisor == 0) revert Math.DivideByZero();
    if (divisor == 1) revert Math.Overflow();
    assembly {
      quotient := add(div(sub(0, divisor), divisor), 1)
    }
  }

  function mod256(uint256 value) private pure returns (uint256 result) {
    if (value == 0) revert Math.DivideByZero();
    assembly {
      result := mod(sub(0, value), value)
    }
  }
}
