// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import 'forge-std/src/Test.sol';
import 'forge-std/src/console.sol';
import '../../contracts/TimeswapV2PoolFactory.sol';
import '../../contracts/interfaces/ITimeswapV2Pool.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@timeswap-labs/v2-option/contracts/TimeswapV2OptionFactory.sol';
import '@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2Option.sol';
import {TimeswapV2PoolMint, TimeswapV2PoolBurn, TimeswapV2PoolDeleverage, TimeswapV2PoolLeverage, TimeswapV2PoolRebalance, TransactionLibrary} from '../../contracts/enums/Transaction.sol';
import {TimeswapV2PoolCollectParam, TimeswapV2PoolMintParam, TimeswapV2PoolBurnParam, TimeswapV2PoolDeleverageParam, TimeswapV2PoolLeverageParam, TimeswapV2PoolRebalanceParam} from '../../contracts/structs/Param.sol';
import {TimeswapV2PoolMintChoiceCallbackParam, TimeswapV2PoolMintCallbackParam} from '../../contracts/structs/CallbackParam.sol';
import {StrikeConversion} from '@timeswap-labs/v2-library/contracts/StrikeConversion.sol';
import {TimeswapV2OptionMintParam} from '@timeswap-labs/v2-option/contracts/structs/Param.sol';
import {TimeswapV2OptionMintCallbackParam, TimeswapV2OptionSwapCallbackParam} from '@timeswap-labs/v2-option/contracts/structs/CallbackParam.sol';
import {TimeswapV2OptionMint} from '@timeswap-labs/v2-option/contracts/enums/Transaction.sol';
import {ConstantProduct} from '../../contracts/libraries/ConstantProduct.sol';
import {DurationCalculation} from '../../contracts/libraries/DurationCalculation.sol';
import {SafeCast} from '@timeswap-labs/v2-library/contracts/SafeCast.sol';

