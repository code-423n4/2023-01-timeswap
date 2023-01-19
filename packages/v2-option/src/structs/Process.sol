//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

/// @dev Processing information required for interacting multple options in a single contract.
/// @notice Since mint, burn, and swap are all flashable transactions.
/// When doing a mint transaction, do not burn or swap the newly minted positions,
/// or risk transaction failure.
/// When doing a swap transaction, do not burn or swap the newly swapped positions,
/// or risk transaction failure.
/// @notice For example, if only long0 is minted.
/// Then calling swap on that long0 position of the same strike and maturity can risk transaction failure.
/// If calling swap on long1 position received elsewhere, that will be fine.
/// If calling swap on long1 but different strike and maturity is fine as well.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param balance0Target The required balance of token0 to be held in the option.
/// @param balance1Target The required balance of token1 to be held in the option.
struct Process {
    uint256 strike;
    uint256 maturity;
    uint256 balance0Target;
    uint256 balance1Target;
}

library ProcessLibrary {
    /// @dev update process for managing how many tokens required from msg.sender.
    /// @dev reentrancy safety as well.
    /// @param processing The current array of processes.
    /// @param token0Amount If isAddToken0 then token0 amount to be deposited, else the token0 amount withdrawn.
    /// @param token1Amount If isAddToken1 then token1 amount to be deposited, else the token1 amount withdrawn.
    /// @param isAddToken0 IsAddToken0 if true. IsSubToken0 if false.
    /// @param isAddToken1 IsAddToken1 if true. IsSubToken0 if false.
    function updateProcess(Process[] storage processing, uint256 token0Amount, uint256 token1Amount, bool isAddToken0, bool isAddToken1) internal {
        for (uint256 i; i < processing.length; ) {
            Process storage process = processing[i];

            if (token0Amount != 0) process.balance0Target = isAddToken0 ? process.balance0Target + token0Amount : process.balance0Target - token0Amount;

            if (token1Amount != 0) process.balance1Target = isAddToken1 ? process.balance1Target + token1Amount : process.balance1Target - token1Amount;

            unchecked {
                i++;
            }
        }
    }
}
