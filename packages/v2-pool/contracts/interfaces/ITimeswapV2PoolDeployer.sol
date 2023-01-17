//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

/// @title An interface for a contract that is capable of deploying Timeswap V2 Pool
/// @notice A contract that constructs a pair must implement this to pass arguments to the pair.
/// @dev This is used to avoid having constructor arguments in the pair contract, which results in the init code hash
/// of the pair being constant allowing the CREATE2 address of the pair to be cheaply computed on-chain.
interface ITimeswapV2PoolDeployer {
  /* ===== VIEW ===== */

  /// @notice Get the parameters to be used in constructing the pair, set transiently during pair creation.
  /// @dev Called by the pair constructor to fetch the parameters of the pair.
  /// @return poolFactory The poolFactory address.
  /// @param optionPair The Timeswap V2 OptionPair address.
  /// @param transactionFee The transaction fee earned by the liquidity providers.
  /// @param protocolFee The protocol fee earned by the DAO.
  function parameter()
    external
    view
    returns (address poolFactory, address optionPair, uint256 transactionFee, uint256 protocolFee);
}
