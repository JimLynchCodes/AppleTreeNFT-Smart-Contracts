const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");

use(solidity);

describe("APPLE", function () {
  let myContract;

  // quick fix to let gas reporter fetch data from gas station & coinmarketcap
  before((done) => {
    setTimeout(done, 2000);
  });

  describe("deploy", function () {

    it('initialiazes everyone owning zero', () => {

    })

    it('initializes totalSupply to zero', () => {

    })

  });

  describe('minting apple', () => {

    it('can\'t be called by owner or user addresses', () => {
      
    })

    describe('called by TREE contract', () => {

      it('mints apple to the specified user', () => {

      })
      
    })

  })

  describe('eating apple', () => {

    it('burns apple equal to amount eaten', () => {
      
    })
    it('updates nutrition score equal to amount eaten', () => {

    })

  })

});
