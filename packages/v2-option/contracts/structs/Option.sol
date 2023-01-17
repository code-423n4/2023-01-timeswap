//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {StrikeConversion} from '@timeswap-labs/v2-library/contracts/StrikeConversion.sol';
import {Error} from '@timeswap-labs/v2-library/contracts/Error.sol';
import {Math} from '@timeswap-labs/v2-library/contracts/Math.sol';

import {Proportion} from '../libraries/Proportion.sol';

import {TimeswapV2OptionPosition, PositionLibrary} from '../enums/Position.sol';
import {TimeswapV2OptionMint, TimeswapV2OptionBurn, TimeswapV2OptionSwap, TimeswapV2OptionCollect, TransactionLibrary} from '../enums/Transaction.sol';

/// @dev The state per option of a given strike and maturity
/// @param totalLong0 The total amount of long token0 supply.
/// @param totalLong1 The total amount of long token1 supply.
/// @param long0 The mapping of addresses to long token0 owned.
/// @param long1 The mapping of addresses to long token1 owned.
/// @param short The mapping of addresses to short owned.
/// @notice The sum of strike converted totalLong0 and strike converted totalLong1 is the total amount of short token supply.
struct Option {
  uint256 totalLong0;
  uint256 totalLong1;
  mapping(address => uint256) long0;
  mapping(address => uint256) long1;
  mapping(address => uint256) short;
}

