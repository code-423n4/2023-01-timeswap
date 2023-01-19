//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {IERC1155Enumerable} from "./IERC1155Enumerable.sol";

import {TimeswapV2LiquidityTokenPosition} from "../structs/Position.sol";
import {TimeswapV2LiquidityTokenMintParam, TimeswapV2LiquidityTokenBurnParam, TimeswapV2LiquidityTokenCollectParam} from "../structs/Param.sol";

/// @title An interface for TS-V2 liquidity token system
interface ITimeswapV2LiquidityToken is IERC1155Enumerable {
    error NotApprovedToTransferFees();

    event TransferFees(address from, address to, TimeswapV2LiquidityTokenPosition position, uint256 long0Fees, uint256 long1Fees, uint256 shortFees);

    /// @dev Returns the option factory address.
    /// @return optionFactory The option factory address.
    function optionFactory() external view returns (address);

    /// @dev Returns the pool factory address.
    /// @return poolFactory The pool factory address.
    function poolFactory() external view returns (address);

    /// @dev Returns the position Balance of the owner
    /// @param owner The owner of the token
    /// @param position The liquidity position
    function positionOf(address owner, TimeswapV2LiquidityTokenPosition calldata position) external view returns (uint256 amount);

    /// @dev Transfers position token TimeswapV2Token from `from` to `to`
    /// @param from The address to transfer position token from
    /// @param to The address to transfer position token to
    /// @param position The TimeswapV2Token Position to transfer
    /// @param liquidityAmount The amount of TimeswapV2Token Position to transfer
    function transferTokenPositionFrom(address from, address to, TimeswapV2LiquidityTokenPosition calldata position, uint160 liquidityAmount) external;

    /// @dev Transfers fees from `from` to `to`
    /// @param from The address to transfer fees from
    /// @param to The address to transfer fees to
    /// @param position The TimeswapV2Token Position to transfer
    /// @param long0Fees The amount of long0 fees to transfer
    /// @param long1Fees The amount of long1 fees to transfer
    /// @param shortFees The amount of short fees to transfer
    function transferFeesFrom(address from, address to, TimeswapV2LiquidityTokenPosition calldata position, uint256 long0Fees, uint256 long1Fees, uint256 shortFees) external;

    /// @dev mints TimeswapV2LiquidityToken as per the liqudityAmount
    /// @param param The TimeswapV2LiquidityTokenMintParam
    /// @return data Arbitrary data
    function mint(TimeswapV2LiquidityTokenMintParam calldata param) external returns (bytes memory data);

    /// @dev burns TimeswapV2LiquidityToken as per the liqudityAmount
    /// @param param The TimeswapV2LiquidityTokenBurnParam
    /// @return data Arbitrary data
    function burn(TimeswapV2LiquidityTokenBurnParam calldata param) external returns (bytes memory data);

    /// @dev collects fees as per the fees desired
    /// @param param The TimeswapV2LiquidityTokenBurnParam
    /// @return long0Fees Fees for long0
    /// @return long1Fees Fees for long1
    /// @return shortFees Fees for short
    function collect(TimeswapV2LiquidityTokenCollectParam calldata param) external returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, bytes memory data);
}
