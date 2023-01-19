//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;
import "../../src/Error.sol";

/// @dev Common error messages
library ErrorExt {
    /// @dev Reverts when input is zero.
    function zeroInput() external pure {
        return Error.zeroInput();
    }

    /// @dev Reverts when output is zero.
    function zeroOutput() external pure {
        return Error.zeroOutput();
    }

    /// @dev Reverts when a value cannot be zero.
    function cannotBeZero() external pure {
        return Error.cannotBeZero();
    }

    /// @dev Reverts when a pool already have liquidity.
    /// @param liquidity The liquidity amount that already existed in the pool.
    function alreadyHaveLiquidity(uint160 liquidity) external pure {
        return Error.alreadyHaveLiquidity(liquidity);
    }

    /// @dev Reverts when a pool requires liquidity.
    function requireLiquidity() external pure {
        return Error.requireLiquidity();
    }

    /// @dev Reverts when a given address is the zero address.
    function zeroAddress() external pure {
        return Error.zeroAddress();
    }

    /// @dev Reverts when the maturity given is not withing uint96.
    /// @param maturity The maturity being inquired.
    function incorrectMaturity(uint256 maturity) external pure {
        return Error.incorrectMaturity(maturity);
    }

    /// @dev Reverts when the maturity is already matured.
    /// @param maturity The maturity.
    /// @param blockTimestamp The current block timestamp.
    function alreadyMatured(uint256 maturity, uint96 blockTimestamp) external pure {
        return Error.alreadyMatured(maturity, blockTimestamp);
    }

    /// @dev Reverts when the maturity is still active.
    /// @param maturity The maturity.
    /// @param blockTimestamp The current block timestamp.
    function stillActive(uint256 maturity, uint96 blockTimestamp) external pure {
        return Error.stillActive(maturity, blockTimestamp);
    }

    /// @dev The deadline of a transaction has been reached.
    /// @param deadline The deadline set.
    function deadlineReached(uint256 deadline) external pure {
        return Error.deadlineReached(deadline);
    }

    /// @dev Reverts when an option of given strike and maturity is still inactive.
    /// @param strike The chosen strike.
    function inactiveOptionChoice(uint256 strike, uint256 maturity) external pure {
        return Error.inactiveOptionChoice(strike, maturity);
    }

    /// @dev Reverts when a pool of given strike and maturity is still inactive.
    /// @param strike The chosen strike.
    /// @param maturity The chosen maturity.
    function inactivePoolChoice(uint256 strike, uint256 maturity) external pure {
        return Error.inactivePoolChoice(strike, maturity);
    }

    /// @dev Reverts when the square root interest rate is zero.
    /// @param strike The chosen strike.
    /// @param maturity The chosen maturity.s
    function zeroSqrtInterestRate(uint256 strike, uint256 maturity) external pure {
        return Error.zeroSqrtInterestRate(strike, maturity);
    }

    /// @dev Reverts when a liquidity token is inactive.
    function inactiveLiquidityTokenChoice() external pure {
        return Error.inactiveLiquidityTokenChoice();
    }

    /// @dev Reverts when token amount not received.
    /// @param balance The balance amount being subtracted.
    /// @param balanceTarget The amount target.
    function checkEnough(uint256 balance, uint256 balanceTarget) external pure {
        return Error.checkEnough(balance, balanceTarget);
    }
}
