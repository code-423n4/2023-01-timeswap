//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

library PoolPairLibrary {
  /// @dev Reverts when swap address is zero.
  error ZeroSwapAddress();

  /// @dev Reverts when the Timeswap V2 Pool already exist.
  /// @param optionPair The Timeswap V2 Option parameter
  /// @param poolPair The address of the existed Timeswap V2 Pair contract.
  error PoolPairAlreadyExisted(address optionPair, address poolPair);

  /// @dev Checks if option address is not zero.
  /// @param poolPair The address being checked upon.
  function checkNotZeroAddress(address poolPair) internal pure {
    if (poolPair == address(0)) revert ZeroSwapAddress();
  }

  /// @dev Checks if the pool doesn not exist.
  /// @param optionPair The address of the TimeswapV2Option contract.
  /// @param poolPair The address of the TimeswapV2Pool contract.
  function checkDoesNotExist(address optionPair, address poolPair) internal pure {
    if (poolPair != address(0)) revert PoolPairAlreadyExisted(optionPair, poolPair);
  }
}
