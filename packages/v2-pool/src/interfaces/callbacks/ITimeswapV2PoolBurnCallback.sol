//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {TimeswapV2PoolBurnChoiceCallbackParam, TimeswapV2PoolBurnCallbackParam} from "../../structs/CallbackParam.sol";

/// @dev The interface that needs to be implemented by a contract calling the burn function.
interface ITimeswapV2PoolBurnCallback {
    /// @dev Returns the amount of long0 position and long1 positions chosen to be withdrawn.
    /// @notice The StrikeConversion.combine of long0 position and long1 position must be less than or equal to long amount.
    /// @return long0Amount Amount of long0 position to be withdrawn.
    /// @return long1Amount Amount of long1 position to be withdrawn.
    /// @return data The bytes of data to be sent to msg.sender.
    function timeswapV2PoolBurnChoiceCallback(TimeswapV2PoolBurnChoiceCallbackParam calldata param) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data);
}

/// @dev The optional interface if flashability is desired.
interface ITimeswapV2PoolBurn2Callback {
    /// @dev Require enough liquidity position by the msg.sender.
    /// @return data The bytes of data to be sent to msg.sender.
    function timeswapV2PoolBurnCallback(TimeswapV2PoolBurnCallbackParam calldata param) external returns (bytes memory data);
}
