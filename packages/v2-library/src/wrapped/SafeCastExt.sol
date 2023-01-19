//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;
import "../SafeCast.sol";

library SafeCastExt {
    function toUint16(uint256 value) external pure returns (uint16 result) {
        return SafeCast.toUint16(value);
    }

    function toUint96(uint256 value) external pure returns (uint96 result) {
        return SafeCast.toUint96(value);
    }

    function toUint160(uint256 value) external pure returns (uint160 result) {
        return SafeCast.toUint160(value);
    }
}
