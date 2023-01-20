// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.8;
import "../../src/libraries/OptionFactory.sol";

library OptionFactoryExt {
    function checkNotZeroFactory(address optionFactory) public pure {
        return OptionFactoryLibrary.checkNotZeroFactory(optionFactory);
    }

    function get(address optionFactory, address token0, address token1) public view returns (address) {
        return OptionFactoryLibrary.get(optionFactory, token0, token1);
    }

    function getWithCheck(address optionFactory, address token0, address token1) public view returns (address) {
        return OptionFactoryLibrary.getWithCheck(optionFactory, token0, token1);
    }
}
