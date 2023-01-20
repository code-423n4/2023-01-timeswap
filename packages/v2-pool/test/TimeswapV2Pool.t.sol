// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import 'forge-std/Test.sol';
import 'forge-std/console.sol';
import '../src/TimeswapV2PoolFactory.sol';
import '../src/interfaces/ITimeswapV2Pool.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@timeswap-labs/v2-option/src/TimeswapV2OptionFactory.sol';
import '@timeswap-labs/v2-option/src/interfaces/ITimeswapV2Option.sol';
import {TimeswapV2PoolMint, TimeswapV2PoolBurn, TimeswapV2PoolDeleverage, TimeswapV2PoolLeverage, TimeswapV2PoolRebalance, TransactionLibrary} from '../src/enums/Transaction.sol';
import {TimeswapV2PoolCollectParam, TimeswapV2PoolMintParam, TimeswapV2PoolBurnParam, TimeswapV2PoolDeleverageParam, TimeswapV2PoolLeverageParam, TimeswapV2PoolRebalanceParam} from '../src/structs/Param.sol';
import {TimeswapV2PoolMintChoiceCallbackParam, TimeswapV2PoolMintCallbackParam, TimeswapV2PoolDeleverageChoiceCallbackParam, TimeswapV2PoolDeleverageCallbackParam} from '../src/structs/CallbackParam.sol';
import {StrikeConversion} from '@timeswap-labs/v2-library/src/StrikeConversion.sol';
import {TimeswapV2OptionMintParam} from '@timeswap-labs/v2-option/src/structs/Param.sol';
import {TimeswapV2OptionMintCallbackParam, TimeswapV2OptionSwapCallbackParam} from '@timeswap-labs/v2-option/src/structs/CallbackParam.sol';
import {TimeswapV2OptionMint} from '@timeswap-labs/v2-option/src/enums/Transaction.sol';
import {ConstantProduct} from '../src/libraries/ConstantProduct.sol';
import {DurationCalculation} from '../src/libraries/DurationCalculation.sol';
import {SafeCast} from '@timeswap-labs/v2-library/src/SafeCast.sol';
import {FullMath} from '@timeswap-labs/v2-library/src/FullMath.sol';
import {TimeswapV2OptionPosition} from '@timeswap-labs/v2-option/src/enums/Position.sol';

import {TimeswapV2PoolBurnChoiceCallbackParam, TimeswapV2PoolBurnCallbackParam} from '../src/structs/CallbackParam.sol';

contract HelperERC20 is ERC20 {
  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
    _mint(msg.sender, type(uint256).max);
  }
}

