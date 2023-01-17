//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {TimeswapV2OptionBurnCallbackParam} from '../../structs/CallbackParam.sol';

/// @title Callback for ITimeswapV2Option#burn
/// @notice Any contract that calls ITimeswapV2Option#burn can optionally implement this interface.
interface ITimeswapV2OptionBurnCallback {
  /// @notice Called to `msg.sender` after initiating a burn from ITimeswapV2Option#burn.
  /// @dev In the implementation, you must have enough long0 positions, long1 positions, and short positions for the burn transaction.
  /// The caller of this method must be checked to be a Timeswap V2 Option pair deployed by the canonical Timeswap V2 Factory.
  /// @dev The token0 and token1 will already transferred to the receipients.
  /// @param param The parameter of the callback.
  /// @return data The bytes code returned from the callback.
  function timeswapV2OptionBurnCallback(
    TimeswapV2OptionBurnCallbackParam calldata param
  ) external returns (bytes memory data);
}
