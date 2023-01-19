//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

/// @dev A data with strike and maturity data.
/// @param strike The strike.
/// @param maturity The maturity.
struct StrikeAndMaturity {
    uint256 strike;
    uint256 maturity;
}
