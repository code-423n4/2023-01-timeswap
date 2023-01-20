//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../wrappedContracts/FeeExt.sol";

contract Fee is Test {
    // reverts when fee is greater than max of uint16
    function testCheck() public {
        vm.expectRevert();
        uint256 fee = type(uint16).max + 1;
        FeeExt.check(fee);
    }

    // returns the input 'fee' when the input 'fee' is less than or equal to the maximum value of 'uint16'
    function testCheck2() public pure {
        uint256 fee = type(uint16).max;
        FeeExt.check(fee);
    }
}
