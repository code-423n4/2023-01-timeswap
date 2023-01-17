//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {Math} from '@timeswap-labs/v2-library/contracts/Math.sol';
import {SafeCast} from '@timeswap-labs/v2-library/contracts/SafeCast.sol';

import {DurationLibrary} from './Duration.sol';

/// @title calculation of duration
library DurationCalculation {
  using Math for uint256;
  using SafeCast for uint256;

  /// @dev gives the duration between the current block timestamp and the last timestamp
  /// @param lastTimestamp The last timestamp
  /// @param blockTimestamp The current block timestamp
  /// @return duration The duration between the current block timestamp and the last timestamp
  function unsafeDurationFromLastTimestampToNow(
    uint96 lastTimestamp,
    uint96 blockTimestamp
  ) internal pure returns (uint96 duration) {
    duration = uint256(blockTimestamp).unsafeSub(lastTimestamp).toUint96();
  }

  /// @dev gives the duration between the maturity and the current block timestamp
  /// @param maturity The maturity of the pool
  /// @param blockTimestamp The current block timestamp
  /// @return duration The duration between the maturity and the current block timestamp
  function unsafeDurationFromNowToMaturity(
    uint256 maturity,
    uint96 blockTimestamp
  ) internal pure returns (uint96 duration) {
    duration = maturity.unsafeSub(uint256(blockTimestamp)).toUint96();
  }

  /// @dev gives the duration between the maturity and the last timestamp
  /// @param lastTimestamp The last timestamp
  /// @param maturity The maturity of the pool
  /// @return duration The duration between the maturity and the last timestamp
  function unsafeDurationFromLastTimestampToMaturity(
    uint96 lastTimestamp,
    uint256 maturity
  ) internal pure returns (uint96 duration) {
    duration = maturity.unsafeSub(lastTimestamp).toUint96();
  }

  /// @dev gives the duration between the maturity and the minimum of the last timestamp and the current block timestamp
  /// @param lastTimestamp The last timestamp
  /// @param maturity The maturity of the pool
  /// @param blockTimestamp The current block timestamp
  /// @return duration The duration between the maturity and the minimum of the last timestamp and the current block timestamp
  function unsafeDurationFromLastTimestampToNowOrMaturity(
    uint96 lastTimestamp,
    uint256 maturity,
    uint96 blockTimestamp
  ) internal pure returns (uint96 duration) {
    duration = maturity.min(blockTimestamp).unsafeSub(lastTimestamp).toUint96();
  }
}