import {TimeswapV2PoolBurnChoiceCallbackParam} from '../../contracts/structs/CallbackParam.sol';

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

  struct MintOutput {
    uint160 liquidityAmount;
    uint256 long0Amount;
    uint256 long1Amount;
    uint256 shortAmount;
    bytes data;
  }

  struct CalculatedAmount {
    uint256 liquidityAmount;
    uint256 longAmount;
    uint256 shortAmount;
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

  function testMintGivenLong(
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
        rate > 0
    );
    unchecked {
      vm.assume(
        (rate * delta) > rate &&
          (rate * delta) > delta &&
          (rate * delta) > type(uint96).max &&
          (rate * delta) < type(uint160).max
      );
      // vm.assume((rate * delta) < type(uint160).max);
    }

    // Hacky way to do fuzzing during init, as setUp doesn't take fuzz params
    chosenTransactionFee = _chosenTransactionFee;
    chosenProtocolFee = _chosenProtocolFee;
    setUp();
    pool.initialize(strike, maturity, rate);

    TimeswapV2PoolMintParam memory param = TimeswapV2PoolMintParam({
      strike: strike,
      maturity: maturity,
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
      pool.sqrtInterestRate(strike, maturity),
      delta,
      DurationCalculation.unsafeDurationFromNowToMaturity(maturity, uint96(block.timestamp)),
      true
    );

    assertEq(liquidityAmount, response.liquidityAmount);
    assertEq(shortAmount, response.shortAmount);
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
        maturity > block.timestamp
    );
    unchecked {
      vm.assume(
        ((uint256(1) << 192) * delta) > (uint256(1) << 192) &&
          ((uint256(1) << 192) * delta) > delta &&
          ((uint256(1) << 192) * delta) >
          (rate * DurationCalculation.unsafeDurationFromNowToMaturity(maturity, uint96(block.timestamp))) &&
          ((uint256(1) << 192) * delta) < type(uint160).max
      );
      // vm.assume((rate * delta) < type(uint160).max);
    }

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
        maturity > block.timestamp &&
        rate > 0
    );

    unchecked {
      vm.assume(
        (rate * delta) > rate &&
          (rate * delta) > delta &&
          (rate * delta) > type(uint96).max &&
          (rate * delta) < type(uint160).max
      );
      // vm.assume((rate * delta) < type(uint160).max);
    }
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

  function testMintGivenLarger(
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
        rate > 0
    );

    unchecked {
      vm.assume(
        (rate * delta) > rate &&
          (rate * delta) > delta &&
          (rate * delta) > type(uint96).max &&
          (rate * delta) < type(uint160).max
      );
      // vm.assume((rate * delta) < type(uint160).max);
    }
    chosenTransactionFee = _chosenTransactionFee;
    chosenProtocolFee = _chosenProtocolFee;
    setUp();
    pool.initialize(strike, maturity, rate);
    console.log(pool.sqrtInterestRate(strike, maturity));

    TimeswapV2PoolMintParam memory param = TimeswapV2PoolMintParam({
      strike: strike,
      maturity: maturity,
      to: to,
      transaction: TimeswapV2PoolMint.GivenLarger,
      delta: delta,
      data: ''
    });

    MintOutput memory response;
    (response.liquidityAmount, response.long0Amount, response.long1Amount, response.shortAmount, response.data) = pool
      .mint(param);

    CalculatedAmount memory calc;
    (calc.liquidityAmount, calc.longAmount, calc.shortAmount) = ConstantProduct.calculateGivenLiquidityLargerOrSmaller(
      pool.sqrtInterestRate(strike, maturity),
      delta,
      DurationCalculation.unsafeDurationFromNowToMaturity(maturity, uint96(block.timestamp)),
      true
    );

    assertEq(calc.liquidityAmount, response.liquidityAmount);
    assertEq(calc.shortAmount, response.shortAmount);
    assertLe(calc.longAmount, StrikeConversion.combine(response.long0Amount, response.long1Amount, strike, false));
  }

  // Burn starts here
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
    // long0Amount = StrikeConversion.turn(param.longAmount/2, param.strike, false, false);
    // long1Amount = StrikeConversion.turn(param.longAmount/2, param.strike, true, false);

    vm.assume(param.longAmount < (1 << 127));
    long0Amount = StrikeConversion.turn(param.longAmount / 2, param.strike, false, true);
    long1Amount = StrikeConversion.turn(param.longAmount / 2, param.strike, true, true);
    vm.assume(param.longAmount > StrikeConversion.combine(long0Amount, long1Amount, param.strike, false));
  }

  function testBurnGivenLong(
    uint256 strike,
    BurnToAddress memory burnToAddress,
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
        burnToAddress.long0To != address(0) &&
        burnToAddress.long1To != address(0) &&
        burnToAddress.shortTo != address(0) &&
        strike != 0 &&
        delta != 0 &&
        maturity > block.timestamp &&
        rate > 0
    );
    unchecked {
      vm.assume(
        (rate * delta) > rate &&
          (rate * delta) > delta &&
          (rate * delta) > type(uint96).max &&
          (rate * delta) < type(uint160).max
      );
      // vm.assume((rate * delta) < type(uint160).max);
    }

    // Hacky way to do fuzzing during init, as setUp doesn't take fuzz params
    chosenTransactionFee = _chosenTransactionFee;
    chosenProtocolFee = _chosenProtocolFee;
    setUp();
    pool.initialize(strike, maturity, rate);
    console.log(burnToAddress.long0To);

    TimeswapV2PoolMintParam memory param = TimeswapV2PoolMintParam({
      strike: strike,
      maturity: maturity,
      to: address(this),
      transaction: TimeswapV2PoolMint.GivenLong,
      delta: delta,
      data: ''
    });

    MintOutput memory mintResponse;
    (
      mintResponse.liquidityAmount,
      mintResponse.long0Amount,
      mintResponse.long1Amount,
      mintResponse.shortAmount,
      mintResponse.data
    ) = pool.mint(param);
    delete param;

    console.log(mintResponse.liquidityAmount, 'liquidityAmount');
    console.log(mintResponse.long0Amount, 'long0Amount');
    console.log(mintResponse.long1Amount, 'long1Amount');
    console.log(mintResponse.shortAmount, 'shortAmount');

    TimeswapV2PoolBurnParam memory param2 = TimeswapV2PoolBurnParam({
      strike: strike,
      maturity: maturity,
      long0To: burnToAddress.long0To,
      long1To: burnToAddress.long1To,
      shortTo: burnToAddress.shortTo,
      transaction: TimeswapV2PoolBurn.GivenLong,
      delta: delta,
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

    assertGe(mintResponse.liquidityAmount, burnResponse.liquidityAmount);

    CalculatedAmount memory calc;
    (calc.liquidityAmount, calc.shortAmount) = ConstantProduct.calculateGivenLiquidityLong(
      pool.sqrtInterestRate(strike, maturity),
      delta,
      DurationCalculation.unsafeDurationFromNowToMaturity(maturity, uint96(block.timestamp)),
      true
    );

    assertEq(calc.liquidityAmount, burnResponse.liquidityAmount);
    assertEq(calc.shortAmount, burnResponse.shortAmount);
    // assertLe(delta, StrikeConversion.combine(burnResponse.long0Amount, burnResponse.long1Amount, strike, false));
  }
}
