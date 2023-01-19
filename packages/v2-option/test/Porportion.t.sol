// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import 'forge-std/Test.sol';
import 'forge-std/console.sol';
import './wrappedContracts/ProportionExt.sol';

contract ProportionTest is Test {
    function testProportion() public {
      vm.expectRevert();
      ProportionExt.proportion(0, 0, 0, false);

    }
}