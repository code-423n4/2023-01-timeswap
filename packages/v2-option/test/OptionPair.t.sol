// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./wrappedContracts/OptionPairExt.sol";

contract OptionPairTest is Test {
    function testCheckNotZeroAddress() public {
        OptionPairExt.checkNotZeroAddress(address(0x345));
    }

    function testCheckCorrectFormat(address token0, address token1) public {
        vm.expectRevert();
        OptionPairExt.checkCorrectFormat(address(0), address(0));
    }

    function testCheckDoesNotExist(address token0, address token1, address optionPair) public {
        OptionPairExt.checkDoesNotExist(address(0), address(0), address(0));
    }
}
