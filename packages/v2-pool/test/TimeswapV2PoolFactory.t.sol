// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import 'forge-std/Test.sol';
import 'forge-std/console.sol';
import '../src/TimeswapV2PoolFactory.sol';
import '../src/interfaces/ITimeswapV2Pool.sol';
import '@timeswap-labs/v2-option/src/TimeswapV2OptionFactory.sol';
import '@timeswap-labs/v2-option/src/interfaces/ITimeswapV2Option.sol';

contract TimeswapV2PoolFactoryTest is Test {
  TimeswapV2OptionFactory optionFactory;
  TimeswapV2PoolFactory poolFactory;
  uint256 chosenTransactionFee = 5;
  uint256 chosenProtocolFee = 4;

  function setUp() public {
    optionFactory = new TimeswapV2OptionFactory();
    poolFactory = new TimeswapV2PoolFactory(address(this), chosenTransactionFee, chosenProtocolFee);
  }

  function testCreate(address token0, address token1) public {
    vm.assume(token1 > token0);
    vm.assume(token1 != address(0) && token0 != address(0));
    address opPair = optionFactory.create(token0, token1);
    address pool = poolFactory.create(opPair);
    assertEq(ITimeswapV2Pool(pool).poolFactory(), address(poolFactory));
    assertEq(ITimeswapV2Pool(pool).transactionFee(), chosenTransactionFee);
    assertEq(ITimeswapV2Pool(pool).protocolFee(), chosenProtocolFee);
    assertEq(ITimeswapV2Pool(pool).optionPair(), opPair);
  }

  function testGet() public {
    address token0 = address(1);
    address token1 = address(2);
    address opPair = optionFactory.create(token0, token1);
    address pool = poolFactory.create(opPair);
    address poolPair = poolFactory.get(opPair);
    assertEq(poolPair, pool);
  }

  function testNumberOfPairs() public {
    address token0 = address(1);
    address token1 = address(2);
    address opPair = optionFactory.create(token0, token1);
    address pool = poolFactory.create(opPair);
    assertEq(poolFactory.numberOfPairs(), 1);
  }
}
