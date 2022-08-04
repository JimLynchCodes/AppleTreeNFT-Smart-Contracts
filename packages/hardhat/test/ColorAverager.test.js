const { ethers } = require('hardhat')
const { use, expect } = require('chai')
const { solidity } = require('ethereum-waffle')

use(solidity)

describe('ColorAverager', function () {
  let colorAverager

  describe('averageColors', function () {
    beforeEach(async () => {
      const ColorAverager_contract = await ethers.getContractFactory(
        'ColorAverager',
      )
      colorAverager = await ColorAverager_contract.deploy()
    })

    it('averages same colors to be the same', async () => {

        expect(await colorAverager.averageColors('#FF0000', '#FF0000')).to.equal('#FF0000');

        expect(await colorAverager.averageColors('#0000FF', '#0000FF')).to.equal('#0000FF');
    })
    
    it('averages different colors', async () => {
        expect(await colorAverager.averageColors('#999999', '#777777')).to.equal('#888888');
        expect(await colorAverager.averageColors('#777777', '#333333')).to.equal('#555555');


    })
  })
})
