// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./wrappedContracts/ParamExt.sol";
import "../src/structs/Param.sol";
import "../src/enums/Transaction.sol";

contract ParamTest is Test {
    function testCheckMint() public {
        vm.expectRevert();
        ParamLibraryExt.checkMint(
            TimeswapV2OptionMintParam({
                strike: 0,
                maturity: 0,
                long0To: address(0),
                long1To: address(0),
                shortTo: address(0),
                transaction: TimeswapV2OptionMint.GivenTokensAndLongs,
                amount0: 0,
                amount1: 0,
                data: ""
            }),
            0
        );
    }

    function testCheckMint2() public {
        vm.expectRevert();
        ParamLibraryExt.checkMint(
            TimeswapV2OptionMintParam({
                strike: 0,
                maturity: 0,
                long0To: address(0),
                long1To: address(0),
                shortTo: address(0),
                transaction: TimeswapV2OptionMint.GivenShorts,
                amount0: 0,
                amount1: 0,
                data: ""
            }),
            0
        );
    }

    function testCheckBurn() public {
        vm.expectRevert();
        ParamLibraryExt.checkBurn(
            TimeswapV2OptionBurnParam({strike: 0, maturity: 0, token0To: address(0), token1To: address(0), transaction: TimeswapV2OptionBurn.GivenTokensAndLongs, amount0: 0, amount1: 0, data: ""}),
            0
        );
    }

    function testCheckBurn2() public {
        vm.expectRevert();
        ParamLibraryExt.checkBurn(
            TimeswapV2OptionBurnParam({strike: 0, maturity: 0, token0To: address(0), token1To: address(0), transaction: TimeswapV2OptionBurn.GivenShorts, amount0: 0, amount1: 0, data: ""}),
            0
        );
    }

    function testCheckSwap() public {
        vm.expectRevert();
        ParamLibraryExt.checkSwap(
            TimeswapV2OptionSwapParam({
                strike: 0,
                maturity: 0,
                tokenTo: address(0),
                longTo: address(0),
                isLong0ToLong1: false,
                transaction: TimeswapV2OptionSwap.GivenToken0AndLong0,
                amount: 0,
                data: ""
            }),
            0
        );
    }

    function testCheckSwap2() public {
        vm.expectRevert();
        ParamLibraryExt.checkSwap(
            TimeswapV2OptionSwapParam({
                strike: 0,
                maturity: 0,
                tokenTo: address(0),
                longTo: address(0),
                isLong0ToLong1: false,
                transaction: TimeswapV2OptionSwap.GivenToken1AndLong1,
                amount: 0,
                data: ""
            }),
            0
        );
    }

    function testCheckCollect() public {
        vm.expectRevert();
        ParamLibraryExt.checkCollect(
            TimeswapV2OptionCollectParam({strike: 0, maturity: 0, token0To: address(0), token1To: address(0), transaction: TimeswapV2OptionCollect.GivenShort, amount: 0, data: ""}),
            0
        );
    }

    function testCheckCollect2() public {
        vm.expectRevert();
        ParamLibraryExt.checkCollect(
            TimeswapV2OptionCollectParam({strike: 0, maturity: 0, token0To: address(0), token1To: address(0), transaction: TimeswapV2OptionCollect.GivenToken0, amount: 0, data: ""}),
            0
        );
    }

    function testCheckCollect3() public {
        vm.expectRevert();
        ParamLibraryExt.checkCollect(
            TimeswapV2OptionCollectParam({strike: 0, maturity: 0, token0To: address(0), token1To: address(0), transaction: TimeswapV2OptionCollect.GivenToken1, amount: 0, data: ""}),
            0
        );
    }
}
