//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {TimeswapV2PoolRebalanceCallbackParam} from '../../structs/CallbackParam.sol';

/// @dev The interface that needs to be implemented by a contract calling the rebalance function.
interface ITimeswapV2PoolRebalanceCallback {
  /// @dev When Long0ToLong1, require the transfer of long0 position into the pool.
  /// @dev When Long1ToLong0, require the transfer of long1 position into the pool.
  /// @dev The long0 positions or long1 positions will already be minted to the receipient.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolRebalanceCallback(
    TimeswapV2PoolRebalanceCallbackParam calldata param
  ) external returns (bytes memory data);
}
