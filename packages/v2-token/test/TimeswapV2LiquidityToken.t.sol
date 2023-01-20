// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import "forge-std/Test.sol";

import "forge-std/console.sol";

import "../src/TimeswapV2LiquidityToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@timeswap-labs/v2-option/src/TimeswapV2OptionFactory.sol";
import "@timeswap-labs/v2-option/src/interfaces/ITimeswapV2Option.sol";

import "@timeswap-labs/v2-pool/src/TimeswapV2PoolFactory.sol";
import "@timeswap-labs/v2-pool/src/interfaces/ITimeswapV2Pool.sol";
import {TimeswapV2PoolMintParam} from "@timeswap-labs/v2-pool/src/structs/Param.sol";
import {TimeswapV2PoolMintChoiceCallbackParam, TimeswapV2PoolMintCallbackParam} from "@timeswap-labs/v2-pool/src/structs/CallbackParam.sol";

import {TimeswapV2OptionMintCallbackParam, TimeswapV2OptionSwapCallbackParam} from "@timeswap-labs/v2-option/src/structs/CallbackParam.sol";

// import "@timeswap-labs/v2-option/src/TimeswapV2OptionFactory.sol";
// // import "@timeswap-labs/v2-option/src/interfaces/ITimeswapV2Option.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {TimeswapV2LiquidityTokenPosition} from "../src/structs/Position.sol";
import {TimeswapV2PoolMint} from "@timeswap-labs/v2-pool/src/enums/Transaction.sol";
import {TimeswapV2OptionMint} from "@timeswap-labs/v2-option/src/enums/Transaction.sol";

import {StrikeConversion} from "@timeswap-labs/v2-library/src/StrikeConversion.sol";
import {DurationCalculation} from "@timeswap-labs/v2-pool/src/libraries/DurationCalculation.sol";
import {FullMath} from "@timeswap-labs/v2-library/src/FullMath.sol";

contract HelperERC20 is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(msg.sender, type(uint256).max);
    }
}
struct Timestamps {
    uint256 maturity;
    uint256 timeNow;
}
struct MintOutput {
    uint160 liquidityAmount;
    uint256 long0Amount;
    uint256 long1Amount;
    uint256 shortAmount;
    bytes data;
}

