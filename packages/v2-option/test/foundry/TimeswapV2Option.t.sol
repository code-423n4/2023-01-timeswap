// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import 'forge-std/src/Test.sol';
import 'forge-std/src/console.sol';
import '../../contracts/TimeswapV2OptionFactory.sol';
import '../../contracts/TimeswapV2Option.sol';
import '../../contracts/interfaces/ITimeswapV2Option.sol';
import {TimeswapV2OptionPosition} from '../../contracts/enums/Position.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {TimeswapV2OptionMintParam, TimeswapV2OptionBurnParam, TimeswapV2OptionSwapParam, TimeswapV2OptionCollectParam, ParamLibrary} from '../../contracts/structs/Param.sol';
import {TimeswapV2OptionMint, TimeswapV2OptionBurn, TimeswapV2OptionSwap, TimeswapV2OptionCollect, TransactionLibrary} from '../../contracts/enums/Transaction.sol';
import {StrikeConversion} from '@timeswap-labs/v2-library/contracts/StrikeConversion.sol';
import {Math} from '@timeswap-labs/v2-library/contracts/Math.sol';
import {FullMath} from '@timeswap-labs/v2-library/contracts/FullMath.sol';

import {Proportion} from '../../contracts/libraries/Proportion.sol';

contract HelperERC20 is ERC20 {
  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
    _mint(msg.sender, type(uint256).max);
  }
}

