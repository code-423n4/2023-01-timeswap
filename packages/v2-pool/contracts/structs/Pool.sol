//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {SafeCast} from '@timeswap-labs/v2-library/contracts/SafeCast.sol';
import {Error} from '@timeswap-labs/v2-library/contracts/Error.sol';
import {Math} from '@timeswap-labs/v2-library/contracts/Math.sol';

import {ITimeswapV2Option} from '@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2Option.sol';

import {StrikeConversion} from '@timeswap-labs/v2-library/contracts/StrikeConversion.sol';

import {DurationCalculation} from '../libraries/DurationCalculation.sol';
import {DurationWeight} from '../libraries/DurationWeight.sol';
import {ConstantProduct} from '../libraries/ConstantProduct.sol';
import {ConstantSum} from '../libraries/ConstantSum.sol';
import {FeeCalculation} from '../libraries/FeeCalculation.sol';

import {ITimeswapV2PoolMintCallback} from '../interfaces/callbacks/ITimeswapV2PoolMintCallback.sol';
import {ITimeswapV2PoolBurnCallback} from '../interfaces/callbacks/ITimeswapV2PoolBurnCallback.sol';
import {ITimeswapV2PoolDeleverageCallback} from '../interfaces/callbacks/ITimeswapV2PoolDeleverageCallback.sol';
import {ITimeswapV2PoolLeverageCallback} from '../interfaces/callbacks/ITimeswapV2PoolLeverageCallback.sol';

import {LiquidityPosition, LiquidityPositionLibrary} from './LiquidityPosition.sol';

import {TimeswapV2PoolMint, TimeswapV2PoolBurn, TimeswapV2PoolDeleverage, TimeswapV2PoolLeverage, TimeswapV2PoolRebalance, TransactionLibrary} from '../enums/Transaction.sol';

import {TimeswapV2PoolCollectParam, TimeswapV2PoolMintParam, TimeswapV2PoolBurnParam, TimeswapV2PoolDeleverageParam, TimeswapV2PoolLeverageParam, TimeswapV2PoolRebalanceParam} from './Param.sol';
import {TimeswapV2PoolMintChoiceCallbackParam, TimeswapV2PoolBurnChoiceCallbackParam, TimeswapV2PoolDeleverageChoiceCallbackParam, TimeswapV2PoolLeverageChoiceCallbackParam} from './CallbackParam.sol';
/// @param liquidity The current total liquidity of the pool.
/// @param lastTimestamp The last block timestamp the pool was interacted with.
/// @param sqrtInterestRate The current square root interest rate of the pool. Follows UQ64.96.
/// @param long0Balance The current amount of long0 positions in the pool.
/// @param long1Balance The current amount of long1 positions in the pool.
/// @param long0FeeGrowth The global long0 position fee growth the last time the pool was interacted with.
/// @param long1FeeGrowth The global long1 position fee growth the last time the pool was interacted with.
/// @param shortFeeGrowth The global short position fee growth the last time the pool was interacted with.
/// @param long0ProtocolFees The amount of long0 position protocol fees earned.
/// @param long1ProtocolFees The amount of long1 position protocol fees earned.
/// @param shortProtocolFees The amount of short position protocol fees earned.
/// @param liquidityPositions The mapping of liquidity positions owned by liquidity providers.
struct Pool {
  uint160 liquidity;
  uint96 lastTimestamp;
  uint160 sqrtInterestRate;
  uint256 long0Balance;
  uint256 long1Balance;
  uint256 long0FeeGrowth;
  uint256 long1FeeGrowth;
  uint256 shortFeeGrowth;
  uint256 long0ProtocolFees;
  uint256 long1ProtocolFees;
  uint256 shortProtocolFees;
  mapping(address => LiquidityPosition) liquidityPositions;
}

