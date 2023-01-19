//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../wrappedContracts/PoolFactoryExt.sol";
import "../../src/TimeswapV2PoolFactory.sol";
import "../../src/interfaces/ITimeswapV2Pool.sol";
import "@timeswap-labs/v2-option/src/TimeswapV2OptionFactory.sol";
import "@timeswap-labs/v2-option/src/interfaces/ITimeswapV2Option.sol";

contract PoolFactory is Test {
    TimeswapV2OptionFactory optionFactory;
    TimeswapV2PoolFactory poolFactory;
    uint256 chosenTransactionFee = 5;
    uint256 chosenProtocolFee = 4;

    function setUp() public {
        optionFactory = new TimeswapV2OptionFactory();
        poolFactory = new TimeswapV2PoolFactory(address(this), chosenTransactionFee, chosenProtocolFee);
    }

    function testCheckNotZeroFactoryRevert() public {
        vm.expectRevert();
        address poolFactoryAddress = address(0);
        PoolFactoryExt.checkNotZeroFactory(poolFactoryAddress);
    }

    function testCheckNotZeroFactorySuccess() public pure {
        address poolFactoryAddress = address(1);
        PoolFactoryExt.checkNotZeroFactory(poolFactoryAddress);
    }

    function testGet() public {
        address token0 = address(3);
        address token1 = address(4);
        (address optionPair, address poolPair) = PoolFactoryExt.get(address(optionFactory), address(poolFactory), token0, token1);
        assertEq(optionPair, address(0));
        assertEq(poolPair, address(0));
    }

    function testGetWithCheckNotZero() public {
        address token0 = address(3);
        address token1 = address(4);
        address opPair = optionFactory.create(token0, token1);
        address pool = poolFactory.create(opPair);
        (address optionPair, address poolPair) = PoolFactoryExt.getWithCheck(ITimeswapV2Option(opPair).optionFactory(), ITimeswapV2Pool(pool).poolFactory(), token0, token1);
        assertTrue(optionPair != address(0));
        assertTrue(poolPair != address(0));
    }

    function testGetWithCheckRevert() public {
        vm.expectRevert();
        address token0 = address(3);
        address token1 = address(4);
        address opPair = address(5);
        address pool = address(6);
        (address optionPair, address poolPair) = PoolFactoryExt.getWithCheck(ITimeswapV2Option(opPair).optionFactory(), ITimeswapV2Pool(pool).poolFactory(), token0, token1);
    }
}
