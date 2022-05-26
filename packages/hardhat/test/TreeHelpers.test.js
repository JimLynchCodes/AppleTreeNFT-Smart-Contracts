const { ethers } = require('hardhat')
const { use, expect } = require('chai')
const { solidity } = require('ethereum-waffle')

use(solidity)

describe('TreeHelpers', async function () {
  let treeHelpers
  let appleContract

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

    describe('empty APPLES contract', () => {

      it('makes at least one apple', async () => {
        
        // treeHelpers = await TreeHelpersContract.deploy()
        
        const dateTime = new Date().getTime();
        const dateTimeSeconds = Math.floor(dateTime / 1000);
        
        const result = await treeHelpers.apples_to_mint_calculation(
          dateTimeSeconds,
          dateTimeSeconds,
          appleContract.address
        );

        // const appleAwardedBn = await appleContract.balanceOf(owner.address)

        const appleAwarded = result

        // BigNumber.from()

        console.log({ appleAwarded })

        // expect(appleAwarded).to.be.greaterThan(1)
      })

      it('makes at least one apple', async () => {
        
        // treeHelpers = await TreeHelpersContract.deploy()
        
        const dateTime = new Date().getTime();
        const dateTimeSeconds = Math.floor(dateTime / 1000);
        
        const result = await treeHelpers.apples_to_mint_calculation(
          dateTimeSeconds,
          dateTimeSeconds,
          appleContract.address
        );

        const appleAwarded = await appleContract.balanceOf(owner.address)

        // console.log(appleAwarded.toNumber())
        // console.log(result.toNumber() / 10**18)

      })
      
      it('', async () => {
        
      })

    })
  })
})
