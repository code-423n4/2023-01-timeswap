//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import '../../src/structs/Param.sol';

library ParamLibraryExt{
  function checkMint(TimeswapV2OptionMintParam memory param, uint96 blockTimestamp) internal pure {
    return ParamLibrary.check(param, blockTimestamp);
  }
  function checkBurn(TimeswapV2OptionBurnParam memory param, uint96 blockTimestamp) internal pure {
    return ParamLibrary.check(param, blockTimestamp);
  }
  function checkSwap(TimeswapV2OptionSwapParam memory param, uint96 blockTimestamp) internal pure {
    return ParamLibrary.check(param, blockTimestamp);
  }
  function checkCollect(TimeswapV2OptionCollectParam memory param, uint96 blockTimestamp) internal pure {
    return ParamLibrary.check(param, blockTimestamp);
  }
}