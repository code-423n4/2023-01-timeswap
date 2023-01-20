// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "@timeswap-labs/v2-pool/src/TimeswapV2PoolFactory.sol";
import "@timeswap-labs/v2-pool/src/interfaces/ITimeswapV2Pool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@timeswap-labs/v2-option/src/TimeswapV2OptionFactory.sol";
import "@timeswap-labs/v2-option/src/interfaces/ITimeswapV2Option.sol";
import {TimeswapV2PoolMint, TimeswapV2PoolBurn, TimeswapV2PoolDeleverage, TimeswapV2PoolLeverage, TimeswapV2PoolRebalance, TransactionLibrary} from "@timeswap-labs/v2-pool/src/enums/Transaction.sol";
import {TimeswapV2PoolCollectParam, TimeswapV2PoolMintParam, TimeswapV2PoolBurnParam, TimeswapV2PoolDeleverageParam, TimeswapV2PoolLeverageParam, TimeswapV2PoolRebalanceParam} from "@timeswap-labs/v2-pool/src/structs/Param.sol";
import {TimeswapV2PoolMintChoiceCallbackParam, TimeswapV2PoolMintCallbackParam} from "@timeswap-labs/v2-pool/src/structs/CallbackParam.sol";
import {StrikeConversion} from "@timeswap-labs/v2-library/src/StrikeConversion.sol";
import {TimeswapV2OptionMintParam} from "@timeswap-labs/v2-option/src/structs/Param.sol";
import {TimeswapV2OptionMintCallbackParam, TimeswapV2OptionSwapCallbackParam} from "@timeswap-labs/v2-option/src/structs/CallbackParam.sol";
import {TimeswapV2OptionMint} from "@timeswap-labs/v2-option/src/enums/Transaction.sol";
import {ConstantProduct} from "@timeswap-labs/v2-pool/src/libraries/ConstantProduct.sol";
import {DurationCalculation} from "@timeswap-labs/v2-pool/src/libraries/DurationCalculation.sol";
import {TimeswapV2TokenMintParam, TimeswapV2TokenBurnParam} from "../src/structs/Param.sol";
import {SafeCast} from "@timeswap-labs/v2-library/src/SafeCast.sol";
import {FullMath} from "@timeswap-labs/v2-library/src/FullMath.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {ITimeswapV2OptionMintCallback} from "@timeswap-labs/v2-option/src/interfaces/callbacks/ITimeswapV2OptionMintCallback.sol";
import {ITimeswapV2TokenMintCallback} from "../src/interfaces/callbacks/ITimeswapV2TokenMintCallback.sol";
import {TimeswapV2Token} from "../src/TimeswapV2Token.sol";
import {TimeswapV2OptionPosition} from "@timeswap-labs/v2-option/src/enums/Position.sol";
import {TimeswapV2TokenMintCallbackParam} from "../src/structs/CallbackParam.sol";

contract HelperERC20 is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(msg.sender, type(uint256).max);
    }
}

