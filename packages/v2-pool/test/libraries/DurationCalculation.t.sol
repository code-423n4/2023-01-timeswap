pragma solidity =0.8.8;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../wrappedContracts/DurationCalculationExt.sol";

contract DurationCalculationTest is Test {

    function testUnsafeDurationFromLastTimestampToNow() public{
        uint96 lastTimestamp = 100;
        uint96 blockTimestamp = 200;
        uint96 duration = DurationCalculationExt.unsafeDurationFromLastTimestampToNow(lastTimestamp, blockTimestamp);
        assertEq(duration, 100);
    }

    function testUnsafeDurationFromNowToMaturity() public{
        uint256 maturity = 1000;
        uint96 blockTimestamp = 200;
        uint96 duration = DurationCalculationExt.unsafeDurationFromNowToMaturity(maturity, blockTimestamp);
        assertEq(duration, 800);
    }

    function testUnsafeDurationFromLastTimestampToMaturity() public{
        uint96 lastTimestamp = 100;
        uint256 maturity = 1000;
        uint96 duration = DurationCalculationExt.unsafeDurationFromLastTimestampToMaturity(lastTimestamp, maturity);
        assertEq(duration, 900);
    }

    function testUnsafeDurationFromLastTimestampToNowOrMaturity() public{
        uint96 lastTimestamp = 100;
        uint256 maturity = 1000;
        uint96 blockTimestamp = 200;
        uint96 duration = DurationCalculationExt.unsafeDurationFromLastTimestampToNowOrMaturity(lastTimestamp, maturity, blockTimestamp);
        assertEq(duration, 100);
    }

}