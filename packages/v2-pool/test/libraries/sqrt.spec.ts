import { expect } from 'chai';
import { ethers } from 'hardhat';
import * as fc from 'fast-check';
// import bigint from "bigint-isqrt";
function sqrt(value: bigint) {
  if (value < 0n) {
    throw 'square root of negative numbers is not supported';
  }

  if (value < 2n) {
    return value;
  }
  function newtonIteration(n: bigint, x0: bigint): bigint {
    const x1 = (n / x0 + x0) >> 1n;
    if (x0 === x1 || x0 === x1 - 1n) {
      return x0;
    }
    return newtonIteration(n, x1);
  }

  return newtonIteration(value, 1n);
}

// describe("Sqrt", function () {
//   it("Should return the correct square root", async function () {

//     const sqrtLibFactory = await ethers.getContractFactory("Sqrt")
//     const sqrtLibContract = await sqrtLibFactory.deploy()
//     await sqrtLibContract.deployed()
//     const sqrtTestFactory = await ethers.getContractFactory("sqrtTest",{libraries: {Sqrt: sqrtLibContract.address}});
//     const sqrtTestContract = await sqrtTestFactory.deploy();
//     await sqrtTestContract.deployed();

//     const testSqrtTxn = await sqrtTestContract.test_sqrt(0,2n**44n);
//     await testSqrtTxn.wait();
//     const testSqrt = BigInt(await sqrtTestContract.get_result());

//     const expectedSqrt= sqrt(2n**300n)

//     const ratio = Number(testSqrt*100n/ expectedSqrt)/100
//     // console.log(ratio)
//     const dev = Math.abs(1-ratio)
//     // console.log(testSqrt,expectedSqrt)
//     // console.log('dev is',dev)

//     // wait until the transaction is mined

//     expect(expectedSqrt.toString()).to.equal(testSqrt.toString());
//   });
// });

describe('SQRT TEST', () => {
  it('Succeeded', async () => {
    await fc.assert(
      fc.asyncProperty(fc.bigUintN(512), async (data) => {
        const MAXUINT256 = 2n ^ 256n;
        let a0 = data;
        let a1 = 0n;
        if (data >= MAXUINT256) {
          a0 = data % MAXUINT256;
          a1 = data >> 256n;
        }
        const sqrtLibFactory = await ethers.getContractFactory('Sqrt');
        const sqrtLibContract = await sqrtLibFactory.deploy();
        await sqrtLibContract.deployed();
        const sqrtTestFactory = await ethers.getContractFactory('sqrtTest', {
          libraries: { Sqrt: sqrtLibContract.address },
        });
        const sqrtTestContract = await sqrtTestFactory.deploy();
        await sqrtTestContract.deployed();
        const testSqrtTxn = await sqrtTestContract.test_sqrt(a0, a1);
        const receipt = await testSqrtTxn.wait();
        const testSqrt = BigInt(await sqrtTestContract.get_result());
        const expectedSqrt = sqrt(data);
        if (testSqrt.toString() === expectedSqrt.toString()) {
          console.log('calculated');
          return true;
        }
        console.log('wrong');
        console.log({
          a0: a0,
          a1: a1,
          number: data,
          expsqrt: expectedSqrt,
          result: testSqrt,
          deviation: Math.abs(1 - Number((expectedSqrt * 100n) / testSqrt) / 100),
        });
        return false;
      })
    );
  });
});
