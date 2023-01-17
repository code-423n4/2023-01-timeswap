//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {TimeswapV2LiquidityTokenCollectCallbackParam} from '../../structs/CallbackParam.sol';

interface ITimeswapV2LiquidityTokenCollectCallback {
  /// @dev Callback for `ITimeswapV2LiquidityToken.collect`
  function timeswapV2LiquidityTokenCollectCallback(
    TimeswapV2LiquidityTokenCollectCallbackParam calldata param
  ) external returns (bytes memory data);
}
