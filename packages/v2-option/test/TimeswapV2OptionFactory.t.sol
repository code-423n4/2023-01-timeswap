// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import "forge-std/Test.sol";
import "../src/TimeswapV2OptionFactory.sol";
import "../src/interfaces/ITimeswapV2Option.sol";

contract TimeswapV2OptionFactoryTest is Test {
    TimeswapV2OptionFactory factory;

    function setUp() public {
        factory = new TimeswapV2OptionFactory();
    }

    function testCreate(address token0, address token1) public {
        vm.assume(token1 > token0);
        vm.assume(token1 != address(0) && token0 != address(0));
        address opPair = factory.create(token0, token1);
        assertEq(token0, ITimeswapV2Option(opPair).token0());
        assertEq(token1, ITimeswapV2Option(opPair).token1());
        assertEq(opPair, factory.get(token0, token1));
        assertEq(address(factory), ITimeswapV2Option(opPair).optionFactory());
    }

    function testOptionFactoryGet(address token0, address token1) public {
        vm.assume(token1 > token0);
        vm.assume(token1 != address(0) && token0 != address(0));
        address opPair = factory.create(token0, token1);
        assertEq(opPair, factory.get(token0, token1));
    }

    function testOptionFactoryNumberOfPairs() public {
        console.log(factory.numberOfPairs());
        assertEq(0, factory.numberOfPairs());
    }
}
