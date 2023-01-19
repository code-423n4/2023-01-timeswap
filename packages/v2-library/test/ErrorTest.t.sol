// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/wrapped/ErrorExt.sol";

contract ErrorExtTest is Test {
    function testZeroInput() public {
        vm.expectRevert();
        ErrorExt.zeroInput();
    }

    function testZeroOutput() public {
        vm.expectRevert();
        ErrorExt.zeroOutput();
    }

    function testCannotBeZero() public {
        vm.expectRevert();
        ErrorExt.cannotBeZero();
    }

    function testAlreadyHaveLiquidity(uint160 liquidity) public {
        vm.expectRevert();
        ErrorExt.alreadyHaveLiquidity(liquidity);
    }

    function testRequireLiquidity() public {
        vm.expectRevert();
        ErrorExt.requireLiquidity();
    }

    function testZeroAddress() public {
        vm.expectRevert();
        ErrorExt.zeroAddress();
    }

    function testIncorrectMaturity(uint256 maturity) public {
        vm.expectRevert();
        ErrorExt.incorrectMaturity(maturity);
    }

    function testAlreadyMatured(uint256 maturity, uint96 blockTimestamp) public {
        vm.expectRevert();
        ErrorExt.alreadyMatured(maturity, blockTimestamp);
    }

    function testStillActive(uint256 maturity, uint96 blockTimestamp) public {
        vm.expectRevert();
        ErrorExt.stillActive(maturity, blockTimestamp);
    }

    function testDeadlineReached(uint256 deadline) public {
        vm.expectRevert();
        ErrorExt.deadlineReached(deadline);
    }

    function testInactiveOptionChoice(uint256 strike, uint256 maturity) public {
        vm.expectRevert();
        ErrorExt.inactiveOptionChoice(strike, maturity);
    }

    function testInactivePoolChoice(uint256 strike, uint256 maturity) public {
        vm.expectRevert();
        ErrorExt.inactivePoolChoice(strike, maturity);
    }

    function testZeroSqrtInterestRate(uint256 strike, uint256 maturity) public {
        vm.expectRevert();
        ErrorExt.zeroSqrtInterestRate(strike, maturity);
    }

    function testInactiveLiquidityTokenChoice() public {
        vm.expectRevert();
        ErrorExt.inactiveLiquidityTokenChoice();
    }

    function testCheckEnought(uint256 a, uint256 b) public {
        vm.assume(a < b);
        vm.expectRevert();
        ErrorExt.checkEnough(a, b);
    }
}

// /// @dev Reverts when a pool of given strike and maturity is still inactive.
// /// @param strike The chosen strike.
// /// @param maturity The chosen maturity.
// function inactivePoolChoice(uint256 strike, uint256 maturity) external pure {
//     return Error.inactivePoolChoice(strike, maturity);
// }

// /// @dev Reverts when the square root interest rate is zero.
// /// @param strike The chosen strike.
// /// @param maturity The chosen maturity.s
// function zeroSqrtInterestRate(uint256 strike, uint256 maturity) external pure {
//     return Error.zeroSqrtInterestRate(strike, maturity);
// }

// /// @dev Reverts when a liquidity token is inactive.
// function inactiveLiquidityTokenChoice() external pure {
//     return Error.inactiveLiquidityTokenChoice();
// }

// /// @dev Reverts when token amount not received.
// /// @param balance The balance amount being subtracted.
// /// @param balanceTarget The amount target.
// function checkEnough(uint256 balance, uint256 balanceTarget) external pure {
//     return Error.checkEnough(balance, balanceTarget);
// }
