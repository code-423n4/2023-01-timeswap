# Timeswap contest details
- Total Prize Pool: $90,500 USDC
  - HM awards: $63,750 USDC 
  - QA report awards: $7,500 USDC 
  - Gas report awards: $3,750 USDC 
  - Judge + presort awards: $15,000 USDC
  - Scout awards: $500 USDC
- Join [C4 Discord](https://discord.gg/code4rena) to register
- Submit findings [using the C4 form](https://code4rena.com/contests/2023-01-timeswap-contest/submit)
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts January 20, 2023 20:00 UTC
- Ends January 27, 2023 20:00 UTC

## C4udit / Publicly Known Issues

The C4audit output for the contest can be found [here](add link to report) within an hour of contest opening.

*Note for C4 wardens: Anything included in the C4udit output is considered a publicly known issue and is ineligible for awards.*

[ ⭐️ SPONSORS ADD INFO HERE ]

# Overview

- A Timeswap pool uses the Duration Weighted Constant Product automated market maker (AMM) similar to Uniswap. It is designed specifically for pricing of Timeswap options.
  Let 𝑥 be the borrow position with token0 as collateral, Let y be the borrow position with token1 as collateral. Let 𝑧 be the lending position per second in the pool.
  Let 𝑑 be the duration of the pool, thus 𝑑𝑧 is the total number of lending positions in the pool.
  Let 𝐿 be the square root of the constant product of the AMM. (𝑘 = 𝐿2) Let 𝐼 be the marginal interest rate per second of the Short per total Long.
  (𝑥 + 𝑦)𝑧 =𝐿(square)
- The token does not conform to ERC20 standard, it uses ERC1155 standard.
- As this is a monorepo, where remappings are required for compilation there might be [issues](https://github.com/crytic/crytic-compile/issues/279) when running slither
- [Link to Documentation](https://petal-cornflower-1db.notion.site/Timeswap-V2-Product-Spec-08ec22e83bb94c0dbb619c8d252c3dc2) (Note: this requires a notion account to view)
- [Link to whitepaper](https://github.com/code-423n4/2022-10-timeswap/blob/main/whitepaper.pdf)
# Scope


| Contract | SLOC | Purpose | Libraries used |  
| ----------- | ----------- | ----------- | ----------- |
| [packages/v2-library/src/BytesLib.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-library/src/BytesLib.sol) | 33 |Bytes Array utils  |  |
| [packages/v2-library/src/SafeCast.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-library/src/SafeCast.sol) | 18 |Library for castings  |  |
| [packages/v2-library/src/FullMath.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-library/src/FullMath.sol)| 140 |Math utils  |  |
| [packages/v2-library/src/Error.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-library/src/Error.sol) | 63 | Error utils  |  |
| [packages/v2-library/src/Math.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-library/src/Math.sol) | 91 | Math utils  |  |
| [packages/v2-library/src/Ownership.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-library/src/Ownership.sol) | 20 |Ownership utils  |  |
| [packages/v2-library/src/StrikeConversion.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-library/src/StrikeConversion.sol) | 28 |Strike conversion utils  |  |
| [packages/v2-library/src/CatchError.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-library/src/CatchError.sol) | 6 |Error utils  |  |
| [packages/v2-pool/src/TimeswapV2Pool.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/TimeswapV2Pool.sol) | 403 | Pool contract  | "@timeswap-labs/v2-library/", "@timeswap-labs/v2-option/" |
| [packages/v2-pool/src/TimeswapV2PoolDeployer.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/TimeswapV2PoolDeployer.sol) | 22 | Contract which deploys  Timeswap V2 pool|  |
| [packages/v2-pool/src/TimeswapV2PoolFactory.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/TimeswapV2PoolFactory.sol) | 40 | Pool factory contract  | "@timeswap-labs/v2-library/", "@timeswap-labs/v2-option/" |
| [packages/v2-pool/src/NoDelegateCall.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/NoDelegateCall.sol) | 15 | Prevents delegatecall to a contract |  |
| [packages/v2-pool/src/interfaces/IOwnableTwoSteps.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/interfaces/IOwnableTwoSteps.sol) | 5 | Interface for OwnableTwoSteps contract |  |
| [packages/v2-pool/src/interfaces/ITimeswapV2Pool.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/interfaces/ITimeswapV2Pool.sol) | 88 | Interface for Timeswap V2 pool contract | "@timeswap-labs/v2-option/" |
| [packages/v2-pool/src/interfaces/ITimeswapV2PoolDeployer.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/interfaces/ITimeswapV2PoolDeployer.sol) | 3 | Interface for Timeswap V2 pool deployer contract |  |
| [packages/v2-pool/src/interfaces/ITimeswapV2PoolFactory.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/interfaces/ITimeswapV2PoolFactory.sol) | 5 | Interface for Timeswap V2 pool factory contract |  |
| [packages/v2-pool/src/interfaces/callbacks/ITimeswapV2PoolBurnCallback.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/interfaces/callbacks/ITimeswapV2PoolBurnCallback.sol) | 5 | Interface for Timeswap V2 pool burn callback |  |
| [packages/v2-pool/src/interfaces/callbacks/ITimeswapV2PoolRebalanceCallback.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/interfaces/callbacks/ITimeswapV2PoolRebalanceCallback.sol) | 4 | Interface for Timeswap V2 pool rebalance callback |  |
| [packages/v2-pool/src/interfaces/callbacks/ITimeswapV2PoolLeverageCallback.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/interfaces/callbacks/ITimeswapV2PoolLeverageCallback.sol) | 4 | Interface for Timeswap V2 pool leverage callback |  |
| [packages/v2-pool/src/interfaces/callbacks/ITimeswapV2PoolMintCallback.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/interfaces/callbacks/ITimeswapV2PoolMintCallback.sol) | 4 | Interface for Timeswap V2 pool mint callback |  |
| [packages/v2-pool/src/interfaces/callbacks/ITimeswapV2PoolDeleverageCallback.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/interfaces/callbacks/ITimeswapV2PoolDeleverageCallback.sol) | 4 | Interface for Timeswap V2 pool deleverage callback |  |
| [packages/v2-pool/src/base/OwnableTwoSteps.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/base/OwnableTwoSteps.sol) | 25 | Ownable contract with two steps | "@timeswap-labs/v2-library/" |
| [packages/v2-pool/src/structs/CallbackParam.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/structs/CallbackParam.sol) | 77 | Struct for callback parameters |  |
|[packages/v2-pool/src/structs/LiquidityPosition.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/structs/LiquidityPosition.sol) | 89 | Struct for liquidity position | "@timeswap-labs/v2-library/" |
| [packages/v2-pool/src/structs/Param.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/structs/Param.sol) | 100 | Struct for parameters | "@timeswap-labs/v2-library/"|
|[packages/v2-pool/src/structs/Pool.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/structs/Pool.sol) | 501 | Struct for pool | "@timeswap-labs/v2-library/", "@timeswap-labs/v2-option/" |
| [packages/v2-pool/src/libraries/ConstantProduct.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/ConstantProduct.sol) | 184 | Constant product library | "@timeswap-labs/v2-library/" |
|[packages/v2-pool/src/libraries/FeeCalculation.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/FeeCalculation.sol) | 36 | Fee calculation library | "@timeswap-labs/v2-library/"|
|[packages/v2-pool/src/libraries/Duration.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/Duration.sol) | 8 | Duration library |  |
|[packages/v2-pool/src/libraries/PoolFactory.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/PoolFactory.sol) | 20 | Pool factory library | "@timeswap-labs/v2-library/", "@timeswap-labs/v2-option/" |
|[packages/v2-pool/src/libraries/ConstantSum.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/ConstantSum.sol) | 20 | Constant sum library | "@timeswap-labs/v2-library/" |
|[packages/v2-pool/src/libraries/DurationCalculation.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/DurationCalculation.sol) | 20 | Duration calculation library | "@timeswap-labs/v2-library/" |
|[packages/v2-pool/src/libraries/DurationWeight.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/DurationWeight.sol) | 20 | Duration weight library | "@timeswap-labs/v2-library/" |
|[packages/v2-pool/src/libraries/Fee.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/Fee.sol) | 7 | Fee library |  |
|[packages/v2-pool/src/libraries/PoolPair.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/PoolPair.sol) | 11 | Pool pair library |  |
|[packages/v2-pool/src/libraries/ReentrancyGuard.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/ReentrancyGuard.sol) | 12 | Reentrancy guard library |  |
|[packages/v2-pool/src/enums/Transaction.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/enums/Transaction.sol) | 50 | Transaction enum |  |
| [packages/v2-token/src/interfaces/ITimeswapV2Token.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-token/src/interfaces/ITimeswapV2Token.sol) | 6 |Interface Timeswap Token  | "openzeppelin/*"  |
| [packages/v2-token/src/interfaces/ITimeswapV2LiquidityToken.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-token/src/interfaces/ITimeswapV2LiquidityToken.sol) | 15 |Interface Timeswap Liquidity Token  |  |
| [packages/v2-token/src/interfaces/IERC1155Enumerable.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-token/src/interfaces/IERC1155Enumerable.sol)| 6 | Interface Helper Enumerable  | "openzeppelin/*"   |
| [packages/v2-token/src/base/ERC1155Enumerable.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-token/src/base/ERC1155Enumerable.sol) | 86 | Helper Enumerable  |  "openzeppelin/*"  |
| [packages/v2-token/src/TimeswapV2LiquidityToken.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-token/src/TimeswapV2LiquidityToken.sol) | 200 | Timeswap Liquidity Token   | "openzeppelin/*" , "timeswap-labs/v2-pool/*", "@timeswap-labs/v2-library/*"  |
| [packages/v2-token/src/TimeswapV2Token.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-token/src/TimeswapV2Token.sol) | 222 |Timeswap Token | "openzeppelin/*" , "timeswap-labs/v2-pool/*", "@timeswap-labs/v2-option/*" , "@timeswap-labs/v2-library/*"  |
| [packages/v2-token/src/interfaces/callbacks/ITimeswapV2LiquidityTokenMintCallback.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-token/src/interfaces/callbacks/ITimeswapV2LiquidityTokenMintCallback.sol) | 4 |Interface Liquidity Token Mint Callback  |  |
| [packages/v2-token/src/interfaces/callbacks/ITimeswapV2TokenMintCallback.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-token/src/interfaces/callbacks/ITimeswapV2TokenMintCallback.sol) | 4 |Interface Token Mint Callback  |  |
| [packages/v2-token/src/structs/CallbackParam.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-token/src/structs/CallbackParam.sol) | 19 |Callback Params Structure |  |
| [packages/v2-token/src/structs/FeesPosition.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-token/src/structs/FeesPosition.sol) | 44 |Fees Positions Structure   |  "timeswap-labs/v2-pool/*", "@timeswap-labs/v2-library/*"  |
| [packages/v2-token/src/structs/Param.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-token/src/structs/Param.sol)| 76 | Params Structure  |  "@timeswap-labs/v2-library/*"  |
| [packages/v2-token/src/structs/Position.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-token/src/structs/Position.sol) | 23 | Position Structure  | "@timeswap-labs/v2-option/*"   |
| [packages/v2-option/src/interfaces/ITimeswapV2Option.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/interfaces/ITimeswapV2Option.sol) | 55 |Option Interface  |  |
| [packages/v2-option/src/interfaces/ITimeswapV2OptionDeployer.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/interfaces/ITimeswapV2OptionDeployer.sol) | 3 |Option deployer interface |  |
| [packages/v2-option/src/interfaces/ITimeswapV2OptionFactory.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/interfaces/ITimeswapV2OptionFactory.sol)| 4 | Option factory interface |  |
| [packages/v2-option/src/interfaces/callbacks/ITimeswapV2OptionSwapCallback.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/interfaces/callbacks/ITimeswapV2OptionSwapCallback.sol) | 4 | Option swap callback interface  |  |
| [	packages/v2-option/src/interfaces/callbacks/ITimeswapV2OptionMintCallback.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/interfaces/callbacks/ITimeswapV2OptionMintCallback.sol) | 4 | Option mint callback interface  |  |
| [packages/v2-option/src/interfaces/callbacks/ITimeswapV2OptionCollectCallback.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/interfaces/callbacks/ITimeswapV2OptionCollectCallback.sol) | 4 | Option collect callback interface  |  |
| [packages/v2-option/src/interfaces/callbacks/ITimeswapV2OptionBurnCallback.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/interfaces/callbacks/ITimeswapV2OptionBurnCallback.sol) | 4 | Option burn callback interface  |  |
| [packages/v2-option/src/TimeswapV2OptionDeployer.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/TimeswapV2OptionDeployer.sol) | 16 | Option Deployer  |  |
| [packages/v2-option/src/structs/Process.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/structs/Process.sol) | 25 |Process libary  |  |
| [packages/v2-option/src/structs/CallbackParam.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/structs/CallbackParam.sol) | 33 |Callback param structs  |  |
| [packages/v2-option/src/structs/StrikeAndMaturity.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/structs/StrikeAndMaturity.sol) | 5 | Strike and Maturity utils  |  |
| [packages/v2-option/src/structs/Option.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/structs/Option.sol) | 117 | Option struct library  |  "@timeswap-labs/v2-library/*" |
| [packages/v2-option/src/structs/Param.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/structs/Param.sol) | 82 | Params for the contract |  "@timeswap-labs/v2-library/*"   |
| [packages/v2-option/src/NoDelegateCall.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/NoDelegateCall.sol) | 15 | To ensure delegate call is not made  |  |
| [packages/v2-option/src/TimeswapV2OptionFactory.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/TimeswapV2OptionFactory.sol) | 29 | Option Factory contract  |  "openzeppelin/*", "@timeswap-labs/v2-library/*"  |
| [packages/v2-option/src/libraries/Proportion.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/libraries/Proportion.sol) | 7 | Proportion util contract  | "@timeswap-labs/v2-library/*"  |
| [packages/v2-option/src/libraries/OptionPair.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/libraries/OptionPair.sol) | 15 | Option related functions  |  |
| [packages/v2-option/src/libraries/OptionFactory.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/libraries/OptionFactory.sol) | 18 | Library for option factory  |  "@timeswap-labs/v2-library/*" |
| [packages/v2-option/src/enums/Transaction.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/enums/Transaction.sol) | 33 | Different transaction types enum  |  |
| [packages/v2-option/src/enums/Position.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/enums/Position.sol) | 12 | Option position types enum |  |
| [packages/v2-option/src/TimeswapV2Option.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-option/src/TimeswapV2Option.sol) | 234 | Different transaction types enum  | "openzeppelin/*" , "@timeswap-labs/v2-library/"   |

### V2-Pool
| Contract | Library/Struct |
| --- | --- |
| [packages/v2-pool/src/enums/Transaction.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/enums/Transaction.sol) | Library |
| [packages/v2-pool/src/libraries/ConstantProduct.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/ConstantProduct.sol) | Library |
| [packages/v2-pool/src/libraries/ConstantSum.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/ConstantSum.sol) | Library |
| [packages/v2-pool/src/libraries/Duration.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/Duration.sol) | Library |
| [packages/v2-pool/src/libraries/DurationCalculation.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/DurationCalculation.sol) | Library |
| [packages/v2-pool/src/libraries/DurationWeight.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/DurationWeight.sol) | Library |
| [packages/v2-pool/src/libraries/Fee.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/Fee.sol) | Library |
| [packages/v2-pool/src/libraries/FeeCalculation.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/FeeCalculation.sol) | Library |
| [packages/v2-pool/src/libraries/PoolFactory.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/PoolFactory.sol) | Library |
| [packages/v2-pool/src/libraries/PoolPair.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/PoolPair.sol) | Library |
| [packages/v2-pool/src/libraries/ReentrancyGuard.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/libraries/ReentrancyGuard.sol) | Library |
| [packages/v2-pool/src/structs/CallbackParam.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/structs/CallbackParam.sol) | Struct |
| [packages/v2-pool/src/structs/LiquidityPosition.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/structs/LiquidityPosition.sol) | Struct |
| [packages/v2-pool/src/structs/Param.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/structs/Param.sol) | Library |
| [packages/v2-pool/src/structs/Pool.sol](https://github.com/code-423n4/2022-10-timeswap/blob/main/packages/v2-pool/src/structs/Pool.sol) | Library |


## Out of scope

Any test file i.e.`**.t.sol`
# Additional Context
Timeswap V2 is a decentralized and oracle-less fixed maturity lending and borrowing protocol. It uses a triple constant product formula to determine the interest  and collateral factor of every transaction.

Timeswap V2 has the following 4 packages in scope:

1. v2-Option
2. v2-Pool
3. v2-Token
4. v2-Library

In the following sections, we will be discussing each of the packages in greater depth.

## Timeswap v2-Option

Timeswap option is a close implementation of European option given the caveats of writing smart contracts in Ethereum. 

Given a pair of tokens, defined as token0 and token1, the option is fully collateralized with either one of the tokens. When the option has locked token0, then it gives the holder the right but not the obligation to swap token1 for token0 before the maturity of the option. When the option has locked token1, then the holder can swap token0 for token1. When the swap is exercised, the token that is deposited becomes the new locked token of the option, giving the holder the right but not the obligation to swap the tokens back before maturity. This design gives the holder the ability to swap token0 and token1 back and forth at a given strike rate, for however many times before the expiry of the option.

## Timeswap v2-Pool

A Timeswap pool is a protocol that gives the user the ability to swap Long 0 and/or Long 1 for Short Timeswap options, and vice versa. A Timeswap pool uses the Constant Product automated market maker (AMM) similar to Uniswap. It is designed specifically for the pricing of Timeswap options.

For lending, the user locks the Token0/Token1, mint Short option, and Long 0/Long 1 option. Then deposits the Long option minted to the pool, to withdraw more Short options from the pool.

For borrowing, the user lock the Token0/Token1, mint Short option, and Long 0/Long 1 option. Then deposits the Short option to the pool, to withdraw more Long 0/Long 1 options from the pool.

As one can see, all three products are fundamentally the same transactions with differences in how tokens are transferred. DEX protocol is used to make these transactions more fluid, whenever necessary.

## **Timeswap v2-Token**

The Timeswap v2 Protocol has 2 tokens that are implemented.  The `Timeswap V2 Token` and the `Timeswap V2 Liquidity Token`

The `Timeswap V2 Liquidit Token` just holds the different liquidity position that user has, while the `Timeswap V2 Token` is a representation of the amount of `Long0, Long1, Short` that a user holds in a particular pool


## Scoping Details 
```
- If you have a public code repo, please share it here: N/A
- How many contracts are in scope?: 70 
- Total SLoC for these contracts?: 3659 [Solidity Metrics](https://github.com/ConsenSys/solidity-metrics) was used for calculating the nSLoC
- How many external imports are there?: 4
- How many separate interfaces and struct definitions are there for the contracts within scope?: 19 and 38
- Does most of your code generally use composition or inheritance?: Primarily inheritance, but composition is also leveraged up to some degree.  
- How many external calls?: 0
  - What is the overall line coverage percentage provided by your tests?: ~50 (`forge coverage` currently throws a "stack too deep" error on large codebases)
- Is there a need to understand a separate part of the codebase / get context in order to audit this part of the protocol?: No  
- Please describe required context: N/A  
- Does it use an oracle?: No
- Does the token conform to the ERC20 standard?: Yes
- Are there any novel or unique curve logic or mathematical models?: We use a 3 variable AMM - (x+y)z=k
- Does it use a timelock function?: No
- Is it an NFT?: No
- Does it have an AMM?: Yes
- Is it a fork of a popular project?: No  
- Does it use rollups?: No
- Is it multi-chain?: No  
- Does it use a side-chain?: Yes and it evm-compatible.
```

# Tests

Tests are currently work in progress
To run the tests for code in each of the directories, run the following command at that directory
```
yarn
yarn hardhat clean
yarn hardhat compile
forge build
forge test
```