contract TimeswapV2LiquidityTokenTest is Test, ERC1155Holder {
    ITimeswapV2Option opPair;
    TimeswapV2OptionFactory optionFactory;
    TimeswapV2PoolFactory poolFactory;
    ITimeswapV2Pool pool;

    uint256 chosenTransactionFee = 5;
    uint256 chosenProtocolFee = 4;

    HelperERC20 token0;
    HelperERC20 token1;
    TimeswapV2LiquidityToken mockLiquidityToken;

    function timeswapV2PoolMintChoiceCallback(TimeswapV2PoolMintChoiceCallbackParam calldata param) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data) {
        vm.assume(param.longAmount < (1 << 127));
        long0Amount = StrikeConversion.turn(param.longAmount / 2, param.strike, false, true) + 1;
        long1Amount = StrikeConversion.turn(param.longAmount / 2, param.strike, true, true) + 1;
        vm.assume(
            param.longAmount < StrikeConversion.combine(long0Amount, long1Amount, param.strike, false) && param.shortAmount < StrikeConversion.combine(long0Amount, long1Amount, param.strike, false)
        );
    }

    function timeswapV2PoolMintCallback(TimeswapV2PoolMintCallbackParam calldata param) external returns (bytes memory data) {
        // have to transfer param.long0Amount, param.long1Amount and param.short to msg.sender
        console.log(param.long0Amount, param.long1Amount);
        TimeswapV2OptionMintParam memory mparam = TimeswapV2OptionMintParam({
            strike: param.strike,
            maturity: param.maturity,
            long0To: msg.sender,
            long1To: msg.sender,
            shortTo: msg.sender,
            transaction: TimeswapV2OptionMint.GivenTokensAndLongs,
            amount0: param.long0Amount,
            amount1: param.long1Amount,
            data: ""
        });
        opPair.mint(mparam);
    }

    function timeswapV2OptionMintCallback(TimeswapV2OptionMintCallbackParam calldata param) external returns (bytes memory data) {
        data = param.data;
        // console.log(token0.balanceOf(address(this)));
        // console.log(token1.balanceOf(address(this)));
        token0.transfer(msg.sender, param.token0AndLong0Amount);
        token1.transfer(msg.sender, param.token1AndLong1Amount);
    }

    function timeswapV2OptionSwapCallback(TimeswapV2OptionSwapCallbackParam calldata param) external returns (bytes memory data) {
        data = param.data;
        HelperERC20 token = param.isLong0ToLong1 ? token1 : token0;
        token.transfer(msg.sender, param.isLong0ToLong1 ? param.token1AndLong1Amount : param.token0AndLong0Amount);
    }

    function isMulDivPossible(uint256 multiplicand, uint256 multiplier, uint256 divisor) internal returns (bool) {
        (uint256 product0, uint256 product1) = FullMath.mul512(multiplicand, multiplier);
        if (divisor <= product1 || (product1 == 0 && product0 < divisor)) {
            return false;
        }
        return true;
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
        mockLiquidityToken = new TimeswapV2LiquidityToken(address(optionFactory), address(poolFactory));
    }

    // function testERC20BalanceOf() public {
    //     // setUp();
    //     assertEq(token0.balanceOf(address(this)), type(uint256).max);
    //     assertEq(token1.balanceOf(address(this)), type(uint256).max);
    // }

    function testMint(uint256 strike, uint160 amt, uint256 maturity, uint256 delta, uint160 rate, address to) public {
        setUp();

        // vm.assume(strike != 0 && (maturity < type(uint96).max) && (maturity > 10000) && amt > 100 && delta != 0 && rate != 0);
        vm.assume(to != address(0));
        vm.assume(
            maturity < type(uint96).max &&
                amt < type(uint160).max &&
                amt != 0 &&
                to != address(0) &&
                strike != 0 &&
                delta != 0 &&
                maturity > block.timestamp &&
                isMulDivPossible(delta, uint256(1) << 192, uint256(rate) * DurationCalculation.unsafeDurationFromNowToMaturity(maturity, uint96(block.timestamp))) &&
                FullMath.mulDiv(delta, uint256(1) << 192, uint256(rate) * DurationCalculation.unsafeDurationFromNowToMaturity(maturity, uint96(block.timestamp)), true) < type(uint160).max &&
                (uint256(FullMath.mulDiv(delta, uint256(1) << 192, uint256(rate) * DurationCalculation.unsafeDurationFromNowToMaturity(maturity, uint96(block.timestamp)), true)) << 96) > rate
        );
        console.log("init");
        pool.initialize(strike, maturity, rate);

        TimeswapV2PoolMintParam memory param = TimeswapV2PoolMintParam({strike: strike, maturity: maturity, to: msg.sender, transaction: TimeswapV2PoolMint.GivenLiquidity, delta: amt, data: ""});

        MintOutput memory response;
        (response.liquidityAmount, response.long0Amount, response.long1Amount, response.shortAmount, response.data) = pool.mint(param);

        TimeswapV2LiquidityTokenMintParam memory liqTokenMintParam = TimeswapV2LiquidityTokenMintParam({
            token0: address(token0),
            token1: address(token1),
            strike: strike,
            maturity: maturity,
            to: msg.sender,
            liquidityAmount: amt,
            data: ""
        });

        // mockLiquidityToken.mint(liqTokenMintParam);
        console.log("yo");
        uint256 liqAmt = mockLiquidityToken.positionOf(msg.sender, TimeswapV2LiquidityTokenPosition({token0: address(token0), token1: address(token1), strike: strike, maturity: maturity}));
        console.log("liqAmt", liqAmt);
        // assertGe(liqAmt, 1);
    }

    // function testPositionOf(uint256 _strike, uint256 _maturity) public {
    //     setUp();
    //     TimeswapV2LiquidityTokenPosition memory liquidityPosition = TimeswapV2LiquidityTokenPosition({token0: address(token0), token1: address(token1), strike: _strike, maturity: _maturity});
    //     uint256 liqAmt = mockLiquidityToken.positionOf(msg.sender, liquidityPosition);
    //     assertEq(liqAmt, 0);
    // }
}
