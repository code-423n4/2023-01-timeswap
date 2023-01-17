//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {TimeswapV2TokenBurnCallbackParam} from '../../structs/CallbackParam.sol';

interface ITimeswapV2TokenBurnCallback {
  /// @dev Callback for `ITimeswapV2Token.burn`
  function timeswapV2TokenBurnCallback(
    TimeswapV2TokenBurnCallbackParam calldata param
  ) external returns (bytes memory data);
}
