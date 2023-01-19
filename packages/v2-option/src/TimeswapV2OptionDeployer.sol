//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {TimeswapV2Option} from "./TimeswapV2Option.sol";

import {ITimeswapV2OptionDeployer} from "./interfaces/ITimeswapV2OptionDeployer.sol";

/// @title Capable of deploying Timeswap V2 Option
/// @author Timeswap Labs
contract TimeswapV2OptionDeployer is ITimeswapV2OptionDeployer {
    /// @param optionFactory The address of the TimeswapV2OptionFactory contract.
    /// @param token0 The smaller numbered address of the ERC20 token pair.
    /// @param token1 The larger numbered address of the ERC20 token pair.
    struct Parameter {
        address optionFactory;
        address token0;
        address token1;
    }

    /* ===== MODEL ===== */

    /// @inheritdoc ITimeswapV2OptionDeployer
    Parameter public override parameter;

    /* ===== UPDATE ===== */

    /// @dev Deploy the TimeswapV2Option contract.
    /// @param optionFactory The address of the TimeswapV2OptionFactory contract.
    /// @param token0 The smaller numbered address of the ERC20 token pair.
    /// @param token1 The larger numbered address of the ERC20 token pair.
    /// @return optionPair The address of the newly deployed TimeswapV2Option contract.
    function deploy(address optionFactory, address token0, address token1) internal returns (address optionPair) {
        parameter = Parameter({optionFactory: optionFactory, token0: token0, token1: token1});

        optionPair = address(new TimeswapV2Option{salt: keccak256(abi.encode(token0, token1))}());

        // save gas.
        delete parameter;
    }
}