contract TimeswapV2PoolTest is Test {
  TimeswapV2OptionFactory optionFactory;
  ITimeswapV2Option opPair;
  TimeswapV2PoolFactory poolFactory;
  ITimeswapV2Pool pool;
  HelperERC20 token0;
  HelperERC20 token1;
  // random values
  uint256 chosenTransactionFee = 5;
  uint256 chosenProtocolFee = 4;

    function isAddable(uint256 num1, uint256 num2) internal returns (bool) {
    return(num1 < type(uint256).max - num2);
  }

  function isMulDivPossible(
    uint256 multiplicand,
    uint256 multiplier,
    uint256 divisor
  ) internal returns (bool) {
    (uint256 product0, uint256 product1) = FullMath.mul512(multiplicand, multiplier);
    if(divisor <= product1 || (product1 == 0 && product0 < divisor)){
      return false;
    }
    return true;
  }

  struct MintOutput {
    uint160 liquidityAmount;
    uint256 long0Amount;
    uint256 long1Amount;
    uint256 shortAmount;
    bytes data;
  }

  struct Fees {
    uint256 token0;
    uint256 token1;
    uint256 shorts;
  }

  function timeswapV2OptionMintCallback(
    TimeswapV2OptionMintCallbackParam calldata param
  ) external returns (bytes memory data) {
    data = param.data;
    // console.log(token0.balanceOf(address(this)));
    // console.log(token1.balanceOf(address(this)));
    token0.transfer(msg.sender, param.token0AndLong0Amount);
    token1.transfer(msg.sender, param.token1AndLong1Amount);
  }

  function timeswapV2OptionSwapCallback(
    TimeswapV2OptionSwapCallbackParam calldata param
  ) external returns (bytes memory data) {
    data = param.data;
    HelperERC20 token = param.isLong0ToLong1 ? token1 : token0;
    token.transfer(msg.sender, param.isLong0ToLong1 ? param.token1AndLong1Amount : param.token0AndLong0Amount);
  }

  function timeswapV2PoolMintChoiceCallback(
    TimeswapV2PoolMintChoiceCallbackParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data) {
    vm.assume(param.longAmount < (1 << 127));
    long0Amount = StrikeConversion.turn(param.longAmount / 2, param.strike, false, true) + 1;
    long1Amount = StrikeConversion.turn(param.longAmount / 2, param.strike, true, true) + 1;
    vm.assume(
      param.longAmount < StrikeConversion.combine(long0Amount, long1Amount, param.strike, false) &&
        param.shortAmount < StrikeConversion.combine(long0Amount, long1Amount, param.strike, false)
    );
  }

  function timeswapV2PoolMintCallback(
    TimeswapV2PoolMintCallbackParam calldata param
  ) external returns (bytes memory data) {
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
      data: ''
    });
    opPair.mint(mparam);
  }

  function setUp() public {
    optionFactory = new TimeswapV2OptionFactory();
    token0 = new HelperERC20('Token A', 'A');
    token1 = new HelperERC20('Token B', 'B');
    if (address(token1) < address(token0)) {
      (token0, token1) = (token1, token0);
    }
    address opAddress = optionFactory.create(address(token0), address(token1));
    opPair = ITimeswapV2Option(opAddress);
    poolFactory = new TimeswapV2PoolFactory(address(this), chosenTransactionFee, chosenProtocolFee);
    pool = ITimeswapV2Pool(poolFactory.create(opAddress));
  }

  struct Timestamps {
    uint256 maturity;
    uint256 timeNow;
  }

  function testPoolList(
    uint256 strike,
    uint256 maturity,
    uint160 rate,
    uint256 _chosenTransactionFee,
    uint256 _chosenProtocolFee
  ) public {
    vm.assume(
      _chosenTransactionFee <= type(uint16).max &&
      _chosenProtocolFee <= type(uint16).max &&
      maturity > block.timestamp &&
      strike != 0 &&
      rate !=0
    );
    chosenTransactionFee = _chosenTransactionFee;
    chosenProtocolFee = _chosenProtocolFee;
    setUp();
    pool.initialize(strike, maturity, rate);
    assertEq(pool.getByIndex(0).strike, strike);
    assertEq(pool.getByIndex(0).maturity, maturity);
  }

  function testNumberOfPools(
    uint256 strike,
    uint256 maturity,
    uint160 rate,
    uint256 _chosenTransactionFee,
    uint256 _chosenProtocolFee
  ) public {
    vm.assume(
      _chosenTransactionFee <= type(uint16).max &&
      _chosenProtocolFee <= type(uint16).max &&
      maturity > block.timestamp &&
      strike != 0 &&
      rate !=0
    );
    chosenTransactionFee = _chosenTransactionFee;
    chosenProtocolFee = _chosenProtocolFee;
    setUp();
    pool.initialize(strike, maturity, rate);
    assertEq(pool.numberOfPools(), 1);
  }


  function testLiquidity(
    uint256 strike,
    address to,
    Timestamps calldata time,
    // uint256 maturity,
    // uint256 currentTimestamp,
    uint256 _chosenTransactionFee,
    uint256 _chosenProtocolFee,
    uint160 rate,
    uint256 delta
  ) public {
    vm.assume(
      time.maturity < type(uint96).max &&
      _chosenTransactionFee <= type(uint16).max &&
      _chosenProtocolFee <= type(uint16).max &&
      to != address(0) &&
      strike != 0 &&
      delta != 0 &&
      time.maturity > block.timestamp &&
      time.maturity < type(uint96).max && //confirmation needed
      rate > 0 &&
      isMulDivPossible(rate, delta, uint256(1) << 96) &&
      FullMath.mulDiv(rate, delta, uint256(1) << 96, true) < type(uint160).max
      && isMulDivPossible(
        FullMath.mulDiv(rate, delta, uint256(1) << 96, true) * DurationCalculation.unsafeDurationFromNowToMaturity(time.maturity, uint96(block.timestamp)),
        rate,
        uint256(1) << 192
      )
    );
    chosenTransactionFee = _chosenTransactionFee;
    chosenProtocolFee = _chosenProtocolFee;
    setUp();
    pool.initialize(strike, time.maturity, rate);
    
    TimeswapV2PoolMintParam memory param = TimeswapV2PoolMintParam({
      strike: strike,
      maturity: time.maturity,
      to: to,
      transaction: TimeswapV2PoolMint.GivenLong,
      delta: delta,
      data: ''
    });

    MintOutput memory response;
    (response.liquidityAmount, response.long0Amount, response.long1Amount, response.shortAmount, response.data) = pool
      .mint(param);
    assertEq(pool.totalLiquidity(strike, time.maturity), response.liquidityAmount);
    assertEq(pool.sqrtInterestRate(strike, time.maturity), rate);
    assertEq(pool.liquidityOf(strike, time.maturity, to), response.liquidityAmount);

    Fees memory f;
    (f.token0, f.token1, f.shorts) = pool.feeGrowth(strike, time.maturity);
    assertEq(f.token0, 0);
    assertEq(f.token1, 0);
    (f.token0, f.token1, f.shorts) = pool.protocolFeesEarned(strike, time.maturity);
    assertEq(f.token0, 0);
    assertEq(f.token1, 0);
    (f.token0, f.token1) = pool.totalLongBalance(strike, time.maturity);
    assertEq(f.token0, response.long0Amount);
    assertEq(f.token1, response.long1Amount);
    (f.token0, f.token1) = pool.totalLongBalanceAdjustFees(strike, time.maturity);
    assertTrue(f.token0 != 0);
    assertTrue(f.token1 != 0);
    vm.prank(to);
    // test if this function passes or not, also to get back the liquidity tokens
    pool.transferLiquidity(strike, time.maturity, address(this), response.liquidityAmount);
    (f.token0, f.token1, f.shorts) = pool.collectProtocolFees(TimeswapV2PoolCollectParam({
      strike: strike,
      maturity: time.maturity,
      long0To: address(this),
      long1To: address(this),
      shortTo: address(this),
      long0Requested: 1,
      long1Requested: 1,
      shortRequested: 1
    }));
    assertGe(f.token0, 0);
    assertGe(f.token1, 0);
    assertGe(f.shorts, 0);
    (f.token0, f.token1, f.shorts) = pool.collectTransactionFees(TimeswapV2PoolCollectParam({
      strike: strike,
      maturity: time.maturity,
      long0To: address(this),
      long1To: address(this),
      shortTo: address(this),
      long0Requested: 1,
      long1Requested: 1,
      shortRequested: 1
    }));
    assertGe(f.token0, 0);
    assertGe(f.token1, 0);
    assertGe(f.shorts, 0);
  }

  function testMintGivenLong(
    uint256 strike,
    address to,
    Timestamps calldata time,
    // uint256 maturity,
    // uint256 currentTimestamp,
    uint256 _chosenTransactionFee,
    uint256 _chosenProtocolFee,
    uint160 rate,
    uint256 delta
  ) public {
    vm.assume(
      time.maturity < type(uint96).max &&
      _chosenTransactionFee <= type(uint16).max &&
      _chosenProtocolFee <= type(uint16).max &&
      to != address(0) &&
      strike != 0 &&
      delta != 0 &&
      time.maturity > block.timestamp &&
      time.maturity < type(uint96).max && //confirmation needed
      rate > 0 &&
      isMulDivPossible(rate, delta, uint256(1) << 96) &&
      FullMath.mulDiv(rate, delta, uint256(1) << 96, true) < type(uint160).max
      && isMulDivPossible(
        FullMath.mulDiv(rate, delta, uint256(1) << 96, true) * DurationCalculation.unsafeDurationFromNowToMaturity(time.maturity, uint96(block.timestamp)),
        rate,
        uint256(1) << 192
      )
    );

    // Hacky way to do fuzzing during init, as setUp doesn't take fuzz params
    chosenTransactionFee = _chosenTransactionFee;
    chosenProtocolFee = _chosenProtocolFee;
    setUp();
    pool.initialize(strike, time.maturity, rate);
    
    TimeswapV2PoolMintParam memory param = TimeswapV2PoolMintParam({
      strike: strike,
      maturity: time.maturity,
      to: to,
      transaction: TimeswapV2PoolMint.GivenLong,
      delta: delta,
      data: ''
    });

    MintOutput memory response;
    (response.liquidityAmount, response.long0Amount, response.long1Amount, response.shortAmount, response.data) = pool
      .mint(param);

    // assertTrue(response.liquidityAmount != 0);
    delete param;

    uint256 liquidityAmount;
    uint256 shortAmount;
    (liquidityAmount, shortAmount) = ConstantProduct.calculateGivenLiquidityLong(
      pool.sqrtInterestRate(strike, time.maturity),
      delta,
      DurationCalculation.unsafeDurationFromNowToMaturity(time.maturity, uint96(block.timestamp)),
      true
    );

    assertEq(liquidityAmount, response.liquidityAmount);
    assertTrue(liquidityAmount != 0);
    assertEq(shortAmount, response.shortAmount);
    assertTrue(shortAmount != 0);
    assertLe(delta, StrikeConversion.combine(response.long0Amount, response.long1Amount, strike, false));
  }


  function testMintGivenShort(
    uint256 strike,
    address to,
    uint256 maturity,
    uint256 _chosenTransactionFee,
    uint256 _chosenProtocolFee,
    uint160 rate,
    uint256 delta
  ) public {
    vm.assume(
      maturity < type(uint96).max &&
      _chosenTransactionFee <= type(uint16).max &&
      _chosenProtocolFee <= type(uint16).max &&
      to != address(0) &&
      strike != 0 &&
      delta != 0 &&
      maturity > block.timestamp &&
      isMulDivPossible(delta, uint256(1) << 192, uint256(rate) * DurationCalculation.unsafeDurationFromNowToMaturity(maturity, uint96(block.timestamp))) &&
      FullMath.mulDiv(
        delta,
        uint256(1) << 192,
        uint256(rate) * DurationCalculation.unsafeDurationFromNowToMaturity(maturity, uint96(block.timestamp)),
        true) < type(uint160).max &&
      (uint256(FullMath.mulDiv(
        delta,
        uint256(1) << 192,
        uint256(rate) * DurationCalculation.unsafeDurationFromNowToMaturity(maturity, uint96(block.timestamp)),
        true)) << 96) > rate
      
    );

    chosenTransactionFee = _chosenTransactionFee;
    chosenProtocolFee = _chosenProtocolFee;
    setUp();
    pool.initialize(strike, maturity, rate);
    console.log(pool.sqrtInterestRate(strike, maturity));

    TimeswapV2PoolMintParam memory param = TimeswapV2PoolMintParam({
      strike: strike,
      maturity: maturity,
      to: to,
      transaction: TimeswapV2PoolMint.GivenShort,
      delta: delta,
      data: ''
    });

    MintOutput memory response;
    (response.liquidityAmount, response.long0Amount, response.long1Amount, response.shortAmount, response.data) = pool
      .mint(param);
    delete param;

    uint256 liquidityAmount;
    uint256 longAmount;
    (liquidityAmount, longAmount) = ConstantProduct.calculateGivenLiquidityShort(
      pool.sqrtInterestRate(strike, maturity),
      delta,
      DurationCalculation.unsafeDurationFromNowToMaturity(maturity, uint96(block.timestamp)),
      true
    );

    assertEq(liquidityAmount, response.liquidityAmount);
    assertEq(delta, response.shortAmount);
    assertLe(longAmount, StrikeConversion.combine(response.long0Amount, response.long1Amount, strike, false));
  }

  function testMintGivenLiquidity(
    uint256 strike,
    address to,
    uint256 maturity,
    uint256 _chosenTransactionFee,
    uint256 _chosenProtocolFee,
    uint160 rate,
    uint256 delta
  ) public {
    vm.assume(
      maturity < type(uint96).max &&
      _chosenTransactionFee <= type(uint16).max &&
      _chosenProtocolFee <= type(uint16).max &&
      to != address(0) &&
      strike != 0 &&
      delta != 0 &&
      delta < type(uint160).max &&
      maturity > block.timestamp &&
      rate > 0 &&
      (uint256(delta) << 96) > rate &&
      isMulDivPossible(delta * DurationCalculation.unsafeDurationFromNowToMaturity(maturity, uint96(block.timestamp)), rate, uint256(1) << 192)
    );

    chosenTransactionFee = _chosenTransactionFee;
    chosenProtocolFee = _chosenProtocolFee;
    setUp();
    pool.initialize(strike, maturity, rate);
    console.log(pool.sqrtInterestRate(strike, maturity));

    TimeswapV2PoolMintParam memory param = TimeswapV2PoolMintParam({
      strike: strike,
      maturity: maturity,
      to: to,
      transaction: TimeswapV2PoolMint.GivenLiquidity,
      delta: delta,
      data: ''
    });

    MintOutput memory response;
    (response.liquidityAmount, response.long0Amount, response.long1Amount, response.shortAmount, response.data) = pool
      .mint(param);
    delete param;

    assertTrue(response.liquidityAmount != 0);

    uint256 shortAmount;
    uint256 longAmount;
    (longAmount, shortAmount) = ConstantProduct.calculateGivenLiquidityDelta(
      pool.sqrtInterestRate(strike, maturity),
      SafeCast.toUint160(delta),
      DurationCalculation.unsafeDurationFromNowToMaturity(maturity, uint96(block.timestamp)),
      true
    );

    assertEq(delta, response.liquidityAmount);
    assertEq(shortAmount, response.shortAmount);
    assertLe(longAmount, StrikeConversion.combine(response.long0Amount, response.long1Amount, strike, false));
  }

