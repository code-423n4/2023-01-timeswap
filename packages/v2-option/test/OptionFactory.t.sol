// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.8;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./wrappedContracts/OptionFactoryExt.sol";

contract OptionFactoryTest is Test {
    function testCheckNotZeroFactory() public {
        vm.expectRevert();
        OptionFactoryExt.checkNotZeroFactory(address(0));
    }

    function testGet(address optionFactory, address token0, address token1) public {
        vm.expectRevert();
        OptionFactoryExt.get(address(0), address(0), address(0));
    }

    function testGetWithCheck(address optionFactory, address token0, address token1) public {
        vm.expectRevert();
        OptionFactoryExt.getWithCheck(address(0), address(0), address(0));
    }
}
