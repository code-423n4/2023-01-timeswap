//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../wrappedContracts/PoolPairExt.sol";

contract PoolPairTest is Test {
    // reverts when pool address is zero.
    function testCheckNotZeroAddress() public {
        vm.expectRevert();
        address poolPair = address(0);
        PoolPairExt.checkNotZeroAddress(poolPair);
    }

    // check if pool address not zero.
    function testCheckNotZeroAddressSuccess() public pure {
        address poolPair = address(1);
        PoolPairExt.checkNotZeroAddress(poolPair);
    }

    function testCheckDoesNotExist() public pure {
        address optionPair = address(0);
        address poolPair = address(0);
        PoolPairExt.checkDoesNotExist(optionPair, poolPair);
    }
}
