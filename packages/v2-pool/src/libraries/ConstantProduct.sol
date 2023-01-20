//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {Math} from "@timeswap-labs/v2-library/src/Math.sol";
import {FullMath} from "@timeswap-labs/v2-library/src/FullMath.sol";

import {SafeCast} from "@timeswap-labs/v2-library/src/SafeCast.sol";

import {FeeCalculation} from "./FeeCalculation.sol";

/// @title Constant Product Library that returns the Constant Product given certain parameters
library ConstantProduct {
    using Math for uint256;
    using SafeCast for uint256;

    /// @dev Reverts when calculation overflows or underflows.
    error CalculationOverload();

    /// @dev Reverts when there is not enough time value liqudity to receive when lending.
    error NotEnoughLiquidityToLend();

    /// @dev Reverts when there is not enough principal liquidity to borrow from.
    error NotEnoughLiquidityToBorrow();

    /// @dev Returns the Long position given liquidity.
    /// @param liquidity The liquidity given.
    /// @param rate The pool's squared root Interest Rate.
    /// @param roundUp Rounds up the result when true. Rounds down the result when false.
    function getLong(uint160 liquidity, uint160 rate, bool roundUp) internal pure returns (uint256) {
        return (uint256(liquidity) << 96).div(rate, roundUp);
    }

    /// @dev Returns the Short position given liquidity.
    /// @param liquidity The liquidity given.
    /// @param rate The pool's squared root Interest Rate.
    /// @param duration The time duration in seconds.
    /// @param roundUp Rounds up the result when true. Rounds down the result when false.
    function getShort(uint160 liquidity, uint160 rate, uint96 duration, bool roundUp) internal pure returns (uint256) {
        return FullMath.mulDiv(uint256(liquidity).unsafeMul(duration), uint256(rate), uint256(1) << 192, roundUp);
    }

    /// @dev Calculate the amount of long positions in base denomination and short positions from change of liquidity.
    /// @param rate The pool's squared root Interest Rate.
    /// @param deltaLiquidity The change in liquidity amount.
    /// @param duration The time duration in seconds.
    /// @param isAdd Increase liquidity amount if true. Decrease liquidity amount if false.
    /// @return longAmount The amount of long positions in base denomination to deposit when increasing liquidity.
    /// The amount of long positions in base denomination to withdraw when decreasing liquidity.
    /// @return shortAmount The amount of short positions to deposit when increasing liquidity.
    /// The amount of short positions to withdraw when decreasing liquidity.
    function calculateGivenLiquidityDelta(uint160 rate, uint160 deltaLiquidity, uint96 duration, bool isAdd) internal pure returns (uint256 longAmount, uint256 shortAmount) {
        longAmount = getLong(deltaLiquidity, rate, isAdd);

        shortAmount = getShort(deltaLiquidity, rate, duration, isAdd);
    }

    /// @dev Calculate the amount of liquidity positions and amount of short positions from given long positions in base denomination.
    /// @param rate The pool's squared root Interest Rate.
    /// @param longAmount The amount of long positions.
    /// @param duration The time duration in seconds.
    /// @param isAdd Deposit long amount in base denomination if true. Withdraw long amount in base denomination if false.
    /// @return liquidityAmount The amount of liquidity positions minted when depositing long positions.
    /// The amount of liquidity positions burnt when withdrawing long positions.
    /// @return shortAmount The amount of short positions to deposit when depositing long positions.
    /// The amount of short positions to withdraw when withdrawing long positions.
    function calculateGivenLiquidityLong(uint160 rate, uint256 longAmount, uint96 duration, bool isAdd) internal pure returns (uint160 liquidityAmount, uint256 shortAmount) {
        liquidityAmount = getLiquidityGivenLong(rate, longAmount, !isAdd);

        shortAmount = getShort(liquidityAmount, rate, duration, isAdd);
    }

    /// @dev Calculate the amount of liquidity positions and amount of long positions in base denomination from given short positions.
    /// @param rate The pool's squared root Interest Rate.
    /// @param shortAmount The amount of short positions.
    /// @param duration The time duration in seconds.
    /// @param isAdd Deposit short amount if true. Withdraw short amount if false.
    /// @return liquidityAmount The amount of liquidity positions minted when depositing short positions.
    /// The amount of liquidity positions burnt when withdrawing short positions.
    /// @return longAmount The amount of long positions in base denomination to deposit when depositing short positions.
    /// The amount of long positions in base denomination to withdraw when withdrawing short positions.
    function calculateGivenLiquidityShort(uint160 rate, uint256 shortAmount, uint96 duration, bool isAdd) internal pure returns (uint160 liquidityAmount, uint256 longAmount) {
        liquidityAmount = getLiquidityGivenShort(rate, shortAmount, duration, !isAdd);

        longAmount = getLong(liquidityAmount, rate, isAdd);
    }

    /// @dev Calculate the amount of liquidity positions and amount of long positions in base denomination or short position whichever is larger or smaller.
    /// @param rate The pool's squared root Interest Rate.
    /// @param amount The amount of long positions in base denomination or short positions whichever is larger.
    /// @param duration The time duration in seconds.
    /// @param isAdd Deposit short amount if true. Withdraw short amount if false.
    /// @return liquidityAmount The amount of liquidity positions minted when depositing short positions.
    /// The amount of liquidity positions burnt when withdrawing short positions.
    /// @return longAmount The amount of long positions in base denomination to deposit when depositing short positions.
    /// The amount of long positions in base denomination to withdraw when withdrawing short positions.
    /// @return shortAmount The amount of short positions to deposit when depositing long positions.
    /// The amount of short positions to withdraw when withdrawing long positions.
    function calculateGivenLiquidityLargerOrSmaller(
        uint160 rate,
        uint256 amount,
        uint96 duration,
        bool isAdd
    ) internal pure returns (uint160 liquidityAmount, uint256 longAmount, uint256 shortAmount) {
        liquidityAmount = getLiquidityGivenLong(rate, amount, !isAdd);

        shortAmount = getShort(liquidityAmount, rate, duration, isAdd);

        if (isAdd ? amount >= shortAmount : amount <= shortAmount) longAmount = amount;
        else {
            liquidityAmount = getLiquidityGivenShort(rate, amount, duration, !isAdd);

            longAmount = getLong(liquidityAmount, rate, isAdd);

            shortAmount = amount;

            if (isAdd ? amount < longAmount : amount > longAmount) longAmount = amount;
        }
    }

    /// @dev Update the new square root interest rate given change in square root change.
    /// @param liquidity The amount of liquidity of the pool.
    /// @param rate The pool's squared root Interest Rate.
    /// @param deltaRate The change in the squared root Interest Rate.
    /// @param duration The time duration in seconds.
    /// @param transactionFee The fee that will be adjusted in the transaction.
    /// @param isAdd Increase square root interest rate if true. Decrease square root interest rate if false.
    /// @return newRate The new squared root Interest Rate.
    /// @return longAmount The amount of long positions in base denomination to withdraw when increasing square root interest rate.
    /// The amount of long positions in base denomination to deposit when decreasing square root interest rate.
    /// @return shortAmount The amount of short positions to deposit when increasing square root interest rate.
    /// The amount of short positions to withdraw when decreasing square root interest rate.
    /// @return fees The amount of long positions fee in base denominations when increasing square root interest rate.
    /// The amount of short positions fee when decreasing square root interest rate.
    function updateGivenSqrtInterestRateDelta(
        uint160 liquidity,
        uint160 rate,
        uint160 deltaRate,
        uint96 duration,
        uint256 transactionFee,
        bool isAdd
    ) internal pure returns (uint160 newRate, uint256 longAmount, uint256 shortAmount, uint256 fees) {
        newRate = isAdd ? rate + deltaRate : rate - deltaRate;

        longAmount = getLongFromSqrtInterestRate(liquidity, rate, deltaRate, newRate, !isAdd);

        shortAmount = getShortFromSqrtInterestRate(liquidity, deltaRate, duration, isAdd);

        fees = FeeCalculation.getFeesRemoval(isAdd ? longAmount : shortAmount, transactionFee);
        if (isAdd) longAmount -= fees;
        else shortAmount -= fees;
    }

    /// @dev Update the new square root interest rate given change in long positions in base denomination.
    /// @param liquidity The amount of liquidity of the pool.
    /// @param rate The pool's squared root Interest Rate.
    /// @param longAmount The amount of long positions.
    /// @param duration The time duration in seconds.
    /// @param transactionFee The fee that will be adjusted in the transaction.
    /// @return newRate The new squared root Interest Rate.
    /// @return shortAmount The amount of short positions to withdraw when depositing long positions in base denomination.
    /// The amount of short positions to deposit when withdrawing long positions in base denomination.
    /// @return fees The amount of short positions fee when depositing long positions in base denomination.
    /// The amount of long positions fee in base denominations fee when withdrawing long positions in base denomination.
    function updateGivenLong(
        uint160 liquidity,
        uint160 rate,
        uint256 longAmount,
        uint96 duration,
        uint256 transactionFee,
        bool isAdd
    ) internal pure returns (uint160 newRate, uint256 shortAmount, uint256 fees) {
        if (!isAdd) fees = FeeCalculation.getFeesAdditional(longAmount, transactionFee);

        newRate = getNewSqrtInterestRateGivenLong(liquidity, rate, longAmount + (isAdd ? 0 : fees), isAdd);

        shortAmount = getShortFromSqrtInterestRate(liquidity, isAdd ? rate - newRate : newRate - rate, duration, !isAdd);

        if (isAdd) {
            fees = FeeCalculation.getFeesRemoval(shortAmount, transactionFee);
            shortAmount -= fees;
        }
    }

    /// @dev Update the new square root interest rate given change in short positions.
    /// @param liquidity The amount of liquidity of the pool.
    /// @param rate The pool's squared root Interest Rate.
    /// @param shortAmount The amount of short positions.
    /// @param duration The time duration in seconds.
    /// @param transactionFee The fee that will be adjusted in the transaction.
    /// @return newRate The new squared root Interest Rate.
    /// @return longAmount The amount of long positions in base denomination to withdraw when depositing short positions.
    /// The amount of long positions in base denomination to deposit when withdrawing short positions.
    /// @return fees The amount of long positions fee in base denominations when depositing short positions.
    /// The amount of short positions fee when withdrawing short positions.
    function updateGivenShort(
        uint160 liquidity,
        uint160 rate,
        uint256 shortAmount,
        uint96 duration,
        uint256 transactionFee,
        bool isAdd
    ) internal pure returns (uint160 newRate, uint256 longAmount, uint256 fees) {
        if (!isAdd) fees = FeeCalculation.getFeesAdditional(shortAmount, transactionFee);

        uint160 deltaRate;
        (newRate, deltaRate) = getNewSqrtInterestRateGivenShort(liquidity, rate, shortAmount + (isAdd ? 0 : fees), duration, isAdd);

        longAmount = getLongFromSqrtInterestRate(liquidity, rate, deltaRate, newRate, !isAdd);

        if (isAdd) {
            fees = FeeCalculation.getFeesRemoval(longAmount, transactionFee);
            longAmount -= fees;
        }
    }

    /// @dev Update the new square root interest rate given sum of long positions in base denomination change and short position change.
    /// @param liquidity The amount of liquidity of the pool.
    /// @param rate The pool's squared root Interest Rate.
    /// @param sumAmount The sum amount of long positions in base denomination change and short position change.
    /// @param duration The time duration in seconds.
    /// @param transactionFee The fee that will be adjusted in the transaction.
    /// @param isAdd Increase square root interest rate if true. Decrease square root interest rate if false.
    /// @return newRate The new squared root Interest Rate.
    /// @return longAmount The amount of long positions in base denomination to withdraw when increasing square root interest rate.
    /// The amount of long positions in base denomination to deposit when decreasing square root interest rate.
    /// @return shortAmount The amount of short positions to deposit when increasing square root interest rate.
    /// The amount of short positions to withdraw when decreasing square root interest rate.
    /// @return fees The amount of long positions fee in base denominations when increasing square root interest rate.
    /// The amount of short positions fee when decreasing square root interest rate.
    function updateGivenSumLong(
        uint160 liquidity,
        uint160 rate,
        uint256 sumAmount,
        uint96 duration,
        uint256 transactionFee,
        bool isAdd
    ) internal pure returns (uint160 newRate, uint256 longAmount, uint256 shortAmount, uint256 fees) {
        uint256 amount = getShortOrLongFromGivenSum(liquidity, rate, sumAmount, duration, transactionFee, isAdd);

        if (isAdd) (newRate, ) = getNewSqrtInterestRateGivenShort(liquidity, rate, amount, duration, false);
        else newRate = getNewSqrtInterestRateGivenLong(liquidity, rate, amount, false);

        fees = FeeCalculation.getFeesRemoval(amount, transactionFee);
        amount -= fees;

        if (isAdd) {
            shortAmount = amount;
            longAmount = sumAmount - shortAmount;
        } else {
            longAmount = amount;
            shortAmount = sumAmount - longAmount;
        }
    }

    /// @dev Returns liquidity for a given long.
    /// @param rate The pool's squared root Interest Rate.
    /// @param longAmount The amount of long in base denomination change..
    /// @param roundUp Round up the result when true. Round down the result when false.
    function getLiquidityGivenLong(uint160 rate, uint256 longAmount, bool roundUp) private pure returns (uint160) {
        return FullMath.mulDiv(uint256(rate), longAmount, uint256(1) << 96, roundUp).toUint160();
    }

    /// @dev Returns liquidity for a given short.
    /// @param rate The pool's squared root Interest Rate.
    /// @param shortAmount The amount of short change.
    /// @param duration The time duration in seconds.
    /// @param roundUp Round up the result when true. Round down the result when false.
    function getLiquidityGivenShort(uint160 rate, uint256 shortAmount, uint96 duration, bool roundUp) private pure returns (uint160) {
        return FullMath.mulDiv(shortAmount, uint256(1) << 192, uint256(rate).unsafeMul(duration), roundUp).toUint160();
    }

    /// @dev Returns the new squared root interest rate given long positions in base denomination change.
    /// @param liquidity The liquidity of the pool.
    /// @param rate The pool's squared root Interest Rate.
    /// @param longAmount The amount long positions in base denomination change.
    /// @param isAdd Long positions increase when true. Long positions decrease when false.
    function getNewSqrtInterestRateGivenLong(uint160 liquidity, uint160 rate, uint256 longAmount, bool isAdd) private pure returns (uint160) {
        uint256 numerator;
        unchecked {
            numerator = uint256(liquidity) << 96;
        }

        uint256 product = longAmount.unsafeMul(rate);

        if (isAdd) {
            if (product.div(longAmount, false) == rate) {
                uint256 denominator = numerator + product;
                if (denominator >= numerator) {
                    return FullMath.mulDiv(numerator, rate, denominator, true).toUint160();
                }
            }

            uint256 denominator2 = numerator.div(rate, false);

            denominator2 += longAmount;
            return numerator.div(denominator2, true).toUint160();
        } else {
            if (product.div(longAmount, false) != rate || product >= numerator) revert NotEnoughLiquidityToBorrow();

            uint256 denominator = numerator.unsafeSub(product);
            return (FullMath.mulDiv(numerator, rate, denominator, true)).toUint160();
        }
    }

    /// @dev Returns the new squared root interest rate given short position change.
    /// @param liquidity The liquidity of the pool.
    /// @param rate The pool's squared root Interest Rate.
    /// @param shortAmount The amount short positions change.
    /// @param duration The time duration in seconds.
    /// @param isAdd Short positions increase when true. Short positions decrease when false.
    /// @return newRate The updated squared interest rate
    /// @return deltaRate The difference between the new and old squared interest rate
    function getNewSqrtInterestRateGivenShort(uint160 liquidity, uint160 rate, uint256 shortAmount, uint96 duration, bool isAdd) private pure returns (uint160 newRate, uint160 deltaRate) {
        uint256 denominator = uint256(liquidity).unsafeMul(duration);

        deltaRate = FullMath.mulDiv(shortAmount, uint256(1) << 192, denominator, !isAdd).toUint160();

        if (isAdd) newRate = rate + deltaRate;
        else if (rate > deltaRate) newRate = rate - deltaRate;
        else revert NotEnoughLiquidityToLend();
    }

    /// @dev Returns the long positions for a given interest rate.
    /// @param liquidity The liquidity of the pool.
    /// @param rate The pool's squared root Interest Rate.
    /// @param deltaRate The pool's delta rate in square root interest rate.
    /// @param newRate The new interest rate of the pool
    /// @param roundUp Increases in square root interest rate when true. Decrease in square root interest rate when false.
    function getLongFromSqrtInterestRate(uint160 liquidity, uint160 rate, uint160 deltaRate, uint160 newRate, bool roundUp) private pure returns (uint256) {
        uint256 numerator;
        unchecked {
            numerator = uint256(liquidity) << 96;
        }
        return roundUp ? FullMath.mulDiv(numerator, deltaRate, uint256(rate), true).div(newRate, true) : FullMath.mulDiv(numerator, deltaRate, uint256(newRate), false).div(rate, false);
    }

    /// @dev Returns the short positions for a given interest rate.
    /// @param liquidity The liquidity of the pool.
    /// @param deltaRate The pool's delta rate in square root interest rate.
    /// @param duration The time duration in seconds.
    /// @param roundUp Increases in square root interest rate when true. Decrease in square root interest rate when false.
    function getShortFromSqrtInterestRate(uint160 liquidity, uint160 deltaRate, uint96 duration, bool roundUp) private pure returns (uint256) {
        uint256 numerator = uint256(liquidity).unsafeMul(duration);
        return FullMath.mulDiv(uint256(numerator), uint256(deltaRate), uint256(1) << 192, roundUp);
    }

    /// @dev Get the short amount or long amount for given sum type transactions.
    /// @param liquidity The liquidity of the pool.
    /// @param rate The pool's squared root Interest Rate.
    /// @param sumAmount The given sum amount.
    /// @param duration The duration of the pool.
    /// @param transactionFee The transaction fee of the pool.
    /// @param isShort True if to calculate for short amount.
    /// False if to calculate for long amount.
    /// @return amount The short amount or long amount calculated.
    function getShortOrLongFromGivenSum(uint160 liquidity, uint160 rate, uint256 sumAmount, uint96 duration, uint256 transactionFee, bool isShort) private pure returns (uint256 amount) {
        uint256 negativeB = calculateNegativeB(liquidity, rate, sumAmount, duration, transactionFee, isShort);

        uint256 sqrtDiscriminant = calculateSqrtDiscriminant(liquidity, rate, sumAmount, duration, transactionFee, negativeB, isShort);

        amount = (negativeB - sqrtDiscriminant).shr(1, false);
    }

    /// @dev Calculate the negativeB.
    /// @param liquidity The liquidity of the pool.
    /// @param rate The pool's squared root Interest Rate.
    /// @param sumAmount The given sum amount.
    /// @param duration The duration of the pool.
    /// @param transactionFee The transaction fee of the pool.
    /// @param isShort True if to calculate for short amount.
    /// False if to calculate for long amount.
    /// @return negativeB The negative B calculated.
    function calculateNegativeB(uint160 liquidity, uint160 rate, uint256 sumAmount, uint96 duration, uint256 transactionFee, bool isShort) private pure returns (uint256 negativeB) {
        uint256 adjustment = (uint256(1) << 16).unsafeSub(transactionFee);

        uint256 negativeB0 = isShort ? getShort(liquidity, rate, duration, false) : getLong(liquidity, rate, false);
        uint256 negativeB1 = isShort
            ? FullMath.mulDiv(liquidity, uint256(1) << 112, uint256(rate).unsafeMul(adjustment), false)
            : FullMath.mulDiv(uint256(liquidity).unsafeMul(duration), rate, (uint256(1) << 176).unsafeMul(adjustment), false);
        uint256 negativeB2 = FullMath.mulDiv(sumAmount, uint256(1) << 16, adjustment, false);

        negativeB = negativeB0 + negativeB1 + negativeB2;
    }

    /// Dev Calculate the square root discriminant.
    /// @param liquidity The liquidity of the pool.
    /// @param rate The pool's squared root Interest Rate.
    /// @param sumAmount The given sum amount.
    /// @param duration The duration of the pool.
    /// @param transactionFee The transaction fee of the pool.
    /// @param negativeB The negative B calculated.
    /// @param isShort True if to calculate for short amount.
    /// False if to calculate for long amount.
    /// @return sqrtDiscriminant The square root disriminant calculated.
    function calculateSqrtDiscriminant(
        uint160 liquidity,
        uint160 rate,
        uint256 sumAmount,
        uint96 duration,
        uint256 transactionFee,
        uint256 negativeB,
        bool isShort
    ) private pure returns (uint256 sqrtDiscriminant) {
        uint256 denominator = isShort ? (uint256(1) << 174).unsafeMul((uint256(1) << 16).unsafeSub(transactionFee)) : uint256(rate).unsafeMul((uint256(1) << 16).unsafeSub(transactionFee));

        (uint256 a0, uint256 a1) = isShort ? FullMath.mul512(uint256(liquidity).unsafeMul(duration), rate) : FullMath.mul512(liquidity, uint256(1) << 114);

        (uint256 a00, uint256 a01) = FullMath.mul512(a0, sumAmount);
        (uint256 a10, uint256 a11) = FullMath.mul512(a1, sumAmount);

        if (a11 == 0 && a01.unsafeAdd(a10) >= a01) {
            a0 = a00;
            a1 = a01.unsafeAdd(a10);
            (a0, a1) = FullMath.div512(a0, a1, denominator, false);
        } else {
            (a0, a1) = FullMath.div512(a0, a1, denominator, false);

            (a00, a01) = FullMath.mul512(a0, sumAmount);
            (a10, a11) = FullMath.mul512(a1, sumAmount);

            if (a11 != 0 || a01.unsafeAdd(a10) < a01) revert CalculationOverload();
            a0 = a00;
            a1 = a01.unsafeAdd(a10);
        }

        (uint256 b0, uint256 b1) = FullMath.mul512(negativeB, negativeB);

        (b0, b1) = FullMath.sub512(b0, b1, a0, a1);

        sqrtDiscriminant = FullMath.sqrt512(b0, b1, true);
    }
}
