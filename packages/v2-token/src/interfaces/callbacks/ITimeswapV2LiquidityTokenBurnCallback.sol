//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {TimeswapV2LiquidityTokenBurnCallbackParam} from "../../structs/CallbackParam.sol";

interface ITimeswapV2LiquidityTokenBurnCallback {
    /// @dev Callback for `ITimeswapV2LiquidityToken.burn`
    function timeswapV2LiquidityTokenBurnCallback(TimeswapV2LiquidityTokenBurnCallbackParam calldata param) external returns (bytes memory data);
}
