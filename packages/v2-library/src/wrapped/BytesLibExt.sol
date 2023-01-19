// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../BytesLib.sol";

library BytesLibExt {
    function slice(bytes memory self, uint start, uint len) external pure returns (bytes memory) {
        return BytesLib.slice(self, start, len);
    }
}
