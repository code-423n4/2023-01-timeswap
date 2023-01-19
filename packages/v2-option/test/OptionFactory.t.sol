// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import 'forge-std/Test.sol';
import 'forge-std/console.sol';
import './wrappedContracts/OptionFactoryExt.sol';

contract OptionFactoryTest is Test {
    
    function testCheckNotZeroFactory() public {
        assertEq(OptionFactoryExt.checkNotZeroFactory(address(0)), 0);
    }

    // //"verify that the 'get' function returns the input 'optionPair' when the input 'optionPair' is not the zero address"
    // function testGetFunction() public {
    //     assertEq(DurationLibraryExt.get(address(1), address(2), address(3)), address(1));
    // }
    
    
    // //"verify that the 'init' function reverts with the 'DurationOverflow' error when the input 'duration' is greater than the maximum value of 'uint96'"
    // function testInitFunctionRevert() public {    
    //     vm.expectRevert();
    //     uint96 maxValue = type(uint96).max;
    //     DurationLibraryExt.init(maxValue+1);
    // }
    // //"verify that the 'init' function returns the input 'duration' when the input 'duration' is less than or equal to the maximum value of 'uint96'"
    // function testInitFunction() public {
    //     uint96 maxValue = type(uint96).max;
    //     assertEq(DurationLibraryExt.init(maxValue), maxValue);
    // }
}