//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {TimeswapV2LiquidityTokenMintCallbackParam} from "../../structs/CallbackParam.sol";

interface ITimeswapV2LiquidityTokenMintCallback {
    /// @dev Callback for `ITimeswapV2LiquidityToken.mint`
    function timeswapV2LiquidityTokenMintCallback(TimeswapV2LiquidityTokenMintCallbackParam calldata param) external returns (bytes memory data);
}
