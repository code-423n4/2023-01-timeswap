//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {TimeswapV2OptionCollectCallbackParam} from "../../structs/CallbackParam.sol";

/// @title Callback for ITimeswapV2Option#collect
/// @notice Any contract that calls ITimeswapV2Option#collect can optionally implement this interface.
interface ITimeswapV2OptionCollectCallback {
    /// @notice Called to `msg.sender` after initiating a collect from ITimeswapV2Option#collect.
    /// @dev In the implementation, you must have enough short positions for the collect transaction.
    /// The caller of this method must be checked to be a Timeswap V2 Option pair deployed by the canonical Timeswap V2 Factory.
    /// @dev The token0 and token1 will already transferred to the receipients.
    /// @param param The parameter of the callback.
    /// @return data The bytes code returned from the callback.
    function timeswapV2OptionCollectCallback(TimeswapV2OptionCollectCallbackParam calldata param) external returns (bytes memory data);
}
