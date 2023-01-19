//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import "../../src/libraries/Proportion.sol";

library ProportionExt{
    function proportion(uint256 multiplicand, uint256 multiplier, uint256 divisor, bool roundUp) public pure returns (uint256) {
      return Proportion.proportion(multiplicand, multiplier, divisor, roundUp);
    }
}