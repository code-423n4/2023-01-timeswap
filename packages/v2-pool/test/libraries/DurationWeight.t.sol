pragma solidity =0.8.8;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/libraries/FeeCalculation.sol";
import "../wrappedContracts/DurationWeightExt.sol";

contract DurationWeightTest is Test {
    function testUpdateFunction() public {
        uint160 liquidity = 100;
        uint256 shortFeeGrowth = 200;
        uint256 shortAmount = 0;
        uint256 feeGrowth = FeeCalculation.getFeeGrowth(shortAmount, liquidity);
        uint256 newShortFeeGrowth = shortFeeGrowth + feeGrowth;
        assertEq(newShortFeeGrowth, DurationWeightExt.update(liquidity, shortFeeGrowth, shortAmount));
    }
}
