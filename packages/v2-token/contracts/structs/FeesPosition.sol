// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {FeeCalculation} from "@timeswap-labs/v2-pool/contracts/libraries/FeeCalculation.sol";
import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";

struct FeesPosition {
    uint256 long0FeeGrowth;
    uint256 long1FeeGrowth;
    uint256 shortFeeGrowth;
    uint256 long0Fees;
    uint256 long1Fees;
    uint256 shortFees;
}

library FeesPositionLibrary {
    function feesEarnedOf(
        FeesPosition memory feesPosition,
        uint160 liquidity,
        uint256 long0FeeGrowth,
        uint256 long1FeeGrowth,
        uint256 shortFeeGrowth
    ) internal pure returns (uint256 long0Fee, uint256 long1Fee, uint256 shortFee) {
        long0Fee = feesPosition.long0Fees + FeeCalculation.getFees(liquidity, feesPosition.long0FeeGrowth, long0FeeGrowth);
        long1Fee = feesPosition.long1Fees + FeeCalculation.getFees(liquidity, feesPosition.long1FeeGrowth, long1FeeGrowth);
        shortFee = feesPosition.shortFees + FeeCalculation.getFees(liquidity, feesPosition.shortFeeGrowth, shortFeeGrowth);
    }

    function update(FeesPosition storage feesPosition, uint160 liquidity, uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth) internal {
        if (liquidity != 0) {
            feesPosition.long0Fees += FeeCalculation.getFees(liquidity, feesPosition.long0FeeGrowth, long0FeeGrowth);
            feesPosition.long1Fees += FeeCalculation.getFees(liquidity, feesPosition.long1FeeGrowth, long1FeeGrowth);
            feesPosition.shortFees += FeeCalculation.getFees(liquidity, feesPosition.shortFeeGrowth, shortFeeGrowth);
        }

        feesPosition.long0FeeGrowth = long0FeeGrowth;
        feesPosition.long1FeeGrowth = long1FeeGrowth;
        feesPosition.shortFeeGrowth = shortFeeGrowth;
    }

    function getFees(
        FeesPosition storage feesPosition,
        uint256 long0FeesDesired,
        uint256 long1FeesDesired,
        uint256 shortFeesDesired
    ) internal view returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees) {
        long0Fees = Math.min(feesPosition.long0Fees, long0FeesDesired);
        long1Fees = Math.min(feesPosition.long1Fees, long1FeesDesired);
        shortFees = Math.min(feesPosition.shortFees, shortFeesDesired);
    }

    function mint(FeesPosition storage feesPosition, uint256 long0Fees, uint256 long1Fees, uint256 shortFees) internal {
        feesPosition.long0Fees += long0Fees;
        feesPosition.long1Fees += long1Fees;
        feesPosition.shortFees += shortFees;
    }

    function burn(FeesPosition storage feesPosition, uint256 long0Fees, uint256 long1Fees, uint256 shortFees) internal {
        feesPosition.long0Fees -= long0Fees;
        feesPosition.long1Fees -= long1Fees;
        feesPosition.shortFees -= shortFees;
    }
}