struct BurnOutput {
    uint160 liquidityAmount;
    uint256 long0Amount;
    uint256 long1Amount;
    uint256 shortAmount;
    bytes data;
  }

  struct BurnToAddress {
    address to;
    address long0To;
    address long1To;
    address shortTo;
  }

  function timeswapV2PoolBurnChoiceCallback(
    TimeswapV2PoolBurnChoiceCallbackParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data) {
    long0Amount = StrikeConversion.turn(param.longAmount / 2, param.strike, false, true) - 1;
    long1Amount = StrikeConversion.turn(param.longAmount / 2, param.strike, true, true) - 1;
    if (param.strike >= type(uint128).max) {
      unchecked {
        vm.assume(
          isMulDivPossible(long1Amount, (uint256(1) << 128), param.strike) &&
            isAddable(long0Amount, StrikeConversion.convert(long1Amount, param.strike, false, false))
        );
      }
    } else {
      unchecked {
        vm.assume(
          isMulDivPossible(long0Amount, param.strike, (uint256(1) << 128)) &&
            isAddable(long1Amount, StrikeConversion.convert(long0Amount, param.strike, true, false))
        );
      }
    }
    // vm.assume(
    //   param.longAmount > StrikeConversion.combine(long0Amount, long1Amount, param.strike, false)
    //     // && param.shortAmount < StrikeConversion.combine(long0Amount, long1Amount, param.strike, false)
    // );
  }

  function timeswapV2PoolBurnCallback(
    TimeswapV2PoolBurnCallbackParam calldata param
  ) external returns (bytes memory data){
    data = "";
  }

  // NOT DONE
  struct CalculatedAmount {
    uint256 liquidityAmount;
    uint256 longAmount;
    uint256 shortAmount;
  }


  function timeswapV2PoolDeleverageChoiceCallback(
    TimeswapV2PoolDeleverageChoiceCallbackParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data) {
    long0Amount = opPair.positionOf(param.strike, param.maturity, address(this), TimeswapV2OptionPosition.Long0);
    long1Amount = opPair.positionOf(param.strike, param.maturity, address(this), TimeswapV2OptionPosition.Long1);

  }


  function timeswapV2PoolDeleverageCallback(
    TimeswapV2PoolDeleverageCallbackParam calldata param
  ) external returns (bytes memory data){
    data = "";
  }

  function testBurnCheck() public {
    chosenTransactionFee = 1;
    chosenProtocolFee = 1;
    setUp();
    uint256 strike = 1;
    uint256 maturity = 1459582642980837690266;
    uint160 rate = 520558458406151014348945;
    pool.initialize(strike, maturity, rate);

    uint256 delta = 110677585605967601658;
    uint256 burnDelta = 1257393021903808828;

    TimeswapV2PoolMintParam memory param = TimeswapV2PoolMintParam({
      strike: strike,
      maturity: maturity,
      to: address(this),
      transaction: TimeswapV2PoolMint.GivenLong,
      delta: delta,
      data: ''
    });

    MintOutput memory response;
    (response.liquidityAmount, response.long0Amount, response.long1Amount, response.shortAmount, response.data) = pool
      .mint(param);

    // assertTrue(response.liquidityAmount != 0);
    TimeswapV2PoolBurnParam memory param2 = TimeswapV2PoolBurnParam({
      strike: strike,
      maturity: maturity,
      long0To: address(this),
      long1To: address(this),
      shortTo: address(this),
      transaction: TimeswapV2PoolBurn.GivenLong,
      delta: burnDelta,
      data: ''
    });

    BurnOutput memory burnResponse;
    (
      burnResponse.liquidityAmount,
      burnResponse.long0Amount,
      burnResponse.long1Amount,
      burnResponse.shortAmount,
      burnResponse.data
    ) = pool.burn(param2);
    delete param;
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Long0));
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Long1));
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Short));
    
  }
  function testDelevCheck() public {
    chosenTransactionFee = 1;
    chosenProtocolFee = 1;
    setUp();
    uint256 strike = 1;
    uint256 maturity = 1459582642980837690266;
    uint160 rate = 520558458406151014348945;
    pool.initialize(strike, maturity, rate);

    uint256 delta = 110677585605967601658;
    uint256 burnDelta = 1257393021903808828;

    TimeswapV2PoolMintParam memory param = TimeswapV2PoolMintParam({
      strike: strike,
      maturity: maturity,
      to: address(this),
      transaction: TimeswapV2PoolMint.GivenLong,
      delta: delta,
      data: ''
    });

    MintOutput memory response;
    (response.liquidityAmount, response.long0Amount, response.long1Amount, response.shortAmount, response.data) = pool
      .mint(param);

    // assertTrue(response.liquidityAmount != 0);
    TimeswapV2PoolBurnParam memory param2 = TimeswapV2PoolBurnParam({
      strike: strike,
      maturity: maturity,
      long0To: address(this),
      long1To: address(this),
      shortTo: address(this),
      transaction: TimeswapV2PoolBurn.GivenLong,
      delta: burnDelta,
      data: ''
    });

    BurnOutput memory burnResponse;
    (
      burnResponse.liquidityAmount,
      burnResponse.long0Amount,
      burnResponse.long1Amount,
      burnResponse.shortAmount,
      burnResponse.data
    ) = pool.burn(param2);
    delete param;
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Long0));
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Long1));
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Short));

    TimeswapV2PoolDeleverageParam memory dparam = TimeswapV2PoolDeleverageParam({
      strike: strike,
      maturity: maturity,
      to: address(this),
      transaction: TimeswapV2PoolDeleverage.GivenLong,
      delta: StrikeConversion.combine(
        opPair.positionOf(strike, param.maturity, address(this), TimeswapV2OptionPosition.Long0),
        opPair.positionOf(strike, param.maturity, address(this), TimeswapV2OptionPosition.Long1),
        strike,
        true
      ),
      data: ""
    });
    vm.expectRevert(); // since the delta value will equate to 0
    pool.deleverage(dparam);
    
  }

  function testDelevCheckShort() public {
    chosenTransactionFee = 1;
    chosenProtocolFee = 1;
    setUp();
    uint256 strike = 1;
    uint256 maturity = 1459582642980837690266;
    uint160 rate = 520558458406151014348945;
    pool.initialize(strike, maturity, rate);

    uint256 delta = 110677585605967601658;
    uint256 burnDelta = 1257393021903808828;

    TimeswapV2PoolMintParam memory param = TimeswapV2PoolMintParam({
      strike: strike,
      maturity: maturity,
      to: address(this),
      transaction: TimeswapV2PoolMint.GivenLong,
      delta: delta,
      data: ''
    });

    MintOutput memory response;
    (response.liquidityAmount, response.long0Amount, response.long1Amount, response.shortAmount, response.data) = pool
      .mint(param);

    // assertTrue(response.liquidityAmount != 0);
    TimeswapV2PoolBurnParam memory param2 = TimeswapV2PoolBurnParam({
      strike: strike,
      maturity: maturity,
      long0To: address(this),
      long1To: address(this),
      shortTo: address(this),
      transaction: TimeswapV2PoolBurn.GivenLong,
      delta: burnDelta,
      data: ''
    });

    BurnOutput memory burnResponse;
    (
      burnResponse.liquidityAmount,
      burnResponse.long0Amount,
      burnResponse.long1Amount,
      burnResponse.shortAmount,
      burnResponse.data
    ) = pool.burn(param2);
    delete param;
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Long0));
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Long1));
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Short));

    TimeswapV2PoolDeleverageParam memory dparam = TimeswapV2PoolDeleverageParam({
      strike: strike,
      maturity: maturity,
      to: address(this),
      transaction: TimeswapV2PoolDeleverage.GivenLong,
      delta: opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Short),
      data: ""
    });
    vm.expectRevert(); // since the delta value will equate to 0
    pool.deleverage(dparam);
    
  }

  function testDelevCheckSum() public {
    chosenTransactionFee = 1;
    chosenProtocolFee = 1;
    setUp();
    uint256 strike = 1;
    uint256 maturity = 1459582642980837690266;
    uint160 rate = 520558458406151014348945;
    pool.initialize(strike, maturity, rate);

    uint256 delta = 110677585605967601658;
    uint256 burnDelta = 1257393021903808828;

    TimeswapV2PoolMintParam memory param = TimeswapV2PoolMintParam({
      strike: strike,
      maturity: maturity,
      to: address(this),
      transaction: TimeswapV2PoolMint.GivenLong,
      delta: delta,
      data: ''
    });

    MintOutput memory response;
    (response.liquidityAmount, response.long0Amount, response.long1Amount, response.shortAmount, response.data) = pool
      .mint(param);

    // assertTrue(response.liquidityAmount != 0);
    TimeswapV2PoolBurnParam memory param2 = TimeswapV2PoolBurnParam({
      strike: strike,
      maturity: maturity,
      long0To: address(this),
      long1To: address(this),
      shortTo: address(this),
      transaction: TimeswapV2PoolBurn.GivenLong,
      delta: burnDelta,
      data: ''
    });

    BurnOutput memory burnResponse;
    (
      burnResponse.liquidityAmount,
      burnResponse.long0Amount,
      burnResponse.long1Amount,
      burnResponse.shortAmount,
      burnResponse.data
    ) = pool.burn(param2);
    delete param;
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Long0));
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Long1));
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Short));

    TimeswapV2PoolDeleverageParam memory dparam = TimeswapV2PoolDeleverageParam({
      strike: strike,
      maturity: maturity,
      to: address(this),
      transaction: TimeswapV2PoolDeleverage.GivenSum,
      delta: 0,
      // delta: StrikeConversion.combine(
      //   opPair.positionOf(strike, param.maturity, address(this), TimeswapV2OptionPosition.Long0),
      //   opPair.positionOf(strike, param.maturity, address(this), TimeswapV2OptionPosition.Long1),
      //   strike,
      //   true
      // ),
      data: ""
    });
    vm.expectRevert(); // since the delta value will equate to 0
    pool.deleverage(dparam);
    
  }

  function testDelevCheckInterest() public {
    chosenTransactionFee = 1;
    chosenProtocolFee = 1;
    setUp();
    uint256 strike = 1;
    uint256 maturity = 1459582642980837690266;
    uint160 rate = 520558458406151014348945;
    pool.initialize(strike, maturity, rate);

    uint256 delta = 110677585605967601658;
    uint256 burnDelta = 1257393021903808828;

    TimeswapV2PoolMintParam memory param = TimeswapV2PoolMintParam({
      strike: strike,
      maturity: maturity,
      to: address(this),
      transaction: TimeswapV2PoolMint.GivenLong,
      delta: delta,
      data: ''
    });

    MintOutput memory response;
    (response.liquidityAmount, response.long0Amount, response.long1Amount, response.shortAmount, response.data) = pool
      .mint(param);

    // assertTrue(response.liquidityAmount != 0);
    TimeswapV2PoolBurnParam memory param2 = TimeswapV2PoolBurnParam({
      strike: strike,
      maturity: maturity,
      long0To: address(this),
      long1To: address(this),
      shortTo: address(this),
      transaction: TimeswapV2PoolBurn.GivenLong,
      delta: burnDelta,
      data: ''
    });

    BurnOutput memory burnResponse;
    (
      burnResponse.liquidityAmount,
      burnResponse.long0Amount,
      burnResponse.long1Amount,
      burnResponse.shortAmount,
      burnResponse.data
    ) = pool.burn(param2);
    delete param;
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Long0));
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Long1));
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Short));

    TimeswapV2PoolDeleverageParam memory dparam = TimeswapV2PoolDeleverageParam({
      strike: strike,
      maturity: maturity,
      to: address(this),
      transaction: TimeswapV2PoolDeleverage.GivenDeltaSqrtInterestRate,
      delta: 0,
      // delta: StrikeConversion.combine(
      //   opPair.positionOf(strike, param.maturity, address(this), TimeswapV2OptionPosition.Long0),
      //   opPair.positionOf(strike, param.maturity, address(this), TimeswapV2OptionPosition.Long1),
      //   strike,
      //   true
      // ),
      data: ""
    });
    vm.expectRevert(); // since the delta value will equate to 0
    pool.deleverage(dparam);
    
  }

  function testLevCheck() public {
    chosenTransactionFee = 1;
    chosenProtocolFee = 1;
    setUp();
    uint256 strike = 1;
    uint256 maturity = 1459582642980837690266;
    uint160 rate = 520558458406151014348945;
    pool.initialize(strike, maturity, rate);

    uint256 delta = 110677585605967601658;
    uint256 burnDelta = 1257393021903808828;

    TimeswapV2PoolMintParam memory param = TimeswapV2PoolMintParam({
      strike: strike,
      maturity: maturity,
      to: address(this),
      transaction: TimeswapV2PoolMint.GivenLong,
      delta: delta,
      data: ''
    });

    MintOutput memory response;
    (response.liquidityAmount, response.long0Amount, response.long1Amount, response.shortAmount, response.data) = pool
      .mint(param);

    // assertTrue(response.liquidityAmount != 0);
    TimeswapV2PoolBurnParam memory param2 = TimeswapV2PoolBurnParam({
      strike: strike,
      maturity: maturity,
      long0To: address(this),
      long1To: address(this),
      shortTo: address(this),
      transaction: TimeswapV2PoolBurn.GivenLong,
      delta: burnDelta,
      data: ''
    });

    BurnOutput memory burnResponse;
    (
      burnResponse.liquidityAmount,
      burnResponse.long0Amount,
      burnResponse.long1Amount,
      burnResponse.shortAmount,
      burnResponse.data
    ) = pool.burn(param2);
    delete param;
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Long0));
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Long1));
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Short));

    TimeswapV2PoolLeverageParam memory lparam = TimeswapV2PoolLeverageParam({
      strike: strike,
      maturity: maturity,
      long0To: address(this),
      long1To: address(this),
      transaction: TimeswapV2PoolLeverage.GivenLong,
      delta: StrikeConversion.combine(
        opPair.positionOf(strike, param.maturity, address(this), TimeswapV2OptionPosition.Long0),
        opPair.positionOf(strike, param.maturity, address(this), TimeswapV2OptionPosition.Long1),
        strike,
        true
      ),
      data: ""
    });
    vm.expectRevert(); // since the delta value will equate to 0
    pool.leverage(lparam);
    
  }

  function testLevCheckShort() public {
    chosenTransactionFee = 1;
    chosenProtocolFee = 1;
    setUp();
    uint256 strike = 1;
    uint256 maturity = 1459582642980837690266;
    uint160 rate = 520558458406151014348945;
    pool.initialize(strike, maturity, rate);

    uint256 delta = 110677585605967601658;
    uint256 burnDelta = 1257393021903808828;

    TimeswapV2PoolMintParam memory param = TimeswapV2PoolMintParam({
      strike: strike,
      maturity: maturity,
      to: address(this),
      transaction: TimeswapV2PoolMint.GivenLong,
      delta: delta,
      data: ''
    });

    MintOutput memory response;
    (response.liquidityAmount, response.long0Amount, response.long1Amount, response.shortAmount, response.data) = pool
      .mint(param);

    // assertTrue(response.liquidityAmount != 0);
    TimeswapV2PoolBurnParam memory param2 = TimeswapV2PoolBurnParam({
      strike: strike,
      maturity: maturity,
      long0To: address(this),
      long1To: address(this),
      shortTo: address(this),
      transaction: TimeswapV2PoolBurn.GivenLong,
      delta: burnDelta,
      data: ''
    });

    BurnOutput memory burnResponse;
    (
      burnResponse.liquidityAmount,
      burnResponse.long0Amount,
      burnResponse.long1Amount,
      burnResponse.shortAmount,
      burnResponse.data
    ) = pool.burn(param2);
    delete param;
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Long0));
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Long1));
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Short));

    TimeswapV2PoolLeverageParam memory lparam = TimeswapV2PoolLeverageParam({
      strike: strike,
      maturity: maturity,
      long0To: address(this),
      long1To: address(this),
      transaction: TimeswapV2PoolLeverage.GivenShort,
      delta: opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Short),
      data: ""
    });
    vm.expectRevert(); // since the delta value will equate to 0
    pool.leverage(lparam);
    
  }

  function testLevCheckSum() public {
    chosenTransactionFee = 1;
    chosenProtocolFee = 1;
    setUp();
    uint256 strike = 1;
    uint256 maturity = 1459582642980837690266;
    uint160 rate = 520558458406151014348945;
    pool.initialize(strike, maturity, rate);

    uint256 delta = 110677585605967601658;
    uint256 burnDelta = 1257393021903808828;

    TimeswapV2PoolMintParam memory param = TimeswapV2PoolMintParam({
      strike: strike,
      maturity: maturity,
      to: address(this),
      transaction: TimeswapV2PoolMint.GivenLong,
      delta: delta,
      data: ''
    });

    MintOutput memory response;
    (response.liquidityAmount, response.long0Amount, response.long1Amount, response.shortAmount, response.data) = pool
      .mint(param);

    // assertTrue(response.liquidityAmount != 0);
    TimeswapV2PoolBurnParam memory param2 = TimeswapV2PoolBurnParam({
      strike: strike,
      maturity: maturity,
      long0To: address(this),
      long1To: address(this),
      shortTo: address(this),
      transaction: TimeswapV2PoolBurn.GivenLong,
      delta: burnDelta,
      data: ''
    });

    BurnOutput memory burnResponse;
    (
      burnResponse.liquidityAmount,
      burnResponse.long0Amount,
      burnResponse.long1Amount,
      burnResponse.shortAmount,
      burnResponse.data
    ) = pool.burn(param2);
    delete param;
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Long0));
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Long1));
    console.log(opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Short));

    TimeswapV2PoolLeverageParam memory lparam = TimeswapV2PoolLeverageParam({
      strike: strike,
      maturity: maturity,
      long0To: address(this),
      long1To: address(this),
      transaction: TimeswapV2PoolLeverage.GivenSum,
      delta: opPair.positionOf(strike, maturity, address(this), TimeswapV2OptionPosition.Short),
      data: ""
    });
    vm.expectRevert(); // since the delta value will equate to 0
    pool.leverage(lparam);
    
  }
}