// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "./wrapped/BytesLibExt.sol";

contract BytesLibTest is Test {
    function testSlice(uint256 _start, uint256 _length) public pure {
        bytes memory _bytes = bytes("abcd");

        BytesLibExt.slice(_bytes, 0, 1);
    }
}
