// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {SafeCastExt} from "./wrapped/SafeCastExt.sol";

contract SafeCastTest is Test {
    function testToUint16(uint256 value) public pure {
        vm.assume(value < (1 << 16));
        SafeCastExt.toUint16(value);
    }

    function testToUint96(uint256 value) public pure {
        vm.assume(value < (1 << 96));
        SafeCastExt.toUint96(value);
    }

    function testToUint160(uint256 value) public pure {
        vm.assume(value < (1 << 160));
        SafeCastExt.toUint160(value);
    }
}
