const { ethers } = require('hardhat')
const { use, expect } = require('chai')
const { solidity } = require('ethereum-waffle')

use(solidity)

describe('TREE', function () {
  let myContract

  // quick fix to let gas reporter fetch data from gas station & coinmarketcap
  before((done) => {
    setTimeout(done, 2000)
  })

  describe('TREE', function () {

    let TREE;
    let APPLE;

    beforeEach(async () => {
      const TREE_Helpers_contract = await ethers.getContractFactory(
        'TREE_helpers',
      )
      const TREE_Helpers = await TREE_Helpers_contract.deploy()
      const Other_Helpers_contract = await ethers.getContractFactory(
        'Other_helpers',
      )
      const Other_Helpers = await Other_Helpers_contract.deploy()
  
      const ColorAverager_contract = await ethers.getContractFactory(
        'ColorAverager',
      )
      const ColorAverager = await ColorAverager_contract.deploy()
      
      const APPLE_contract = await ethers.getContractFactory(
        'APPLE'
      )
      
      APPLE = await APPLE_contract.deploy()
  
      const TREE_contract = await ethers.getContractFactory('TREE', {
        libraries: {
          TREE_helpers: TREE_Helpers.address,
          Other_helpers: Other_Helpers.address,
          ColorAverager: ColorAverager.address,
        },
      })
  
      TREE = await TREE_contract.deploy(APPLE.address)

    })

    it('Should deploy TREE', async function () {
      expect((await TREE.name()).length).to.be.greaterThan(0)
    })

    describe('minting gen zero trees', () => {
      
    })

    describe('picking APPLE', () => {

    })

    describe('selling TREEs', () => {

    })

    describe('breeding TREEs', () => {

    })

  })
})
