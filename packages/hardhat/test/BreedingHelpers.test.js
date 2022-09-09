const { ethers } = require('hardhat')
const { use, expect } = require('chai')
const { solidity } = require('ethereum-waffle')

var utils = require('ethers').utils;

use(solidity)

describe('BreedingHelpers', function () {
  let breedingHelpers;

  let owner;

  beforeEach(async () => {
    
    [owner] = await ethers.getSigners();
    const BreedingHelpersContract = await ethers.getContractFactory(
      'BreedingHelpers',
    )
    breedingHelpers = await BreedingHelpersContract.deploy();

  })

  describe('min_breeding_price', () => {

    const testCases = [

      [0, 1, '9.99', '10.1'],
      [1, 1, '10', '10.25'],
      [2, 2, '10.03', '10.1'],
      [5, 5, '10.199', '10.3'],
      [10, 10, '10.4', '10.5'],
      [100, 100, '14', '16'],
      [1000, 1000, '58', '59'],
      [1000000, 1000000, '50000', '50011'],
      [10000000, 10000000, '490000', '501000'],
      [100000000, 100000000, '5000000', '5001100'],
      [1000000000, 1000000000, '49000000', '50011000'],

      // high apple supply, low trees supply
      
      [1000000000, 5,  '3000', '3200'],
      [1000000000, 100,  '15000', '16000'],
      [1000000000, 5000,  '110000', '120000'],
      [1000000000, 50000,  '350000', '360000'],
      [1000000000, 1000000,  '1500000', '2000000'],
      
      // low apple supply, high trees supply
      
      [5, 1000000000, '3000', '3200'],
      [100, 1000000000, '15000', '16000'],
      [5000, 1000000000, '110000', '120000'],
      [50000, 1000000000, '350000', '360000'],
      [1000000, 1000000000, '1500000', '2000000'],
    ]

    testCases.forEach(testCase => {

      const supplyOfApples = testCase[0];
      const supplyOfTress = testCase[1];
      const minBreedingPriceLowerBound = testCase[2];
      const minBreedingPriceUpperBound = testCase[3];

      it(`supplyOfApples: ${supplyOfApples}, supplyOfTrees: ${supplyOfTress} -> min-breeding price lowerBound: ${minBreedingPriceLowerBound}, min-breeding price upperBound: ${minBreedingPriceUpperBound}`, async () => {

        const result = await breedingHelpers.min_breeding_price(
          supplyOfApples, supplyOfTress, 18
        );

        // console.log('resultBreedingString: ')
        // console.log(result.toString())

        expect(result.gt(utils.parseEther(minBreedingPriceLowerBound))).to.be.true;
        expect(result.lt(utils.parseEther(minBreedingPriceUpperBound))).to.be.true;

      })

    })

  })

})
