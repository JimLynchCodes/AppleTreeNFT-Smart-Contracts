const { ethers } = require('hardhat')
const { use, expect } = require('chai')
const { solidity } = require('ethereum-waffle')
const { BigNumber } = require("@ethersproject/bignumber");
var utils = require('ethers').utils;

use(solidity)

describe('TreeHelpers', async function () {
  let treeHelpers;
  let appleContract;

  const msInOneWeek = 604800000;
  const msInOneMonth = 4 * msInOneWeek;
  const msInThreeMonths = 3 * msInOneMonth;
  const msInOneYear = 12 * msInOneMonth;
  const msInThreeYears = 3 * (12 * msInOneMonth);
  const msInFiveYears = 5 * (12 * msInOneMonth);
  const msInTenYears = 10 * (12 * msInOneMonth);
  const msInTwentyFiveYears = 25 * (12 * msInOneMonth);
  const msInFiftyYears = 50 * (12 * msInOneMonth);

  let newBornBirthday_s;
  let oneWeekOldBirthday_s;
  let oneMonthOldBirthday_s;
  let threeMonthOldBirthday_s;
  let oneYearOldBirthday_s;
  let threeYearOldBirthday_s;
  let fiveYearOldBirthday_s;
  let tenYearOldBirthday_s;
  let twentyFiveYearOldBirthday_s;
  let fiftyYearOldBirthday_s;

  const [owner] = await ethers.getSigners();

  // quick fix to let gas reporter fetch data from gas station & coinmarketcap
  before((done) => {
    setTimeout(done, 2000)
  })

  beforeEach(async () => {

    const TreeHelpersContract = await ethers.getContractFactory(
      'TreeHelpers',
    )
    treeHelpers = await TreeHelpersContract.deploy()


    const APPLE_contract = await ethers.getContractFactory(
      'APPLE'
    )

    appleContract = await APPLE_contract.deploy()

  })

  describe('apples_to_mint_calculation', function () {

    newBornBirthday_s = Math.floor(new Date().getTime() / 1000)
    oneWeekOldBirthday_s = Math.floor((new Date().getTime() - msInOneWeek) / 1000)
    oneMonthOldBirthday_s = Math.floor((new Date().getTime() - msInOneMonth) / 1000)
    threeMonthOldBirthday_s = Math.floor((new Date().getTime() - msInThreeMonths) / 1000)
    oneYearOldBirthday_s = Math.floor((new Date().getTime() - msInOneYear) / 1000)
    threeYearOldBirthday_s = Math.floor((new Date().getTime() - msInThreeYears) / 1000)
    fiveYearOldBirthday_s = Math.floor((new Date().getTime() - msInFiveYears) / 1000)
    tenYearOldBirthday_s = Math.floor((new Date().getTime() - msInTenYears) / 1000)
    twentyFiveYearOldBirthday_s = Math.floor((new Date().getTime() - msInTwentyFiveYears) / 1000);
    fiftyYearOldBirthday_s = Math.floor((new Date().getTime() - msInFiftyYears) / 1000);

    const testCases = [

      // zero nutrition, 1 growth score

      [newBornBirthday_s, 1, 18, 0, '1.0000000000001', '1.0000000001'],
      [oneWeekOldBirthday_s, 1, 18, 0, '1.0001', '1.001'],
      [oneMonthOldBirthday_s, 1, 18, 0, '1.01', '1.02'],
      [threeMonthOldBirthday_s, 1, 18, 0, '1.1', '1.2'],
      [oneYearOldBirthday_s, 1, 18, 0, '2.4', '2.5'],
      [threeYearOldBirthday_s, 1, 18, 0, '7.0', '7.1'],
      [fiveYearOldBirthday_s, 1, 18, 0, '9.0', '9.1'],
      [tenYearOldBirthday_s, 1, 18, 0, '10.4', '10.5'],
      [twentyFiveYearOldBirthday_s, 1, 18, 0, '10.75', '11.01'],
      [fiftyYearOldBirthday_s, 1, 18, 0, '10.9', '11.01'],

      // zero nutrition, 2 growth score

      [newBornBirthday_s, 2, 18, 0, '1.00000000000003', '1.000000001'],
      [oneWeekOldBirthday_s, 2, 18, 0, '1.001', '1.002'],
      [oneMonthOldBirthday_s, 2, 18, 0, '1.02', '1.03'],
      [threeMonthOldBirthday_s, 2, 18, 0, '1.2', '1.3'],
      [oneYearOldBirthday_s, 2, 18, 0, '3.8', '4'],
      [threeYearOldBirthday_s, 2, 18, 0, '13.0', '13.2'],
      [fiveYearOldBirthday_s, 2, 18, 0, '17.0', '17.2'],
      [tenYearOldBirthday_s, 2, 18, 0, '19.0', '20.0'],
      [twentyFiveYearOldBirthday_s, 2, 18, 0, '20.0', '21.0'],

      // zero nutrition, 5 growth score

      [newBornBirthday_s, 5, 18, 0, '1.0000000000007', '1.0000000008'],
      [oneWeekOldBirthday_s, 5, 18, 0, '1.003', '1.004'],
      [oneMonthOldBirthday_s, 5, 18, 0, '1.05', '1.06'],
      [threeMonthOldBirthday_s, 5, 18, 0, '1.5', '1.6'],
      [oneYearOldBirthday_s, 5, 18, 0, '8', '9'],
      [threeYearOldBirthday_s, 5, 18, 0, '31', '32'],
      [fiveYearOldBirthday_s, 5, 18, 0, '41', '42'],
      [tenYearOldBirthday_s, 5, 18, 0, '48', '49'],
      [twentyFiveYearOldBirthday_s, 5, 18, 0, '50', '51'],

      // zero nutrition, 10 growth score

      [newBornBirthday_s, 10, 18, 0, '1.0000000000001', '1.000000002'],
      [oneWeekOldBirthday_s, 10, 18, 0, '1', '1.008'],
      [oneMonthOldBirthday_s, 10, 18, 0, '1.1', '1.2'],
      [threeMonthOldBirthday_s, 10, 18, 0, '2', '2.1'],
      [oneYearOldBirthday_s, 10, 18, 0, '15', '16'],
      [threeYearOldBirthday_s, 10, 18, 0, '61', '62'],
      [fiveYearOldBirthday_s, 10, 18, 0, '81', '82'],
      [tenYearOldBirthday_s, 10, 18, 0, '95', '96'],
      [twentyFiveYearOldBirthday_s, 10, 18, 0, '100', '101'],

      /** With nutrition, max growth factor (10) */

      // low nutrition (5 apples eaten) - growth factor 10
      [newBornBirthday_s, 10, 18, utils.parseEther('5'), '1.0000000000005', '1.000000007'],
      [oneWeekOldBirthday_s, 10, 18, utils.parseEther('5'), '1.02', '1.03'],
      [oneMonthOldBirthday_s, 10, 18, utils.parseEther('5'), '1.4', '1.5'],
      [threeMonthOldBirthday_s, 10, 18, utils.parseEther('5'), '5', '5.1'],
      [oneYearOldBirthday_s, 10, 18, utils.parseEther('5'), '41', '42'],
      [threeYearOldBirthday_s, 10, 18, utils.parseEther('5'), '85', '87'],
      [fiveYearOldBirthday_s, 10, 18, utils.parseEther('5'), '95', '96'],
      [tenYearOldBirthday_s, 10, 18, utils.parseEther('5'), '99', '100'],
      [twentyFiveYearOldBirthday_s, 10, 18, utils.parseEther('5'), '100', '101'],

      // medium nutrition (20 apples eaten) - growth factor 10
      [newBornBirthday_s, 10, 18, utils.parseEther('20'), '1.000000000001', '1.00000002'],
      [oneWeekOldBirthday_s, 10, 18, utils.parseEther('20'), '1.05', '1.06'],
      [oneMonthOldBirthday_s, 10, 18, utils.parseEther('20'), '1.8', '1.9'],
      [threeMonthOldBirthday_s, 10, 18, utils.parseEther('20'), '7.9', '8.1'],
      [oneYearOldBirthday_s, 10, 18, utils.parseEther('20'), '55', '56'],
      [threeYearOldBirthday_s, 10, 18, utils.parseEther('20'), '92', '93'],
      [fiveYearOldBirthday_s, 10, 18, utils.parseEther('20'), '97', '98'],
      [tenYearOldBirthday_s, 10, 18, utils.parseEther('20'), '100', '101'],
      [twentyFiveYearOldBirthday_s, 10, 18, utils.parseEther('20'), '100', '101'],

      // high nutrition (100 apples eaten) - growth factor 10
      [newBornBirthday_s, 10, 18, utils.parseEther('100'), '1.0000000000001', '1.0000002'],
      [oneWeekOldBirthday_s, 10, 18, utils.parseEther('100'), '1.08', '1.09'],
      [oneMonthOldBirthday_s, 10, 18, utils.parseEther('100'), '2.2', '2.3'],
      [threeMonthOldBirthday_s, 10, 18, utils.parseEther('100'), '11', '12'],
      [oneYearOldBirthday_s, 10, 18, utils.parseEther('100'), '66', '67'],
      [threeYearOldBirthday_s, 10, 18, utils.parseEther('100'), '95', '96'],
      [fiveYearOldBirthday_s, 10, 18, utils.parseEther('100'), '98', '99'],
      [tenYearOldBirthday_s, 10, 18, utils.parseEther('100'), '100', '101'],
      [twentyFiveYearOldBirthday_s, 10, 18, utils.parseEther('100'), '100', '101'],

      // higher nutrition (1000 apples eaten) - growth factor 10
      [newBornBirthday_s, 10, 18, utils.parseEther('1000'), '1.0000000000002', '1.0000003'],
      [oneWeekOldBirthday_s, 10, 18, utils.parseEther('1000'), '1.1', '1.2'],
      [oneMonthOldBirthday_s, 10, 18, utils.parseEther('1000'), '2.8', '3'],
      [threeMonthOldBirthday_s, 10, 18, utils.parseEther('1000'), '15', '16'],
      [oneYearOldBirthday_s, 10, 18, utils.parseEther('1000'), '74', '75'],
      [threeYearOldBirthday_s, 10, 18, utils.parseEther('1000'), '97', '98'],
      [fiveYearOldBirthday_s, 10, 18, utils.parseEther('1000'), '99', '100'],
      [tenYearOldBirthday_s, 10, 18, utils.parseEther('1000'), '100', '101'],
      [twentyFiveYearOldBirthday_s, 10, 18, utils.parseEther('1000'), '100', '101'],

      // very high nutrition (100,000 apples eaten) - growth factor 10
      [newBornBirthday_s, 10, 18, utils.parseEther('1000000'), '1.00000000000025', '1.0000008'],
      [oneWeekOldBirthday_s, 10, 18, utils.parseEther('1000000'), '1.2', '1.3'],
      [oneMonthOldBirthday_s, 10, 18, utils.parseEther('1000000'), '4.4', '4.5'],
      [threeMonthOldBirthday_s, 10, 18, utils.parseEther('1000000'), '25', '26'],
      [oneYearOldBirthday_s, 10, 18, utils.parseEther('1000000'), '84', '85'],
      [threeYearOldBirthday_s, 10, 18, utils.parseEther('1000000'), '98', '99'],
      [fiveYearOldBirthday_s, 10, 18, utils.parseEther('1000000'), '100', '101'],
      [tenYearOldBirthday_s, 10, 18, utils.parseEther('1000000'), '100', '101'],
      [twentyFiveYearOldBirthday_s, 10, 18, utils.parseEther('1000000'), '100', '101'],

    ]

    testCases.forEach(testCase => {

      const birthday = testCase[0];
      const growthStrength = testCase[1];
      const appleDecimals = testCase[2];
      const nutritionScore = testCase[3];
      const lowerBound = testCase[4];
      const upperBound = testCase[5];

      it(`birthday: ${birthday}, growthStrength: ${growthStrength}, appleDecimals: ${appleDecimals}, nutritionScore: ${nutritionScore} -> ${lowerBound} < x < ${upperBound}`, async () => {

        const result = await treeHelpers.apples_to_mint_calculation(
          birthday,
          growthStrength,
          appleDecimals,
          nutritionScore
        );

        // console.log('resultString: ')
        // console.log(result.toString())

        expect(result.gt(utils.parseEther(lowerBound))).to.be.true;
        expect(result.lt(utils.parseEther(upperBound))).to.be.true;
      })

    })

  })

  describe('fibonacci level', () => {

    const testCases = [
      [utils.parseEther('0'), 1],
      [utils.parseEther('1'), 1],
      [utils.parseEther('2'), 2],
      [utils.parseEther('3'), 3],
      [utils.parseEther('4'), 4],
      [utils.parseEther('5'), 4],
      [utils.parseEther('6'), 5],
      [utils.parseEther('7'), 5],
      [utils.parseEther('8'), 5],
      [utils.parseEther('9'), 6],
      [utils.parseEther('12'), 6],
      [utils.parseEther('13'), 6],
      [utils.parseEther('20'), 7],
      [utils.parseEther('21'), 7],
      [utils.parseEther('33'), 8],
      [utils.parseEther('34'), 8],
      [utils.parseEther('35'), 9],
    ]

    testCases.forEach(testCase => {

      const input = testCase[0];
      const expectedOutput = testCase[1];

      it(`input: ${input} -> output: ${expectedOutput}`, async () => {

        const result = await treeHelpers.fib_level_loop(input, 18);

        expect(result).to.equal(expectedOutput)
      })

    })

  })

})
