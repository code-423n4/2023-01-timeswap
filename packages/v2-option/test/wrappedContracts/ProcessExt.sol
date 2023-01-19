
import "../../src/structs/Process.sol";

library ProcessLibraryExt{
   function updateProcessExt(Process[] storage processing, uint256 token0Amount, uint256 token1Amount, bool isAddToken0, bool isAddToken1) public {
      return ProcessLibrary.updateProcess(processing, token0Amount, token1Amount, isAddToken0, isAddToken1);
   }
}