contract TimeswapV2OptionTest is Test {
  TimeswapV2OptionFactory factory;
  ITimeswapV2Option opPair;
  HelperERC20 token0;
  HelperERC20 token1;

  event Mint(
    uint256 strike,
    uint256 maturity,
    address caller,
    address long0To,
    address long1To,
    address shortTo,
    uint256 token0AndLong0Amount,
    uint256 token1AndLong1Amount,
    uint256 shortAmount
  );

  event Burn(
    uint256 strike,
    uint256 maturity,
    address caller,
    address token0To,
    address token1To,
    uint256 token0AndLong0Amount,
    uint256 token1AndLong1Amount,
    uint256 shortAmount
  );

  function setUp() public {
    factory = new TimeswapV2OptionFactory();
    token0 = new HelperERC20('Token A', 'A');
    token1 = new HelperERC20('Token B', 'B');
    if (address(token1) < address(token0)) {
      (token0, token1) = (token1, token0);
    }
    opPair = ITimeswapV2Option(factory.create(address(token0), address(token1)));
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

  // testFailBlockstamp
  // testTransferPosition

  struct MintData {
    uint256 token0;
    uint256 token1;
    uint256 short;
    uint256 strike;
    uint256 maturity;
    bytes data;
  }

  struct BurnData {
    uint256 token0AndLong0Amount;
    uint256 token1AndLong1Amount;
    uint256 shortAmount;
  }

  struct CollectData {
    uint256 token0;
    uint256 token1;
    uint256 short;
  }

  struct UINT512 {
    uint256 num0;
    uint256 num1;
  }

  function isAddable(uint256 num1, uint256 num2) internal returns (bool) {
    return (num1 < type(uint256).max - num2);
  }

  function isMulDivPossible(uint256 multiplicand, uint256 multiplier, uint256 divisor) internal returns (bool) {
    (uint256 product0, uint256 product1) = FullMath.mul512(multiplicand, multiplier);
    if (divisor <= product1 || (product1 == 0 && product0 < divisor)) {
      return false;
    }
    return true;
  }

  function assertOutputAndPositionsLong0(
    uint256 expectedAmount,
    uint256 outputAmount,
    uint256 maturity,
    address userAddress,
    uint256 strike
  ) internal {
    uint256 long0Position = opPair.positionOf(strike, maturity, userAddress, TimeswapV2OptionPosition.Long0);
    assertEq(expectedAmount, long0Position);
    assertEq(expectedAmount, outputAmount);
  }

  function assertOutputAndPositionsLong1(
    uint256 expectedAmount,
    uint256 outputAmount,
    uint256 maturity,
    address userAddress,
    uint256 strike
  ) internal {
    uint256 long1Position = opPair.positionOf(strike, maturity, userAddress, TimeswapV2OptionPosition.Long1);
    assertEq(expectedAmount, long1Position);
    assertEq(expectedAmount, outputAmount);
  }

  function assertOutputAndPositionsShort(
    uint256 expectedAmount,
    uint256 outputAmount,
    uint256 maturity,
    address userAddress,
    uint256 strike
  ) internal {
    uint256 shortPosition = opPair.positionOf(strike, maturity, userAddress, TimeswapV2OptionPosition.Short);
    assertEq(expectedAmount, shortPosition);
    assertEq(expectedAmount, outputAmount);
  }

  function testMintGivenTokensAndLongs(
    uint256 strike,
    address long0To,
    address long1To,
    address shortTo,
    uint256 amount0,
    uint256 amount1,
    // uint256 maturity,TODO: Parameterize this as well
    bytes memory data
  ) public {
    vm.assume(
      long0To != address(0) &&
        long1To != address(0) &&
        shortTo != address(0) &&
        amount0 != 0 &&
        amount1 != 0 &&
        strike != 0
      // && strike > (1 << 128)
      // amount0 < (1 << 128) && amount1 < (1 << 128)
    );

    // if(strike >= (1 << 128)){
    if (strike >= type(uint128).max) {
      unchecked {
        vm.assume(
          isMulDivPossible(amount1, (uint256(1) << 128), strike) &&
            isAddable(amount0, StrikeConversion.convert(amount1, strike, false, false))
        );
      }
    } else {
      unchecked {
        vm.assume(
          isMulDivPossible(amount0, strike, (uint256(1) << 128)) &&
            isAddable(amount1, StrikeConversion.convert(amount0, strike, true, false))
        );
      }
    }

    uint256 maturity = block.timestamp + 100;

    TimeswapV2OptionMintParam memory param = TimeswapV2OptionMintParam({
      strike: strike,
      long0To: long0To,
      maturity: maturity,
      long1To: long1To,
      shortTo: shortTo,
      transaction: TimeswapV2OptionMint.GivenTokensAndLongs,
      amount0: amount0,
      amount1: amount1,
      data: data
    });
    MintData memory res = MintData(0, 0, 0, strike, maturity, bytes(''));
    (res.token0, res.token1, res.short, ) = opPair.mint(param);

    assertOutputAndPositionsLong0(amount0, res.token0, res.maturity, long0To, res.strike);
    assertOutputAndPositionsLong1(amount1, res.token1, res.maturity, long1To, res.strike);
    assertOutputAndPositionsShort(
      StrikeConversion.combine(amount0, amount1, res.strike, false),
      res.short,
      res.maturity,
      shortTo,
      res.strike
    );
  }

  function testMintGivenShorts(
    uint256 strike,
    address long0To,
    address long1To,
    address shortTo,
    uint256 amount0,
    uint256 amount1,
    // uint256 maturity,
    bytes memory data
  ) public {
    vm.assume(
      long0To != address(0) &&
        long1To != address(0) &&
        shortTo != address(0) &&
        amount0 != 0 &&
        amount1 != 0 &&
        strike != 0
      // && strike >= type(uint128).max
    );

    if (strike >= type(uint128).max) {
      unchecked {
        vm.assume(
          // isAddable(amount0, amount1) &&
          amount0 + amount1 > amount0 && amount0 + amount1 > amount1 && isMulDivPossible(amount1, strike, (1 << 128))
        );
      }
    } else {
      unchecked {
        vm.assume(
          // isAddable(amount0, amount1) &&
          amount0 + amount1 > amount0 && amount0 + amount1 > amount1 && isMulDivPossible(amount0, (1 << 128), strike)
        );
      }
    }

    uint256 maturity = block.timestamp + 100;

    TimeswapV2OptionMintParam memory param = TimeswapV2OptionMintParam({
      strike: strike,
      long0To: long0To,
      maturity: block.timestamp + 100,
      long1To: long1To,
      shortTo: shortTo,
      transaction: TimeswapV2OptionMint.GivenShorts,
      amount0: amount0,
      amount1: amount1,
      data: data
    });
    MintData memory res = MintData(0, 0, 0, strike, maturity, bytes(''));

    (res.token0, res.token1, res.short, ) = opPair.mint(param);

    assertOutputAndPositionsLong0(
      StrikeConversion.turn(amount0, strike, false, true),
      res.token0,
      res.maturity,
      long0To,
      res.strike
    );
    assertOutputAndPositionsLong1(
      StrikeConversion.turn(amount1, strike, true, true),
      res.token1,
      res.maturity,
      long1To,
      res.strike
    );
    assertOutputAndPositionsShort(amount0 + amount1, res.short, res.maturity, shortTo, res.strike);
  }

  function testSwapGivenToken0(
    uint256 amount0,
    uint256 strike,
    bool isLong0ToLong1,
    // TimeswapV2OptionSwap transaction,
    address longTo
  ) public {
    vm.assume(
      amount0 > 0 &&
        // amount1 > 0 &&
        isMulDivPossible(amount0, strike, (1 << 128)) &&
        strike > 0 &&
        longTo != address(0)
    );

    // muldivoverflow
    uint256 amount1 = StrikeConversion.convert(amount0, strike, true, isLong0ToLong1);

    // vm.assume(amount1 > 0);

    TimeswapV2OptionMintParam memory param = TimeswapV2OptionMintParam({
      strike: strike,
      long0To: address(this),
      maturity: block.timestamp + 100,
      long1To: address(this),
      shortTo: address(this),
      transaction: TimeswapV2OptionMint.GivenTokensAndLongs,
      amount0: isLong0ToLong1 ? amount0 : 0,
      amount1: isLong0ToLong1 ? 0 : amount1,
      data: ''
    });

    opPair.mint(param);
    delete param;

    TimeswapV2OptionSwapParam memory sparam = TimeswapV2OptionSwapParam({
      strike: strike,
      maturity: block.timestamp + 100,
      longTo: longTo,
      tokenTo: longTo,
      isLong0ToLong1: isLong0ToLong1,
      // transaction: transaction,
      transaction: TimeswapV2OptionSwap.GivenToken0AndLong0,
      // amount: (transaction == TimeswapV2OptionSwap.GivenToken0AndLong0) ? amount0 : amount1,
      amount: amount0,
      data: ''
    });

    console.log(amount0, amount1);
    console.log(
      opPair.positionOf(strike, block.timestamp + 100, address(this), TimeswapV2OptionPosition.Long0),
      opPair.positionOf(strike, block.timestamp + 100, address(this), TimeswapV2OptionPosition.Long1)
    );

    uint256 expectedAmount0;
    uint256 expectedAmount1;
    (expectedAmount0, expectedAmount1, ) = opPair.swap(sparam);
    delete sparam;
    assertEq(amount0, expectedAmount0);
    assertEq(amount1, expectedAmount1);

    if (isLong0ToLong1) {
      assertEq(token0.balanceOf(longTo), amount0);
    } else {
      assertEq(token1.balanceOf(longTo), amount1);
    }
  }

  function testSwapGivenToken1(
    uint256 amount1,
    uint256 strike,
    bool isLong0ToLong1,
    // TimeswapV2OptionSwap transaction,
    address longTo
  ) public {
    // vm.assume(amount1 > 0 && strike > (1 << 128) && longTo != address(0));
    vm.assume(
      amount1 > 0 &&
        // amount1 < (1 << 128) &&
        // strike > (1 << 128) &&
        strike > 0 &&
        isMulDivPossible(amount1, (uint256(1) << 128), strike) &&
        longTo != address(0)
    );

    uint256 amount0 = StrikeConversion.convert(amount1, strike, false, !isLong0ToLong1);
    vm.assume(amount0 > 0);
    console.log(amount0, amount1);

    TimeswapV2OptionMintParam memory param = TimeswapV2OptionMintParam({
      strike: strike,
      long0To: address(this),
      maturity: block.timestamp + 100,
      long1To: address(this),
      shortTo: address(this),
      transaction: TimeswapV2OptionMint.GivenTokensAndLongs,
      amount0: isLong0ToLong1 ? amount0 : 0,
      amount1: isLong0ToLong1 ? 0 : amount1,
      data: ''
    });

    opPair.mint(param);
    // too fix stack too deep error
    console.log(
      opPair.positionOf(strike, block.timestamp + 100, address(this), TimeswapV2OptionPosition.Long0),
      opPair.positionOf(strike, block.timestamp + 100, address(this), TimeswapV2OptionPosition.Long1)
    );

    console.log(
      opPair.totalPosition(strike, block.timestamp + 100, TimeswapV2OptionPosition.Long0),
      opPair.totalPosition(strike, block.timestamp + 100, TimeswapV2OptionPosition.Long1)
    );
    delete param;

    TimeswapV2OptionSwapParam memory sparam = TimeswapV2OptionSwapParam({
      strike: strike,
      maturity: block.timestamp + 100,
      longTo: longTo,
      tokenTo: longTo,
      isLong0ToLong1: isLong0ToLong1,
      // transaction: transaction,
      transaction: TimeswapV2OptionSwap.GivenToken1AndLong1,
      // amount: (transaction == TimeswapV2OptionSwap.GivenToken0AndLong0) ? amount0 : amount1,
      amount: amount1,
      data: ''
    });

    uint256 expectedAmount0;
    uint256 expectedAmount1;
    (expectedAmount0, expectedAmount1, ) = opPair.swap(sparam);
    delete sparam;

    //TODO: verify logic for >=
    assertGe(amount0, expectedAmount0);
    assertGe(amount1, expectedAmount1);

    if (isLong0ToLong1) {
      assertEq(token0.balanceOf(longTo), expectedAmount0);
    } else {
      assertEq(token1.balanceOf(longTo), expectedAmount1);
    }
  }

  function assertCollectedToken0Value(uint256 actual, uint256 expected, address owner) internal {
    assertEq(actual, expected);
    assertEq(actual, token0.balanceOf(owner));
  }

  function assertCollectedToken1Value(uint256 actual, uint256 expected, address owner) internal {
    assertEq(actual, expected);
    assertEq(actual, token1.balanceOf(owner));
  }

  function testCollectGivenShort(
    uint256 amount,
    uint256 amount0,
    uint256 amount1,
    address token0To,
    address token1To,
    uint256 strike
  ) public {
    vm.assume(
      strike > 0 && token0To != address(0) && token1To != address(0) && amount1 > 0 && amount0 > 0 && amount > 0
    );

    if (strike >= type(uint128).max) {
      unchecked {
        vm.assume(
          isMulDivPossible(amount1, (uint256(1) << 128), strike) &&
            isAddable(amount0, StrikeConversion.convert(amount1, strike, false, false))
        );
      }
    } else {
      unchecked {
        vm.assume(
          isMulDivPossible(amount0, strike, (uint256(1) << 128)) &&
            isAddable(amount1, StrikeConversion.convert(amount0, strike, true, false))
        );
      }
    }
    //vm.assume(amount0 < (1 << 128) && amount1 < (1 << 128));

    // uint256 maturity = block.timestamp + 100;

    TimeswapV2OptionMintParam memory param = TimeswapV2OptionMintParam({
      strike: strike,
      long0To: address(this),
      maturity: block.timestamp + 100,
      long1To: address(this),
      shortTo: address(this),
      transaction: TimeswapV2OptionMint.GivenTokensAndLongs,
      amount0: amount0,
      amount1: amount1,
      data: ''
    });

    opPair.mint(param);
    delete param;

    TimeswapV2OptionCollectParam memory cparam = TimeswapV2OptionCollectParam({
      strike: strike,
      maturity: block.timestamp + 100,
      token0To: token0To,
      token1To: token1To,
      transaction: TimeswapV2OptionCollect.GivenShort,
      amount: amount
    });

    uint256 totalLong0 = opPair.totalPosition(strike, block.timestamp + 100, TimeswapV2OptionPosition.Long0);
    uint256 totalLong1 = opPair.totalPosition(strike, block.timestamp + 100, TimeswapV2OptionPosition.Long1);

    if (strike > (uint256(1) << 128)) {
      vm.assume(isMulDivPossible(totalLong1, (uint256(1) << 128), strike));
    } else {
      vm.assume(isMulDivPossible(totalLong0, strike, (uint256(1) << 128)));
    }

    vm.assume(amount < opPair.positionOf(strike, block.timestamp + 100, address(this), TimeswapV2OptionPosition.Short));

    vm.warp(block.timestamp + 101);

    uint256 denominator = StrikeConversion.combine(totalLong0, totalLong1, strike, true);
    uint256 token0Amount = Proportion.proportion(amount, totalLong0, denominator, false);
    uint256 token1Amount = Proportion.proportion(amount, totalLong1, denominator, false);

    vm.assume(isMulDivPossible(amount, totalLong0, denominator) && isMulDivPossible(amount, totalLong1, denominator));

    CollectData memory output;
    (output.token0, output.token1, output.short) = opPair.collect(cparam);
    delete cparam;
    delete strike;
    assertEq(output.short, amount);
    assertCollectedToken0Value(token0Amount, output.token0, token0To);
    assertCollectedToken1Value(token1Amount, output.token1, token1To);
  }

  function testCollectGivenToken0(
    uint256 amount,
    uint256 amount0,
    uint256 amount1,
    address token0To,
    address token1To,
    uint256 strike
  ) public {
    vm.assume(
      strike > 0 &&
        token0To != address(0) &&
        token1To != address(0) &&
        amount1 > 0 &&
        amount0 > 0 &&
        amount > 0 &&
        amount < amount0
    );
    if (strike >= type(uint128).max) {
      unchecked {
        vm.assume(
          isMulDivPossible(amount1, (uint256(1) << 128), strike) &&
            isAddable(amount0, StrikeConversion.convert(amount1, strike, false, false))
        );
      }
    } else {
      unchecked {
        vm.assume(
          isMulDivPossible(amount0, strike, (uint256(1) << 128)) &&
            isAddable(amount1, StrikeConversion.convert(amount0, strike, true, false))
        );
      }
    }
    // vm.assume(amount0 < (1 << 128) && amount1 < (1 << 128));

    // uint256 maturity = block.timestamp + 100;

    TimeswapV2OptionMintParam memory param = TimeswapV2OptionMintParam({
      strike: strike,
      long0To: address(this),
      maturity: block.timestamp + 100,
      long1To: address(this),
      shortTo: address(this),
      transaction: TimeswapV2OptionMint.GivenTokensAndLongs,
      amount0: amount0,
      amount1: amount1,
      data: ''
    });

    opPair.mint(param);
    delete param;

    TimeswapV2OptionCollectParam memory cparam = TimeswapV2OptionCollectParam({
      strike: strike,
      maturity: block.timestamp + 100,
      token0To: token0To,
      token1To: token1To,
      transaction: TimeswapV2OptionCollect.GivenToken0,
      //amount: amount0
      amount: amount
    });

    uint256 totalLong0 = opPair.totalPosition(strike, block.timestamp + 100, TimeswapV2OptionPosition.Long0);
    uint256 totalLong1 = opPair.totalPosition(strike, block.timestamp + 100, TimeswapV2OptionPosition.Long1);
    if (strike > (uint256(1) << 128)) {
      vm.assume(isMulDivPossible(totalLong1, (uint256(1) << 128), strike));
    } else {
      vm.assume(isMulDivPossible(totalLong0, strike, (uint256(1) << 128)));
    }

    uint256 denominator = StrikeConversion.combine(totalLong0, totalLong1, strike, true);
    vm.assume(isMulDivPossible(amount, denominator, totalLong0));
    uint256 shortAmount = Proportion.proportion(amount, denominator, totalLong0, true);
    vm.assume(
      shortAmount <= opPair.positionOf(strike, block.timestamp + 100, address(this), TimeswapV2OptionPosition.Short) &&
        isMulDivPossible(shortAmount, totalLong1, denominator)
    );
    uint256 token1Amount = Proportion.proportion(shortAmount, totalLong1, denominator, false);
    vm.warp(block.timestamp + 101);

    CollectData memory output;
    (output.token0, output.token1, output.short) = opPair.collect(cparam);
    delete cparam;
    delete strike;
    assertEq(output.short, shortAmount);
    assertCollectedToken0Value(amount, output.token0, token0To);
    assertCollectedToken1Value(token1Amount, output.token1, token1To);
  }

  function testCollectGivenToken1(
    uint256 amount,
    uint256 amount0,
    uint256 amount1,
    address token0To,
    address token1To,
    uint256 strike
  ) public {
    vm.assume(
      strike > 0 &&
        token0To != address(0) &&
        token1To != address(0) &&
        amount1 > 0 &&
        amount0 > 0 &&
        amount > 0 &&
        amount < amount1
    );

    if (strike >= type(uint128).max) {
      unchecked {
        vm.assume(
          isMulDivPossible(amount1, (uint256(1) << 128), strike) &&
            isAddable(amount0, StrikeConversion.convert(amount1, strike, false, false))
        );
      }
    } else {
      unchecked {
        vm.assume(
          isMulDivPossible(amount0, strike, (uint256(1) << 128)) &&
            isAddable(amount1, StrikeConversion.convert(amount0, strike, true, false))
        );
      }
    }

    // uint256 maturity = block.timestamp + 100;

    TimeswapV2OptionMintParam memory param = TimeswapV2OptionMintParam({
      strike: strike,
      long0To: address(this),
      maturity: block.timestamp + 100,
      long1To: address(this),
      shortTo: address(this),
      transaction: TimeswapV2OptionMint.GivenTokensAndLongs,
      amount0: amount0,
      amount1: amount1,
      data: ''
    });

    opPair.mint(param);
    delete param;

    TimeswapV2OptionCollectParam memory cparam = TimeswapV2OptionCollectParam({
      strike: strike,
      maturity: block.timestamp + 100,
      token0To: token0To,
      token1To: token1To,
      transaction: TimeswapV2OptionCollect.GivenToken1,
      amount: amount
    });

    uint256 totalLong0 = opPair.totalPosition(strike, block.timestamp + 100, TimeswapV2OptionPosition.Long0);
    uint256 totalLong1 = opPair.totalPosition(strike, block.timestamp + 100, TimeswapV2OptionPosition.Long1);
    //vm.assume(amount < opPair.positionOf(strike, block.timestamp + 100, address(this), TimeswapV2OptionPosition.Short));

    if (strike > (uint256(1) << 128)) {
      vm.assume(isMulDivPossible(totalLong1, (uint256(1) << 128), strike));
    } else {
      vm.assume(isMulDivPossible(totalLong0, strike, (uint256(1) << 128)));
    }

    uint256 denominator = StrikeConversion.combine(totalLong0, totalLong1, strike, true);
    // uint256 token0Amount = Proportion.proportion(amount, totalLong0, denominator, false);
    // uint256 token1Amount = Proportion.proportion(amount, totalLong1, denominator, false);

    vm.assume(isMulDivPossible(amount, denominator, totalLong1));
    uint256 shortAmount = Proportion.proportion(amount, denominator, totalLong1, true);
    vm.assume(
      shortAmount <= opPair.positionOf(strike, block.timestamp + 100, address(this), TimeswapV2OptionPosition.Short) &&
        isMulDivPossible(shortAmount, totalLong0, denominator)
    );
    uint256 token0Amount = Proportion.proportion(shortAmount, totalLong0, denominator, false);

    vm.warp(block.timestamp + 101);
    CollectData memory output;
    (output.token0, output.token1, output.short) = opPair.collect(cparam);
    delete cparam;
    delete strike;
    assertEq(output.short, shortAmount);
    assertCollectedToken0Value(token0Amount, output.token0, token0To);
    assertCollectedToken1Value(amount, output.token1, token1To);
  }

  //   function assertOutputAndPositionsLong0Burnt(
  //     uint256 expectedAmount,
  //     uint256 mintedAmount,
  //     uint256 outputAmount
  //   ) internal {
  //     assertGe(1, mintedAmount - outputAmount);
  //     assertGe(1, opPair.positionOf(strike, maturity, address(this), ))
  //     assertEq(outputAmount, expectedAmount);
  //   }

  //   function testBurnGivenShorts(
  //       uint256 strike,
  //       uint256 amount0,
  //       uint256 amount1
  //   ) public {
  //     vm.assume(amount0 != 0 && amount1 != 0 && strike != 0);
  //     vm.assume(amount0 < (1 << 128) && amount1 < (1 << 128));

  //     bytes memory data;

  //     TimeswapV2OptionMintParam memory mintParam = TimeswapV2OptionMintParam({
  //         strike: strike,
  //         long0To: address(this),
  //         maturity: block.timestamp + 100,
  //         long1To: address(this),
  //         shortTo: address(this),
  //         transaction: TimeswapV2OptionMint.GivenShorts,
  //         amount0: amount0,
  //         amount1: amount1,
  //         data:data
  //     });

  //     MintData memory mintRes = MintData(0, 0, 0, strike, block.timestamp + 100, bytes(''));

  //     (mintRes.token0, mintRes.token1, mintRes.short, ) = opPair.mint(mintParam);

  //     TimeswapV2OptionBurnParam memory burnParam = TimeswapV2OptionBurnParam({
  //         strike: strike,
  //         token0To: address(this),
  //         maturity: block.timestamp + 100,
  //         token1To: address(this),
  //         transaction: TimeswapV2OptionBurn.GivenShorts,
  //         amount0: amount0,
  //         amount1: amount1
  //     });

  //     vm.expectEmit(false, false, false, true);
  //     emit Burn(
  //         strike,
  //         block.timestamp + 100,
  //         address(this),
  //         address(this),
  //         address(this),
  //         StrikeConversion.turn(amount0, strike, false, false),
  //         StrikeConversion.turn(amount1, strike, true, false),
  //         amount1 + amount0
  //     );

  //     BurnData memory burnRes;
  //     // OptionData memory prevOption;

  //     // prevOption.token0 = opPair.positionOf(strike, block.timestamp+100, address(this), TimeswapV2OptionPosition.Long0);
  //     // prevOption.token1 = opPair.positionOf(strike, block.timestamp+100, address(this), TimeswapV2OptionPosition.Long1);
  //     // prevOption.short = opPair.positionOf(strike, block.timestamp+100, address(this), TimeswapV2OptionPosition.Short);

  //     (burnRes.token0AndLong0Amount, burnRes.token1AndLong1Amount, burnRes.shortAmount) = opPair.burn(burnParam);

  //     assertGe(mintRes.token0, burnRes.token0AndLong0Amount);
  //     assertGe(mintRes.token1, burnRes.token1AndLong1Amount);
  //     assertGe(mintRes.short, burnRes.shortAmount);

  //   }
}
