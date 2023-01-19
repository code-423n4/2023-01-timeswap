//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;
import "../../src/StrikeConversion.sol";

library StrikeConversionExt {
    function convert(uint256 amount, uint256 strike, bool zeroToOne, bool roundUp) external pure returns (uint256) {
        return StrikeConversion.convert(amount, strike, zeroToOne, roundUp);
    }

    function turn(uint256 amount, uint256 strike, bool toOne, bool roundUp) external pure returns (uint256) {
        return StrikeConversion.turn(amount, strike, toOne, roundUp);
    }

    function combine(uint256 amount0, uint256 amount1, uint256 strike, bool roundUp) external pure returns (uint256) {
        return StrikeConversion.combine(amount0, amount1, strike, roundUp);
    }

    function dif(uint256 base, uint256 amount, uint256 strike, bool zeroToOne, bool roundUp) external pure returns (uint256) {
        return StrikeConversion.dif(base, amount, strike, zeroToOne, roundUp);
    }
}
