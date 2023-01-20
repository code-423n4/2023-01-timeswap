// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import "../../src/libraries/PoolFactory.sol";

library PoolFactoryExt {
    function checkNotZeroFactory(address poolFactory) public pure {
        PoolFactoryLibrary.checkNotZeroFactory(poolFactory);
    }

    function get(address optionFactory, address poolFactory, address token0, address token1) public view returns (address optionPair, address poolPair) {
        (optionPair, poolPair) = PoolFactoryLibrary.get(optionFactory, poolFactory, token0, token1);
    }

    function getWithCheck(address optionFactory, address poolFactory, address token0, address token1) public view returns (address optionPair, address poolPair) {
        (optionPair, poolPair) = PoolFactoryLibrary.getWithCheck(optionFactory, poolFactory, token0, token1);
    }
}
