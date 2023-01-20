//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {Math} from "@timeswap-labs/v2-library/src/Math.sol";

import {FeeCalculation} from "../libraries/FeeCalculation.sol";

/// @param liquidity The amount of liquidity owned.
/// @param long0FeeGrowth The long0 position fee growth stored when the user entered the positions.
/// @param long1FeeGrowth The long1 position fee growth stored when the user entered the positions.
/// @param shortFeeGrowth The short position fee growth stored when the user entered the positions.
/// @param long0Fees The stored amount of long0 position fees owned.
/// @param long1Fees The stored amount of long1 position fees owned.
/// @param shortFees The stored amount of short position fees owned.
struct LiquidityPosition {
    uint160 liquidity;
    uint256 long0FeeGrowth;
    uint256 long1FeeGrowth;
    uint256 shortFeeGrowth;
    uint256 long0Fees;
    uint256 long1Fees;
    uint256 shortFees;
}

library LiquidityPositionLibrary {
    using Math for uint256;

    /// @dev Get the total fees earned by the owner.
    /// @param liquidityPosition The liquidity position of the owner.
    /// @param long0FeeGrowth The current global long0 position fee growth to be compared.
    /// @param long1FeeGrowth The current global long1 position fee growth to be compared.
    /// @param shortFeeGrowth The current global short position fee growth to be compared.
    function feesEarnedOf(
        LiquidityPosition memory liquidityPosition,
        uint256 long0FeeGrowth,
        uint256 long1FeeGrowth,
        uint256 shortFeeGrowth
    ) internal pure returns (uint256 long0Fee, uint256 long1Fee, uint256 shortFee) {
        uint160 liquidity = liquidityPosition.liquidity;

        long0Fee = liquidityPosition.long0Fees.unsafeAdd(FeeCalculation.getFees(liquidity, liquidityPosition.long0FeeGrowth, long0FeeGrowth));
        long1Fee = liquidityPosition.long1Fees.unsafeAdd(FeeCalculation.getFees(liquidity, liquidityPosition.long1FeeGrowth, long1FeeGrowth));
        shortFee = liquidityPosition.shortFees.unsafeAdd(FeeCalculation.getFees(liquidity, liquidityPosition.shortFeeGrowth, shortFeeGrowth));
    }

    /// @dev Update the liquidity position after mint and/or burn functions.
    /// @param liquidityPosition The liquidity position of the owner.
    /// @param long0FeeGrowth The current global long0 position fee growth to be compared.
    /// @param long1FeeGrowth The current global long1 position fee growth to be compared.
    /// @param shortFeeGrowth The current global short position fee growth to be compared.
    function update(LiquidityPosition storage liquidityPosition, uint256 long0FeeGrowth, uint256 long1FeeGrowth, uint256 shortFeeGrowth) internal {
        uint160 liquidity = liquidityPosition.liquidity;

        if (liquidity != 0) {
            liquidityPosition.long0Fees += FeeCalculation.getFees(liquidity, liquidityPosition.long0FeeGrowth, long0FeeGrowth);
            liquidityPosition.long1Fees += FeeCalculation.getFees(liquidity, liquidityPosition.long1FeeGrowth, long1FeeGrowth);
            liquidityPosition.shortFees += FeeCalculation.getFees(liquidity, liquidityPosition.shortFeeGrowth, shortFeeGrowth);
        }

        liquidityPosition.long0FeeGrowth = long0FeeGrowth;
        liquidityPosition.long1FeeGrowth = long1FeeGrowth;
        liquidityPosition.shortFeeGrowth = shortFeeGrowth;
    }

    function mint(LiquidityPosition storage liquidityPosition, uint160 liquidityAmount) internal {
        liquidityPosition.liquidity += liquidityAmount;
    }

    function mintFees(LiquidityPosition storage liquidityPosition, uint256 long0Fees, uint256 long1Fees, uint256 shortFees) internal {
        liquidityPosition.long0Fees += long0Fees;
        liquidityPosition.long1Fees += long1Fees;
        liquidityPosition.shortFees += shortFees;
    }

    function burn(LiquidityPosition storage liquidityPosition, uint160 liquidityAmount) internal {
        liquidityPosition.liquidity -= liquidityAmount;
    }

    function burnFees(LiquidityPosition storage liquidityPosition, uint256 long0Fees, uint256 long1Fees, uint256 shortFees) internal {
        liquidityPosition.long0Fees -= long0Fees;
        liquidityPosition.long1Fees -= long1Fees;
        liquidityPosition.shortFees -= shortFees;
    }

    function collectTransactionFees(
        LiquidityPosition storage liquidityPosition,
        uint256 long0Requested,
        uint256 long1Requested,
        uint256 shortRequested
    ) internal returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees) {
        if (long0Requested >= liquidityPosition.long0Fees) {
            long0Fees = liquidityPosition.long0Fees;
            liquidityPosition.long0Fees = 0;
        } else {
            long0Fees = long0Requested;
            liquidityPosition.long0Fees = liquidityPosition.long0Fees.unsafeSub(long0Requested);
        }

        if (long1Requested >= liquidityPosition.long1Fees) {
            long1Fees = liquidityPosition.long1Fees;
            liquidityPosition.long1Fees = 0;
        } else {
            long1Fees = long1Requested;
            liquidityPosition.long1Fees = liquidityPosition.long1Fees.unsafeSub(long1Requested);
        }

        if (shortRequested >= liquidityPosition.shortFees) {
            shortFees = liquidityPosition.shortFees;
            liquidityPosition.shortFees = 0;
        } else {
            shortFees = shortRequested;
            liquidityPosition.shortFees = liquidityPosition.shortFees.unsafeSub(shortRequested);
        }
    }
}
