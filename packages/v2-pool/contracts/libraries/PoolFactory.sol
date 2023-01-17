//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {OptionFactoryLibrary} from '@timeswap-labs/v2-option/contracts/libraries/OptionFactory.sol';

import {ITimeswapV2PoolFactory} from '../interfaces/ITimeswapV2PoolFactory.sol';

import {Error} from '@timeswap-labs/v2-library/contracts/Error.sol';

library PoolFactoryLibrary {
  using OptionFactoryLibrary for address;

  /// @dev Reverts when pool factory address is zero.
  error ZeroFactoryAddress();

  /// @dev Checks if the pool factory address is zero.
  /// @param poolFactory The pool factory address which is needed to be checked.
  function checkNotZeroFactory(address poolFactory) internal pure {
    if (poolFactory == address(0)) revert ZeroFactoryAddress();
  }

  /// @dev Get the option pair address and pool pair address.
  /// @param optionFactory The option factory contract address.
  /// @param poolFactory The pool factory contract address.
  /// @param token0 The address of the smaller address ERC20 token contract.
  /// @param token1 The address of the larger address ERC20 token contract.
  /// @return optionPair The retreived option pair address. Zero address if not deployed.
  /// @return poolPair The retreived pool pair address. Zero address if not deployed.
  function get(
    address optionFactory,
    address poolFactory,
    address token0,
    address token1
  ) internal view returns (address optionPair, address poolPair) {
    optionPair = optionFactory.get(token0, token1);

    poolPair = ITimeswapV2PoolFactory(poolFactory).get(optionPair);
  }

  /// @dev Get the option pair address and pool pair address.
  /// @notice Reverts when the option or the pool is not deployed.
  /// @param optionFactory The option factory contract address.
  /// @param poolFactory The pool factory contract address.
  /// @param token0 The address of the smaller address ERC20 token contract.
  /// @param token1 The address of the larger address ERC20 token contract.
  /// @return optionPair The retreived option pair address.
  /// @return poolPair The retreived pool pair address.
  function getWithCheck(
    address optionFactory,
    address poolFactory,
    address token0,
    address token1
  ) internal view returns (address optionPair, address poolPair) {
    optionPair = optionFactory.getWithCheck(token0, token1);

    poolPair = ITimeswapV2PoolFactory(poolFactory).get(optionPair);

    if (poolPair == address(0)) Error.zeroAddress();
  }
}
