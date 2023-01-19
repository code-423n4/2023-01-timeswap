// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {CatchErrorExt} from "./wrapped/CatchErrorExt.sol";

contract CatchErrorTest is Test {
    function testCatchError(bytes calldata reason, bytes4 selector) public {
        vm.expectRevert();
        CatchErrorExt.catchError(reason, selector);
    }
}
