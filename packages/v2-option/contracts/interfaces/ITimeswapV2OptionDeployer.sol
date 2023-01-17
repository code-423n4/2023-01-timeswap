//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

/// @title An interface for a contract that is capable of deploying Timeswap V2 Option
/// @notice A contract that constructs a pair must implement this to pass arguments to the pair.
/// @dev This is used to avoid having constructor arguments in the pair contract, which results in the init code hash
/// of the pair being constant allowing the CREATE2 address of the pair to be cheaply computed on-chain.
interface ITimeswapV2OptionDeployer {
  /* ===== VIEW ===== */

  /// @notice Get the parameters to be used in constructing the pair, set transiently during pair creation.
  /// @dev Called by the pair constructor to fetch the parameters of the pair.
  /// @return optionFactory The factory address.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  function parameter() external view returns (address optionFactory, address token0, address token1);
}