contract TimeswapV2TokenTest is Test, ERC1155Holder, ITimeswapV2OptionMintCallback, ITimeswapV2TokenMintCallback {
    TimeswapV2OptionFactory optionFactory;
    ITimeswapV2Option opPair;
    TimeswapV2PoolFactory poolFactory;
    ITimeswapV2Pool pool;
    HelperERC20 token0;
    HelperERC20 token1;
    TimeswapV2Token token;
    uint256 chosenTransactionFee = 5;
    uint256 chosenProtocolFee = 4;
    uint256 strike;
    uint256 maturity;
    uint256 token0Amount;
    uint256 token1Amount;
    uint256 long0Amount;
    uint256 long1Amount;
    uint256 shortAmount;
    struct Timestamps {
        uint256 maturity;
        uint256 timeNow;
    }

    function testSample() public {
        assertTrue(true);
    }

    //       struct CacheForTimeswapV2PoolMintChoiceCallback {
    //     address token0;
    //     address token1;
    //     address liquidityTo;
    //     address excessLong0To;
    //     address excessLong1To;
    //     address excessShortTo;
    //     bool preferLong0Excess;
    //     uint256 token0Amount;
    //     uint256 token1Amount;
    //   }
    function timeswapV2TokenMintCallback(TimeswapV2TokenMintCallbackParam calldata param) external override returns (bytes memory data) {
        ITimeswapV2Option(opPair).transferPosition(param.strike, param.maturity, msg.sender, TimeswapV2OptionPosition.Long0, param.long0Amount);
        ITimeswapV2Option(opPair).transferPosition(param.strike, param.maturity, msg.sender, TimeswapV2OptionPosition.Long1, param.long1Amount);
        ITimeswapV2Option(opPair).transferPosition(param.strike, param.maturity, msg.sender, TimeswapV2OptionPosition.Short, param.shortAmount);
    }

    function timeswapV2OptionMintCallback(TimeswapV2OptionMintCallbackParam memory param) external override returns (bytes memory data) {
        // CacheForTimeswapV2OptionMintCallback memory cache;
        // (cache, data) = abi.decode(param.data, (CacheForTimeswapV2OptionMintCallback, bytes));

        // Verify.timeswapV2Option(optionFactory, cache.token0, cache.token1);

        // excessLong0Amount = cache.excessLong0Amount;
        // excessLong1Amount = cache.excessLong1Amount;
        // excessShortAmount = cache.excessShortAmount;

        // if (cache.excessLong0Amount != 0 || cache.excessLong1Amount != 0 || cache.excessShortAmount != 0)
        //   ITimeswapV2Token(tokens).mint(
        //     TimeswapV2TokenMintParam({
        //       token0: cache.token0,
        //       token1: cache.token1,
        //       strike: param.strike,
        //       maturity: param.maturity,
        //       long0To: cache.excessLong0Amount == 0 ? address(this) : cache.excessLong0To,
        //       long1To: cache.excessLong1Amount == 0 ? address(this) : cache.excessLong1To,
        //       shortTo: cache.excessShortAmount == 0 ? address(this) : cache.excessShortTo,
        //       long0Amount: cache.excessLong0Amount,
        //       long1Amount: cache.excessLong1Amount,
        //       shortAmount: cache.excessShortAmount,
        //       data: bytes('')
        //     })
        //   );

        // data = timeswapV2PeripheryAddLiquidityGivenPrincipalInternal(
        //   TimeswapV2PeripheryAddLiquidityGivenPrincipalInternalParam({
        //     optionPair: msg.sender,
        //     token0: cache.token0,
        //     token1: cache.token1,
        //     strike: param.strike,
        //     maturity: param.maturity,
        //     token0Amount: param.token0AndLong0Amount,
        //     token1Amount: param.token1AndLong1Amount,
        //     liquidityAmount: cache.liquidityAmount,
        //     excessLong0Amount: cache.excessLong0Amount,
        //     excessLong1Amount: cache.excessLong1Amount,
        //     excessShortAmount: cache.excessShortAmount,
        //     data: data
        //   })
        // );
        token0.transfer(msg.sender, param.token0AndLong0Amount);
        token1.transfer(msg.sender, param.token1AndLong1Amount);
        console.log("callback is done");
    }

    function setUp() public {
        optionFactory = new TimeswapV2OptionFactory();
        token0 = new HelperERC20("Token A", "A");
        token1 = new HelperERC20("Token B", "B");
        if (address(token1) < address(token0)) {
            (token0, token1) = (token1, token0);
        }
        address opAddress = optionFactory.create(address(token0), address(token1));
        opPair = ITimeswapV2Option(opAddress);
        poolFactory = new TimeswapV2PoolFactory(address(this), chosenTransactionFee, chosenProtocolFee);
        pool = ITimeswapV2Pool(poolFactory.create(opAddress));
        token = new TimeswapV2Token(address(optionFactory));

        // opPair.mint()
    }

    function testMint(uint256 strike, uint256 maturity, uint256 token0Amount, uint256 token1Amount) public {
        // opPair.mint()
        // token0Amount = 10
        token0Amount = 10;
        token1Amount = 10;
        vm.assume(strike > 0 && maturity > block.timestamp && maturity < type(uint96).max && token0Amount > 0 && token1Amount > 0);

        console.log(block.timestamp);
        setUp();
        console.log("initial done");
        bytes memory data;
        (long0Amount, long1Amount, shortAmount, data) = ITimeswapV2Option(opPair).mint(
            TimeswapV2OptionMintParam({
                strike: strike,
                maturity: maturity,
                long0To: address(this),
                long1To: address(this),
                shortTo: address(this),
                transaction: TimeswapV2OptionMint.GivenTokensAndLongs,
                amount0: token0Amount,
                amount1: token1Amount,
                data: bytes("")
            })
        );
        console.log(long0Amount, long1Amount, shortAmount);
        // console.log(I)
        token.mint(
            TimeswapV2TokenMintParam({
                token0: address(token0),
                token1: address(token1),
                strike: strike,
                maturity: maturity,
                long0To: address(this),
                long1To: address(this),
                shortTo: address(this),
                long0Amount: long0Amount,
                long1Amount: long1Amount,
                shortAmount: shortAmount,
                data: bytes("")
            })
        );
        token.burn(
            TimeswapV2TokenBurnParam({
                token0: address(token0),
                token1: address(token1),
                strike: strike,
                maturity: maturity,
                long0To: address(this),
                long1To: address(this),
                shortTo: address(this),
                long0Amount: long0Amount,
                long1Amount: long1Amount,
                shortAmount: shortAmount,
                data: bytes("")
            })
        );
    }
}
