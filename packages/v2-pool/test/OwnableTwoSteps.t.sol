// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import 'forge-std/Test.sol';
import 'forge-std/console.sol';

import "../src/base/OwnableTwoSteps.sol";

contract OwnableTwoStepsTest is Test{
    OwnableTwoSteps ownableTwoSteps;

    function setUp() public {
        ownableTwoSteps = new OwnableTwoSteps(address(this));
    }

    function testSetPendingOwner() public {
        ownableTwoSteps.setPendingOwner(address(1));
        assertEq(ownableTwoSteps.pendingOwner(), address(1));
    }

    function testAcceptOwner() public {
        ownableTwoSteps.setPendingOwner(address(1));
        vm.prank(address(1));
        ownableTwoSteps.acceptOwner();
        assertEq(ownableTwoSteps.owner(), address(1));
    }

}