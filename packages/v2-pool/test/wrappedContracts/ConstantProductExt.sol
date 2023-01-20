// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import "../../src/libraries/ConstantProduct.sol";

library ConstantProductExt {
    function getLong(uint160 liquidity, uint160 rate, bool roundUp) public pure returns (uint256) {
        return ConstantProduct.getLong(liquidity, rate, roundUp);
    }

    function getShort(uint160 liquidity, uint160 rate, uint96 duration, bool roundUp) public pure returns (uint256) {
        return ConstantProduct.getShort(liquidity, rate, duration, roundUp);
    }

    function calculateGivenLiquidityDelta(uint160 rate, uint160 deltaLiquidity, uint96 duration, bool isAdd) public pure returns (uint256 longAmount, uint256 shortAmount) {
        return ConstantProduct.calculateGivenLiquidityDelta(rate, deltaLiquidity, duration, isAdd);
    }

    function calculateGivenLiquidityLong(uint160 rate, uint256 longAmount, uint96 duration, bool isAdd) public pure returns (uint160 liquidityAmount, uint256 shortAmount) {
        return ConstantProduct.calculateGivenLiquidityLong(rate, longAmount, duration, isAdd);
    }

    function calculateGivenLiquidityShort(uint160 rate, uint256 shortAmount, uint96 duration, bool isAdd) public pure returns (uint160 liquidityAmount, uint256 longAmount) {
        return ConstantProduct.calculateGivenLiquidityShort(rate, shortAmount, duration, isAdd);
    }

    function calculateGivenLiquidityLargerOrSmaller(uint160 rate, uint256 amount, uint96 duration, bool isAdd) public pure returns (uint160 liquidityAmount, uint256 longAmount, uint256 shortAmount) {
        return ConstantProduct.calculateGivenLiquidityLargerOrSmaller(rate, amount, duration, isAdd);
    }

    function updateGivenSqrtInterestRateDelta(
        uint160 liquidity,
        uint160 rate,
        uint160 deltaRate,
        uint96 duration,
        uint256 transactionFee,
        bool isAdd
    ) public pure returns (uint160 newRate, uint256 longAmount, uint256 shortAmount, uint256 fees) {
        return ConstantProduct.updateGivenSqrtInterestRateDelta(liquidity, rate, deltaRate, duration, transactionFee, isAdd);
    }

    function updateGivenLong(
        uint160 liquidity,
        uint160 rate,
        uint256 longAmount,
        uint96 duration,
        uint256 transactionFee,
        bool isAdd
    ) public pure returns (uint160 newRate, uint256 shortAmount, uint256 fees) {
        return ConstantProduct.updateGivenLong(liquidity, rate, longAmount, duration, transactionFee, isAdd);
    }

    function updateGivenShort(
        uint160 liquidity,
        uint160 rate,
        uint256 shortAmount,
        uint96 duration,
        uint256 transactionFee,
        bool isAdd
    ) public pure returns (uint160 newRate, uint256 longAmount, uint256 fees) {
        return ConstantProduct.updateGivenShort(liquidity, rate, shortAmount, duration, transactionFee, isAdd);
    }

    function updateGivenSumLong(
        uint160 liquidity,
        uint160 rate,
        uint256 sumAmount,
        uint96 duration,
        uint256 transactionFee,
        bool isAdd
    ) public pure returns (uint160 newRate, uint256 longAmount, uint256 shortAmount, uint256 fees) {
        return ConstantProduct.updateGivenSumLong(liquidity, rate, sumAmount, duration, transactionFee, isAdd);
    }
}
