// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./wrapped/BytesLibExt.sol";

contract BytesLibTest is Test {
    function testSlice(bytes memory _bytes, uint256 _start, uint256 _length) public pure {
        BytesLibExt.slice(_bytes, _start, _length);
    }
}