/// @dev internal library handling important business logic of the option.
library OptionLibrary {
  using Math for uint256;
  using Proportion for uint256;

  /// @dev Get the total position of Long0, Long1, or Short.
  /// @param option The option struct stored.
  /// @param strike The strike of the option.
  /// @param position The position being inquired.
  /// @return balance The total supply positions result.
  function totalPosition(
    Option storage option,
    uint256 strike,
    TimeswapV2OptionPosition position
  ) internal view returns (uint256 balance) {
    if (position == TimeswapV2OptionPosition.Long0) balance = option.totalLong0;
    else if (position == TimeswapV2OptionPosition.Long1) balance = option.totalLong1;
    else if (position == TimeswapV2OptionPosition.Short)
      balance = StrikeConversion.combine(option.totalLong0, option.totalLong1, strike, true);
  }

  /// @dev Get the position of Long0, Long1, or Short owned by an address.
  /// @param option The option struct stored.
  /// @param owner The owner being inquired upon.
  /// @param position The position being inquired.
  /// @return balance The total positions owned result.
  function positionOf(
    Option storage option,
    address owner,
    TimeswapV2OptionPosition position
  ) internal view returns (uint256 balance) {
    if (position == TimeswapV2OptionPosition.Long0) balance = option.long0[owner];
    else if (position == TimeswapV2OptionPosition.Long1) balance = option.long1[owner];
    else if (position == TimeswapV2OptionPosition.Short) balance = option.short[owner];
  }

  /// @dev Transfer position of Long0, Long1, or Short to an address.
  /// @param option The option struct stored.
  /// @param to The target recipient.
  /// @param position The position being inquired.
  /// @param amount The amount being transferred.
  function transferPosition(
    Option storage option,
    address to,
    TimeswapV2OptionPosition position,
    uint256 amount
  ) internal {
    if (position == TimeswapV2OptionPosition.Long0) {
      option.long0[msg.sender] -= amount;
      option.long0[to] += amount;
    } else if (position == TimeswapV2OptionPosition.Long1) {
      option.long1[to] += amount;
      option.long1[msg.sender] -= amount;
    } else if (position == TimeswapV2OptionPosition.Short) {
      option.short[msg.sender] -= amount;
      option.short[to] += amount;
    }
  }

  /// @dev Handles main mint logic.
  /// @param option The option struct stored.
  /// @param strike The strike of the option.
  /// @param long0To The recipient of long0 token.
  /// @param long1To The recipient of long1 token.
  /// @param shortTo The recipient of short token.
  /// @param transaction The mint transaction type.
  /// @param amount0 The first amount based on transaction type.
  /// @param amount1 The second amount based on transaction type.
  /// @return token0AndLong0Amount The amount of token0 deposited and long0 minted.
  /// @return token1AndLong1Amount The amount of token1 deposited and long1 minted.
  /// @return shortAmount The amount of short minted.
  function mint(
    Option storage option,
    uint256 strike,
    address long0To,
    address long1To,
    address shortTo,
    TimeswapV2OptionMint transaction,
    uint256 amount0,
    uint256 amount1
  ) internal returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, uint256 shortAmount) {
    if (transaction == TimeswapV2OptionMint.GivenTokensAndLongs)
      shortAmount = StrikeConversion.combine(
        token0AndLong0Amount = amount0,
        token1AndLong1Amount = amount1,
        strike,
        false
      );
    else if (transaction == TimeswapV2OptionMint.GivenShorts) {
      shortAmount = amount0 + amount1;
      token0AndLong0Amount = StrikeConversion.turn(amount0, strike, false, true);
      token1AndLong1Amount = StrikeConversion.turn(amount1, strike, true, true);
    }

    if (token0AndLong0Amount != 0) {
      option.totalLong0 += token0AndLong0Amount;
      option.long0[long0To] += token0AndLong0Amount;
    }

    if (token1AndLong1Amount != 0) {
      option.totalLong1 += token1AndLong1Amount;
      option.long1[long1To] += token1AndLong1Amount;
    }

    option.short[shortTo] += shortAmount;

    // Checks overflow. Reverts when overflow.
    StrikeConversion.combine(option.totalLong0, option.totalLong1, strike, true);
  }

  /// @dev Handles main burn logic.
  /// @param option The option struct stored.
  /// @param strike The strike of the option.
  /// @param transaction The burn transaction type.
  /// @param amount0 The first amount based on transaction type.
  /// @param amount1 The second amount based on transaction type.
  /// @return token0AndLong0Amount The amount of token0 withdrawn and long0 burnt.
  /// @return token1AndLong1Amount The amount of token1 withdrawn and long1 burnt.
  /// @return shortAmount The amount of short burnt.
  function burn(
    Option storage option,
    uint256 strike,
    TimeswapV2OptionBurn transaction,
    uint256 amount0,
    uint256 amount1
  ) internal returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, uint256 shortAmount) {
    if (transaction == TimeswapV2OptionBurn.GivenTokensAndLongs)
      shortAmount = StrikeConversion.combine(
        token0AndLong0Amount = amount0,
        token1AndLong1Amount = amount1,
        strike,
        true
      );
    else if (transaction == TimeswapV2OptionBurn.GivenShorts) {
      shortAmount = amount0 + amount1;
      token0AndLong0Amount = StrikeConversion.turn(amount0, strike, false, false);
      token1AndLong1Amount = StrikeConversion.turn(amount1, strike, true, false);
    }

    option.totalLong0 -= token0AndLong0Amount;
    option.totalLong1 -= token1AndLong1Amount;
  }

  /// @dev Handles main mint logic.
  /// @param option The option struct stored.
  /// @param strike The strike of the option.
  /// @param longTo The recipient of long0 or long1 token.
  /// @param isLong0ToLong1 True if transforming long0 for long1 and false if transforming long1 for long0.
  /// @param transaction The swap transaction type.
  /// @param amount The amount based on transaction type.
  /// @return token0AndLong0Amount If direction is Long0ToLong1, the amount of token0 withdrawn and long0 burnt.
  /// If direction is Long1ToLong0, the amount of token0 deposited and long0 minted.
  /// @return token1AndLong1Amount If direction is Long0ToLong1, the amount of token1 deposited and long1 minted.
  /// If direction is Long1ToLong0, the amount of token1 withdrawn and long1 burnt.
  function swap(
    Option storage option,
    uint256 strike,
    address longTo,
    bool isLong0ToLong1,
    TimeswapV2OptionSwap transaction,
    uint256 amount
  ) internal returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount) {
    if (transaction == TimeswapV2OptionSwap.GivenToken0AndLong0) {
      token0AndLong0Amount = amount;
      token1AndLong1Amount = StrikeConversion.convert(token0AndLong0Amount, strike, true, isLong0ToLong1);
    } else if (transaction == TimeswapV2OptionSwap.GivenToken1AndLong1) {
      token1AndLong1Amount = amount;
      token0AndLong0Amount = StrikeConversion.convert(token1AndLong1Amount, strike, false, !isLong0ToLong1);
    }

    if (isLong0ToLong1) {
      option.totalLong0 -= token0AndLong0Amount;
      option.totalLong1 += token1AndLong1Amount;
      option.long1[longTo] += token1AndLong1Amount;
    } else {
      option.totalLong1 -= token1AndLong1Amount;
      option.totalLong0 += token0AndLong0Amount;
      option.long0[longTo] += token0AndLong0Amount;
    }
  }

  /// @dev Handles main mint logic.
  /// @param option The option struct stored.
  /// @param strike The strike of the option.
  /// @param transaction The collect transaction type.
  /// @param amount The amount based on transaction type.
  /// @return token0Amount The token0 amount withdrawn.
  /// @return token1Amount The token1 amount withdrawn.
  /// @return shortAmount The short amount burnt.
  function collect(
    Option storage option,
    uint256 strike,
    TimeswapV2OptionCollect transaction,
    uint256 amount
  ) internal returns (uint256 token0Amount, uint256 token1Amount, uint256 shortAmount) {
    uint256 denominator = StrikeConversion.combine(option.totalLong0, option.totalLong1, strike, true);

    if (transaction == TimeswapV2OptionCollect.GivenShort) {
      shortAmount = amount;
      token0Amount = shortAmount.proportion(option.totalLong0, denominator, false);
      token1Amount = shortAmount.proportion(option.totalLong1, denominator, false);
    } else if (transaction == TimeswapV2OptionCollect.GivenToken0) {
      token0Amount = amount;
      shortAmount = token0Amount.proportion(denominator, option.totalLong0, true);
      token1Amount = shortAmount.proportion(option.totalLong1, denominator, false);
    } else if (transaction == TimeswapV2OptionCollect.GivenToken1) {
      token1Amount = amount;
      shortAmount = token1Amount.proportion(denominator, option.totalLong1, true);
      token0Amount = shortAmount.proportion(option.totalLong0, denominator, false);
    }

    option.totalLong0 -= token0Amount;
    option.totalLong1 -= token1Amount;
  }
}