library PoolLibrary {
  using LiquidityPositionLibrary for LiquidityPosition;
  using Math for uint256;
  using SafeCast for uint256;

  /// @dev It calculates the global fee growth, which is fee increased per unit of liquidity token.
  /// @param pool The state of the pool.
  /// @return long0FeeGrowth The global fee increased per unit of liquidity token for long0.
  /// @return long1FeeGrowth The global fee increased per unit of liquidity token for long1.
  /// @return  shortFeeGrowth The global fee increased per unit of liquidity token for short.
  function feeGrowth(
    Pool storage pool
  ) external view returns (uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth) {
    return (pool.long0FeeGrowth, pool.long1FeeGrowth, pool.shortFeeGrowth);
  }

  /// @param pool The state of the pool.
  /// @param owner The address to query the fees earned of.
  /// @return long0Fees The amount of long0 fees owned by the given address.
  /// @return long1Fees The amount of long1 fees owned by the given address.
  /// @return shortFees The amount of short fees owned by the given address.
  function feesEarnedOf(
    Pool storage pool,
    address owner
  ) external view returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees) {
    return pool.liquidityPositions[owner].feesEarnedOf(pool.long0FeeGrowth, pool.long1FeeGrowth, pool.shortFeeGrowth);
  }

  /// @param pool The state of the pool.
  /// @return long0ProtocolFees The amount of long0 protocol fees owned by the owner of the factory contract.
  /// @return long1ProtocolFees The amount of long1 protocol fees owned by the owner of the factory contract.
  /// @return shortProtocolFees The amount of short protocol fees owned by the owner of the factory contract.
  function protocolFeesEarned(
    Pool storage pool
  ) external view returns (uint256 long0ProtocolFees, uint256 long1ProtocolFees, uint256 shortProtocolFees) {
    return (pool.long0ProtocolFees, pool.long1ProtocolFees, pool.shortProtocolFees);
  }

  /// @dev Returns the amount of long0 and long1 adjusted for the protocol and transaction fee.
  /// @param pool The state of the pool.
  /// @return long0Amount The amount of long0 in the pool, adjusted for the protocol and transaction fee.
  /// @return long1Amount The amount of long1 in the pool, adjusted for the protocol and transaction fee.
  function totalLongBalanceAdjustFees(
    Pool storage pool,
    uint256 transactionFee
  ) external view returns (uint256 long0Amount, uint256 long1Amount) {
    long0Amount = FeeCalculation.removeFees(pool.long0Balance, transactionFee);
    long1Amount = FeeCalculation.removeFees(pool.long1Balance, transactionFee);
  }

  /// @dev Returns the amount of sum of long0 and long1 converted to base denomination in the pool.
  /// @dev Returns the amount of short positions in the pool.
  /// @param pool The state of the pool.
  /// @return longAmount The amount of sum of long0 and long1 converted to base denomination in the pool.
  /// @return shortAmount The amount of short in the pool.
  function totalPositions(
    Pool storage pool,
    uint256 maturity,
    uint96 blockTimestamp
  ) external view returns (uint256 longAmount, uint256 shortAmount) {
    longAmount = ConstantProduct.getLong(pool.liquidity, pool.sqrtInterestRate, false);
    shortAmount = ConstantProduct.getShort(
      pool.liquidity,
      pool.sqrtInterestRate,
      DurationCalculation.unsafeDurationFromNowToMaturity(maturity, blockTimestamp),
      false
    );
  }

  /// @dev Move short positions to short fee growth due to duration of the pool decreasing as time moves forward.
  /// @param liquidity The liquidity in the pool.
  /// @param rate The square root interest rate in the pool.
  /// @param shortFeeGrowth The previous short fee growth from last transaction in the pool.
  /// @param duration The duration time of the pool.
  /// @param blockTimestamp The block timestamp.
  /// @return newLastTimestamp The new current last timestamp.
  /// @return newShortFeeGrowth The newly updated short fee growth.
  function updateDurationWeight(
    uint160 liquidity,
    uint160 rate,
    uint256 shortFeeGrowth,
    uint96 duration,
    uint96 blockTimestamp
  ) private pure returns (uint96 newLastTimestamp, uint256 newShortFeeGrowth) {
    newLastTimestamp = blockTimestamp;
    newShortFeeGrowth = DurationWeight.update(
      liquidity,
      shortFeeGrowth,
      ConstantProduct.getShort(liquidity, rate, duration, false)
    );
  }

  /// @dev Move short positions to short fee growth due to duration of the pool decreasing as time moves forward when pool is before maturity.
  /// @param pool The state of the pool.
  /// @param blockTimestamp The block timestamp.
  function updateDurationWeightBeforeMaturity(Pool storage pool, uint96 blockTimestamp) private {
    if (pool.lastTimestamp < blockTimestamp)
      (pool.lastTimestamp, pool.shortFeeGrowth) = updateDurationWeight(
        pool.liquidity,
        pool.sqrtInterestRate,
        pool.shortFeeGrowth,
        DurationCalculation.unsafeDurationFromLastTimestampToNow(pool.lastTimestamp, blockTimestamp),
        blockTimestamp
      );
  }

  /// @dev Move short positions to short fee growth due to duration of the pool decreasing as time moves forward when pool is after maturity.
  /// @param pool The state of the pool.
  /// @param blockTimestamp The block timestamp.
  function updateDurationWeightAfterMaturity(Pool storage pool, uint256 maturity, uint96 blockTimestamp) private {
    (pool.lastTimestamp, pool.shortFeeGrowth) = updateDurationWeight(
      pool.liquidity,
      pool.sqrtInterestRate,
      pool.shortFeeGrowth,
      DurationCalculation.unsafeDurationFromLastTimestampToMaturity(pool.lastTimestamp, maturity),
      blockTimestamp
    );
  }

  /// @dev Transfer liquidity positions to another address.
  /// @notice Does not transfer the transaction fees earned by the sender.
  /// @param pool The state of the pool.
  /// @param to The receipient of the liquidity positions.
  /// @param liquidityAmount The amount of liquidity positions transferred.
  /// @param blockTimestamp The current block timestamp.
  function transferLiquidity(Pool storage pool, address to, uint160 liquidityAmount, uint96 blockTimestamp) external {
    // Update the state of the pool first for the short fee growth.
    if (pool.liquidity != 0) updateDurationWeightBeforeMaturity(pool, blockTimestamp);

    // Update the fee growth and fees of msg.sender.
    LiquidityPosition storage liquidityPosition = pool.liquidityPositions[msg.sender];

    liquidityPosition.update(pool.long0FeeGrowth, pool.long1FeeGrowth, pool.shortFeeGrowth);
    liquidityPosition.burn(liquidityAmount);

    // Update the fee growth and fees of receipient.
    LiquidityPosition storage newLiquidityPosition = pool.liquidityPositions[to];

    newLiquidityPosition.update(pool.long0FeeGrowth, pool.long1FeeGrowth, pool.shortFeeGrowth);
    newLiquidityPosition.mint(liquidityAmount);
  }

  /// @dev Transfer fees earned of the sender to another address.
  /// @notice Does not transfer the liquidity positions of the sender.
  /// @param pool The state of the pool.
  /// @param to The receipient of the transaction fees.
  /// @param long0Fees The amount of long0 position fees transferrred.
  /// @param long1Fees The amount of long1 position fees transferrred.
  /// @param shortFees The amount of short position fees transferrred.
  /// @param blockTimestamp The current block timestamp.
  function transferFees(
    Pool storage pool,
    uint256 maturity,
    address to,
    uint256 long0Fees,
    uint256 long1Fees,
    uint256 shortFees,
    uint96 blockTimestamp
  ) external {
    // Update the state of the pool first for the short fee growth.
    if (pool.liquidity != 0) {
      if (maturity > blockTimestamp) updateDurationWeightBeforeMaturity(pool, blockTimestamp);
      else if (pool.lastTimestamp < maturity) updateDurationWeightAfterMaturity(pool, maturity, blockTimestamp);
    }
    // Update the fee growth and fees of msg.sender.
    LiquidityPosition storage liquidityPosition = pool.liquidityPositions[msg.sender];

    liquidityPosition.update(pool.long0FeeGrowth, pool.long1FeeGrowth, pool.shortFeeGrowth);
    liquidityPosition.burnFees(long0Fees, long1Fees, shortFees);

    // Update the fee growth and fees of recipient.
    liquidityPosition = pool.liquidityPositions[to];

    liquidityPosition.update(pool.long0FeeGrowth, pool.long1FeeGrowth, pool.shortFeeGrowth);
    liquidityPosition.mintFees(long0Fees, long1Fees, shortFees);
  }

  /// @dev initializes the pool with the given parameters.
  /// @param pool The state of the pool.
  /// @param rate The square root of the interest rate of the pool.
  function initialize(Pool storage pool, uint160 rate) external {
    if (pool.liquidity != 0) Error.alreadyHaveLiquidity(pool.liquidity);
    pool.sqrtInterestRate = rate;
  }

  /// @dev Collects the protocol fees of the pool.
  /// @dev only protocol owner can call this function.
  /// @dev if the owner enters an amount which is greater than the fee amount they have earned, withdraw only the amount they have.
  /// @param pool The state of the pool.
  /// @param long0Requested The maximum amount of long0 positions wanted.
  /// @param long1Requested The maximum amount of long1 positions wanted.
  /// @param shortRequested The maximum amount of short positions wanted.
  /// @return long0Amount The amount of long0 collected.
  /// @return long1Amount The amount of long1 collected.
  /// @return shortAmount The amount of short collected.
  function collectProtocolFees(
    Pool storage pool,
    uint256 long0Requested,
    uint256 long1Requested,
    uint256 shortRequested
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount) {
    if (long0Requested >= pool.long0ProtocolFees) {
      long0Amount = pool.long0ProtocolFees;
      pool.long0ProtocolFees = 0;
    } else {
      long0Amount = long0Requested;
      pool.long0ProtocolFees = pool.long0ProtocolFees.unsafeSub(long0Requested);
    }

    if (long1Requested >= pool.long1ProtocolFees) {
      long1Amount = pool.long1ProtocolFees;
      pool.long1ProtocolFees = 0;
    } else {
      long1Amount = long1Requested;
      pool.long1ProtocolFees = pool.long1ProtocolFees.unsafeSub(long1Requested);
    }

    if (shortRequested >= pool.shortProtocolFees) {
      shortAmount = pool.shortProtocolFees;
      pool.shortProtocolFees = 0;
    } else {
      shortAmount = shortRequested;
      pool.shortProtocolFees = pool.shortProtocolFees.unsafeSub(shortRequested);
    }
  }

  /// @dev Collects the transaction fees of the pool.
  /// @dev only liquidity provider can call this function.
  /// @dev if the owner enters an amount which is greater than the fee amount they have earned, withdraw only the amount they have.
  /// @param pool The state of the pool.
  /// @param blockTimestamp The current block timestamp.
  /// @param long0Requested The maximum amount of long0 positions wanted.
  /// @param long1Requested The maximum amount of long1 positions wanted.
  /// @param shortRequested The maximum amount of short positions wanted.
  /// @return long0Amount The amount of long0 collected.
  /// @return long1Amount The amount of long1 collected.
  /// @return shortAmount The amount of short collected.
  function collectTransactionFees(
    Pool storage pool,
    uint256 maturity,
    uint256 long0Requested,
    uint256 long1Requested,
    uint256 shortRequested,
    uint96 blockTimestamp
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount) {
    // Update the state of the pool first for the short fee growth.
    if (pool.liquidity != 0) {
      if (maturity > blockTimestamp) updateDurationWeightBeforeMaturity(pool, blockTimestamp);
      else if (pool.lastTimestamp < maturity) updateDurationWeightAfterMaturity(pool, maturity, blockTimestamp);
    }

    // Update the fee growth and fees of caller.
    LiquidityPosition storage liquidityPosition = pool.liquidityPositions[msg.sender];

    if (pool.liquidity != 0) liquidityPosition.update(pool.long0FeeGrowth, pool.long1FeeGrowth, pool.shortFeeGrowth);

    (long0Amount, long1Amount, shortAmount) = liquidityPosition.collectTransactionFees(
      long0Requested,
      long1Requested,
      shortRequested
    );
  }

  /// @dev deposit Short and Long tokens and mints Liquidity
  /// @dev can be only called before the maturity.
  /// @param pool The state of the pool.
  /// @param param it is a struct that contains the parameters of the mint function.
  /// @param blockTimestamp The current block timestamp.
  /// @return liquidityAmount The amount of liquidity minted.
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function mint(
    Pool storage pool,
    TimeswapV2PoolMintParam memory param,
    uint96 blockTimestamp
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data)
  {
    // Update the state of the pool first for the short fee growth.
    if (pool.liquidity != 0) updateDurationWeightBeforeMaturity(pool, blockTimestamp);
    // Update the fee growth and fees of caller.
    LiquidityPosition storage liquidityPosition = pool.liquidityPositions[param.to];

    uint256 longAmount;
    if (param.transaction == TimeswapV2PoolMint.GivenLiquidity) {
      (longAmount, shortAmount) = ConstantProduct.calculateGivenLiquidityDelta(
        pool.sqrtInterestRate,
        liquidityAmount = param.delta.toUint160(),
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        true
      );

      if (longAmount == 0) Error.zeroOutput();
      if (shortAmount == 0) Error.zeroOutput();
    } else if (param.transaction == TimeswapV2PoolMint.GivenLong) {
      (liquidityAmount, shortAmount) = ConstantProduct.calculateGivenLiquidityLong(
        pool.sqrtInterestRate,
        longAmount = param.delta,
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        true
      );

      if (liquidityAmount == 0) Error.zeroOutput();
      if (shortAmount == 0) Error.zeroOutput();
    } else if (param.transaction == TimeswapV2PoolMint.GivenShort) {
      (liquidityAmount, longAmount) = ConstantProduct.calculateGivenLiquidityShort(
        pool.sqrtInterestRate,
        shortAmount = param.delta,
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        true
      );

      if (liquidityAmount == 0) Error.zeroOutput();
      if (longAmount == 0) Error.zeroOutput();
    } else if (param.transaction == TimeswapV2PoolMint.GivenLarger) {
      (liquidityAmount, longAmount, shortAmount) = ConstantProduct.calculateGivenLiquidityLargerOrSmaller(
        pool.sqrtInterestRate,
        param.delta,
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        true
      );

      if (liquidityAmount == 0) Error.zeroOutput();
      if (longAmount == 0) Error.zeroOutput();
      if (shortAmount == 0) Error.zeroOutput();
    }

    // Ask the msg.sender how much long0 position and long1 position wanted.
    (long0Amount, long1Amount, data) = ITimeswapV2PoolMintCallback(msg.sender).timeswapV2PoolMintChoiceCallback(
      TimeswapV2PoolMintChoiceCallbackParam({
        strike: param.strike,
        maturity: param.maturity,
        longAmount: longAmount,
        shortAmount: shortAmount,
        liquidityAmount: liquidityAmount,
        data: param.data
      })
    );
    Error.checkEnough(StrikeConversion.combine(long0Amount, long1Amount, param.strike, false), longAmount);

    if (long0Amount != 0) pool.long0Balance += long0Amount;
    if (long1Amount != 0) pool.long1Balance += long1Amount;

    liquidityPosition.mint(liquidityAmount);
    pool.liquidity += liquidityAmount;
  }

  /// @dev burn Liquidity and receive Short and Long tokens
  /// @dev can be only called before the maturity.
  /// @dev after the maturity of the pool, the long0 and long1 tokens are zero. And the short tokens are added into the transaction fees.
  /// @dev if the user wants to burn the liquidity after the maturity, they should call the collectTransactionFee function.
  /// @param pool The state of the pool.
  /// @param param it is a struct that contains the parameters of the burn function.
  /// @param blockTimestamp The current block timestamp.
  /// @return liquidityAmount The amount of liquidity burned.
  /// @return long0Amount The amount of long0 withdrawn.
  /// @return long1Amount The amount of long1 withdrawn.
  /// @return shortAmount The amount of short withdrawn.
  /// @return data the data used for the callbacks.
  function burn(
    Pool storage pool,
    TimeswapV2PoolBurnParam memory param,
    uint96 blockTimestamp
  )
    external
    returns (uint160 liquidityAmount, uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data)
  {
    if (pool.liquidity == 0) Error.requireLiquidity();

    // Update the state of the pool first for the short fee growth.
    updateDurationWeightBeforeMaturity(pool, blockTimestamp);

    LiquidityPosition storage liquidityPosition = pool.liquidityPositions[msg.sender];

    liquidityPosition.update(pool.long0FeeGrowth, pool.long1FeeGrowth, pool.shortFeeGrowth);

    uint256 longAmount;
    if (param.transaction == TimeswapV2PoolBurn.GivenLiquidity) {
      (longAmount, shortAmount) = ConstantProduct.calculateGivenLiquidityDelta(
        pool.sqrtInterestRate,
        liquidityAmount = param.delta.toUint160(),
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        false
      );

      if (longAmount == 0) Error.zeroOutput();
      if (shortAmount == 0) Error.zeroOutput();
    } else if (param.transaction == TimeswapV2PoolBurn.GivenLong) {
      (liquidityAmount, shortAmount) = ConstantProduct.calculateGivenLiquidityLong(
        pool.sqrtInterestRate,
        longAmount = param.delta,
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        false
      );

      if (liquidityAmount == 0) Error.zeroOutput();
      if (shortAmount == 0) Error.zeroOutput();
    } else if (param.transaction == TimeswapV2PoolBurn.GivenShort) {
      (liquidityAmount, longAmount) = ConstantProduct.calculateGivenLiquidityShort(
        pool.sqrtInterestRate,
        shortAmount = param.delta,
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        false
      );

      if (liquidityAmount == 0) Error.zeroOutput();
      if (longAmount == 0) Error.zeroOutput();
    } else if (param.transaction == TimeswapV2PoolBurn.GivenSmaller) {
      (liquidityAmount, longAmount, shortAmount) = ConstantProduct.calculateGivenLiquidityLargerOrSmaller(
        pool.sqrtInterestRate,
        param.delta,
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        false
      );

      if (liquidityAmount == 0) Error.zeroOutput();
      if (longAmount == 0) Error.zeroOutput();
      if (shortAmount == 0) Error.zeroOutput();
    }

    (long0Amount, long1Amount, data) = ITimeswapV2PoolBurnCallback(msg.sender).timeswapV2PoolBurnChoiceCallback(
      TimeswapV2PoolBurnChoiceCallbackParam({
        strike: param.strike,
        maturity: param.maturity,
        long0Balance: pool.long0Balance,
        long1Balance: pool.long1Balance,
        longAmount: longAmount,
        shortAmount: shortAmount,
        liquidityAmount: liquidityAmount,
        data: param.data
      })
    );
    Error.checkEnough(longAmount, StrikeConversion.combine(long0Amount, long1Amount, param.strike, true));

    if (long0Amount != 0) pool.long0Balance -= long0Amount;
    if (long1Amount != 0) pool.long1Balance -= long1Amount;

    pool.liquidity -= liquidityAmount;
    pool.liquidityPositions[msg.sender].burn(liquidityAmount);
  }

  /// @dev deposit Long tokens and receive Short tokens
  /// @dev can be only called before the maturity.
  /// @param pool The state of the pool.
  /// @param param it is a struct that contains the parameters of the deleverage function
  /// @param transactionFee The transaction fee rate.
  /// @param protocolFee The protocol fee rate.
  /// @param blockTimestamp The current block timestamp.
  /// @return long0Amount The amount of long0 deposited.
  /// @return long1Amount The amount of long1 deposited.
  /// @return shortAmount The amount of short received.
  /// @return data the data used for the callbacks.
  function deleverage(
    Pool storage pool,
    TimeswapV2PoolDeleverageParam memory param,
    uint256 transactionFee,
    uint256 protocolFee,
    uint96 blockTimestamp
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data) {
    if (pool.liquidity == 0) Error.requireLiquidity();
    // Update the state of the pool first for the short fee growth.
    updateDurationWeightBeforeMaturity(pool, blockTimestamp);

    uint256 longAmount;
    uint256 shortFees;
    if (param.transaction == TimeswapV2PoolDeleverage.GivenDeltaSqrtInterestRate) {
      (pool.sqrtInterestRate, longAmount, shortAmount, shortFees) = ConstantProduct.updateGivenSqrtInterestRateDelta(
        pool.liquidity,
        pool.sqrtInterestRate,
        param.delta.toUint160(),
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        transactionFee,
        false
      );

      if (longAmount == 0) Error.zeroOutput();
      if (shortAmount == 0) Error.zeroOutput();
    } else if (param.transaction == TimeswapV2PoolDeleverage.GivenLong) {
      (pool.sqrtInterestRate, shortAmount, shortFees) = ConstantProduct.updateGivenLong(
        pool.liquidity,
        pool.sqrtInterestRate,
        longAmount = param.delta,
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        transactionFee,
        true
      );

      if (shortAmount == 0) Error.zeroOutput();
    } else if (param.transaction == TimeswapV2PoolDeleverage.GivenShort) {
      (pool.sqrtInterestRate, longAmount, shortFees) = ConstantProduct.updateGivenShort(
        pool.liquidity,
        pool.sqrtInterestRate,
        shortAmount = param.delta,
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        transactionFee,
        false
      );

      if (longAmount == 0) Error.zeroOutput();
    } else if (param.transaction == TimeswapV2PoolDeleverage.GivenSum) {
      (pool.sqrtInterestRate, longAmount, shortAmount, shortFees) = ConstantProduct.updateGivenSumLong(
        pool.liquidity,
        pool.sqrtInterestRate,
        param.delta,
        DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
        transactionFee,
        true
      );

      if (longAmount == 0) Error.zeroOutput();
      if (shortAmount == 0) Error.zeroOutput();
    }

    (pool.shortFeeGrowth, pool.shortProtocolFees) = FeeCalculation.update(
      pool.liquidity,
      pool.shortFeeGrowth,
      pool.shortProtocolFees,
      shortFees,
      protocolFee
    );

    (long0Amount, long1Amount, data) = ITimeswapV2PoolDeleverageCallback(msg.sender)
      .timeswapV2PoolDeleverageChoiceCallback(
        TimeswapV2PoolDeleverageChoiceCallbackParam({
          strike: param.strike,
          maturity: param.maturity,
          longAmount: longAmount,
          shortAmount: shortAmount,
          data: param.data
        })
      );
    Error.checkEnough(StrikeConversion.combine(long0Amount, long1Amount, param.strike, false), longAmount);

    if (long0Amount != 0) pool.long0Balance += long0Amount;
    if (long1Amount != 0) pool.long1Balance += long1Amount;
  }

  /// @dev deposit Short tokens and receive Long tokens
  /// @dev can be only called before the maturity.
  /// @param pool The state of the pool.
  /// @param param it is a struct that contains the parameters of the leverage function.
  /// @param transactionFee The transaction fee rate.
  /// @param protocolFee The protocol fee rate.
  /// @param blockTimestamp The current block timestamp.
  /// @return long0Amount The amount of long0 received.
  /// @return long1Amount The amount of long1 received.
  /// @return shortAmount The amount of short deposited.
  /// @return data the data used for the callbacks.
  function leverage(
    Pool storage pool,
    TimeswapV2PoolLeverageParam memory param,
    uint256 transactionFee,
    uint256 protocolFee,
    uint96 blockTimestamp
  ) external returns (uint256 long0Amount, uint256 long1Amount, uint256 shortAmount, bytes memory data) {
    if (pool.liquidity == 0) Error.requireLiquidity();

    // Update the state of the pool first for the short fee growth.
    updateDurationWeightBeforeMaturity(pool, blockTimestamp);

    uint256 long0BalanceAdjustFees = FeeCalculation.removeFees(pool.long0Balance, transactionFee);
    uint256 long1BalanceAdjustFees = FeeCalculation.removeFees(pool.long1Balance, transactionFee);
    {
      uint256 longAmount;
      if (param.transaction == TimeswapV2PoolLeverage.GivenDeltaSqrtInterestRate) {
        (pool.sqrtInterestRate, longAmount, shortAmount, ) = ConstantProduct.updateGivenSqrtInterestRateDelta(
          pool.liquidity,
          pool.sqrtInterestRate,
          param.delta.toUint160(),
          DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
          transactionFee,
          true
        );

        if (longAmount == 0) Error.zeroOutput();
        if (shortAmount == 0) Error.zeroOutput();
      } else if (param.transaction == TimeswapV2PoolLeverage.GivenLong) {
        (pool.sqrtInterestRate, shortAmount, ) = ConstantProduct.updateGivenLong(
          pool.liquidity,
          pool.sqrtInterestRate,
          longAmount = param.delta,
          DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
          transactionFee,
          false
        );

        if (shortAmount == 0) Error.zeroOutput();
      } else if (param.transaction == TimeswapV2PoolLeverage.GivenShort) {
        (pool.sqrtInterestRate, longAmount, ) = ConstantProduct.updateGivenShort(
          pool.liquidity,
          pool.sqrtInterestRate,
          shortAmount = param.delta,
          DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
          transactionFee,
          true
        );

        if (longAmount == 0) Error.zeroOutput();
      } else if (param.transaction == TimeswapV2PoolLeverage.GivenSum) {
        (pool.sqrtInterestRate, longAmount, shortAmount, ) = ConstantProduct.updateGivenSumLong(
          pool.liquidity,
          pool.sqrtInterestRate,
          param.delta,
          DurationCalculation.unsafeDurationFromNowToMaturity(param.maturity, blockTimestamp),
          transactionFee,
          false
        );
        if (longAmount == 0) Error.zeroOutput();
        if (shortAmount == 0) Error.zeroOutput();
      }

      (long0Amount, long1Amount, data) = ITimeswapV2PoolLeverageCallback(msg.sender)
        .timeswapV2PoolLeverageChoiceCallback(
          TimeswapV2PoolLeverageChoiceCallbackParam({
            strike: param.strike,
            maturity: param.maturity,
            long0Balance: long0BalanceAdjustFees,
            long1Balance: long1BalanceAdjustFees,
            longAmount: longAmount,
            shortAmount: shortAmount,
            data: param.data
          })
        );
      Error.checkEnough(longAmount, StrikeConversion.combine(long0Amount, long1Amount, param.strike, true));
    }

    if (long0Amount != 0) {
      uint256 long0Fees;
      if (long0Amount == long0BalanceAdjustFees) {
        long0Fees = pool.long0Balance.unsafeSub(long0Amount);
        pool.long0Balance = 0;
      } else {
        long0Fees = FeeCalculation.getFeesAdditional(long0Amount, transactionFee);
        pool.long0Balance -= (long0Amount + long0Fees);
      }

      (pool.long0FeeGrowth, pool.long0ProtocolFees) = FeeCalculation.update(
        pool.liquidity,
        pool.long0FeeGrowth,
        pool.long0ProtocolFees,
        long0Fees,
        protocolFee
      );
    }

    if (long1Amount != 0) {
      uint256 long1Fees;
      if (long1Amount == long1BalanceAdjustFees) {
        long1Fees = pool.long1Balance.unsafeSub(long1Amount);
        pool.long1Balance = 0;
      } else {
        long1Fees = FeeCalculation.getFeesAdditional(long1Amount, transactionFee);

        pool.long1Balance -= (long1Amount + long1Fees);
      }

      (pool.long1FeeGrowth, pool.long1ProtocolFees) = FeeCalculation.update(
        pool.liquidity,
        pool.long1FeeGrowth,
        pool.long1ProtocolFees,
        long1Fees,
        protocolFee
      );
    }
  }

  /// @dev Deposit Long0 to receive Long1 or deposit Long1 to receive Long0.
  /// @dev can be only called before the maturity.
  /// @param pool The state of the pool.
  /// @param param it is a struct that contains the parameters of the rebalance function.
  /// @param transactionFee The transaction fee rate.
  /// @param protocolFee The protocol fee rate.
  /// @return long0Amount The amount of long0 received/deposited.
  /// @return long1Amount The amount of long1 deposited/received.
  function rebalance(
    Pool storage pool,
    TimeswapV2PoolRebalanceParam memory param,
    uint256 transactionFee,
    uint256 protocolFee
  ) external returns (uint256 long0Amount, uint256 long1Amount) {
    if (pool.liquidity == 0) Error.requireLiquidity();

    // No need to update short fee growth.

    uint256 longFees;
    if (param.isLong0ToLong1) {
      if (param.transaction == TimeswapV2PoolRebalance.GivenLong0) {
        (long1Amount, longFees) = ConstantSum.calculateGivenLongIn(
          param.strike,
          long0Amount = param.delta,
          transactionFee,
          true
        );

        if (long1Amount == 0) Error.zeroOutput();

        pool.long1Balance -= (long1Amount + longFees);
      } else if (param.transaction == TimeswapV2PoolRebalance.GivenLong1) {
        uint256 long1AmountAdjustFees = FeeCalculation.removeFees(pool.long0Balance, transactionFee);

        if ((long1Amount = param.delta) == long1AmountAdjustFees) {
          long0Amount = ConstantSum.calculateGivenLongOutAlreadyAdjustFees(param.strike, pool.long1Balance, true);

          longFees = pool.long1Balance.unsafeSub(long1Amount);
          pool.long1Balance = 0;
        } else {
          (long0Amount, longFees) = ConstantSum.calculateGivenLongOut(param.strike, long1Amount, transactionFee, true);

          pool.long1Balance -= (long1Amount + longFees);
        }

        if (long0Amount == 0) Error.zeroOutput();
      }

      pool.long0Balance += long0Amount;

      (pool.long1FeeGrowth, pool.long1ProtocolFees) = FeeCalculation.update(
        pool.liquidity,
        pool.long1FeeGrowth,
        pool.long1ProtocolFees,
        longFees,
        protocolFee
      );
    } else {
      if (param.transaction == TimeswapV2PoolRebalance.GivenLong0) {
        uint256 long0AmountAdjustFees = FeeCalculation.removeFees(pool.long0Balance, transactionFee);

        if ((long0Amount = param.delta) == long0AmountAdjustFees) {
          long1Amount = ConstantSum.calculateGivenLongOutAlreadyAdjustFees(param.strike, pool.long0Balance, false);

          longFees = pool.long0Balance.unsafeSub(long0Amount);
          pool.long0Balance = 0;
        } else {
          (long1Amount, longFees) = ConstantSum.calculateGivenLongOut(param.strike, long0Amount, transactionFee, false);

          pool.long0Balance -= (long0Amount + longFees);
        }

        if (long1Amount == 0) Error.zeroOutput();
      } else if (param.transaction == TimeswapV2PoolRebalance.GivenLong1) {
        (long0Amount, longFees) = ConstantSum.calculateGivenLongIn(
          param.strike,
          long1Amount = param.delta,
          transactionFee,
          false
        );

        if (long0Amount == 0) Error.zeroOutput();

        pool.long0Balance -= (long0Amount + longFees);
      }

      pool.long1Balance += long1Amount;

      (pool.long0FeeGrowth, pool.long0ProtocolFees) = FeeCalculation.update(
        pool.liquidity,
        pool.long0FeeGrowth,
        pool.long0ProtocolFees,
        longFees,
        protocolFee
      );
    }
  }
}
