//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {Ownership} from '@timeswap-labs/v2-library/contracts/Ownership.sol';

import {OptionPairLibrary} from '@timeswap-labs/v2-option/contracts/libraries/OptionPair.sol';

import {ITimeswapV2PoolFactory} from './interfaces/ITimeswapV2PoolFactory.sol';

import {TimeswapV2PoolDeployer} from './TimeswapV2PoolDeployer.sol';

import {Error} from '@timeswap-labs/v2-library/contracts/Error.sol';

import {OwnableTwoSteps} from './base/OwnableTwoSteps.sol';

contract TimeswapV2PoolFactory is ITimeswapV2PoolFactory, TimeswapV2PoolDeployer, OwnableTwoSteps {
  using OptionPairLibrary for address;
  using Ownership for address;

  /// @dev Revert when fee initialization is chosen to be larger than uint16.
  /// @param fee The chosen fee.
  error IncorrectFeeInitialization(uint256 fee);

  /* ===== MODEL ===== */

  /// @inheritdoc ITimeswapV2PoolFactory
  uint256 public immutable override transactionFee;
  /// @inheritdoc ITimeswapV2PoolFactory
  uint256 public immutable override protocolFee;

  mapping(address => address) private pairs;

  address[] public override getByIndex;

  /* ===== INIT ===== */

  constructor(
    address chosenOwner,
    uint256 chosenTransactionFee,
    uint256 chosenProtocolFee
  ) OwnableTwoSteps(chosenOwner) {
    if (chosenTransactionFee > type(uint16).max) revert IncorrectFeeInitialization(chosenTransactionFee);
    if (chosenProtocolFee > type(uint16).max) revert IncorrectFeeInitialization(chosenProtocolFee);

    transactionFee = chosenTransactionFee;
    protocolFee = chosenProtocolFee;
  }

  /* ===== VIEW ===== */

  /// @inheritdoc ITimeswapV2PoolFactory
  function get(address optionPair) external view override returns (address pair) {
    pair = pairs[optionPair];
  }

  function numberOfPairs() external view override returns (uint256) {
    return getByIndex.length;
  }

  /* ===== UPDATE ===== */

  /// @inheritdoc ITimeswapV2PoolFactory
  function create(address optionPair) external override returns (address pair) {
    if (optionPair == address(0)) Error.zeroAddress();

    pair = pairs[optionPair];
    if (pair != address(0)) Error.zeroAddress();

    pair = deploy(address(this), optionPair, transactionFee, protocolFee);

    pairs[optionPair] = pair;

    emit Create(msg.sender, optionPair, pair);
  }
}
