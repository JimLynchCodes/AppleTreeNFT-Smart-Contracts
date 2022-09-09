const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");

use(solidity);

describe("APPLE", function () {
  let apple;

  let owner, user1, user2;
  
  beforeEach(async () => {
    [owner, user1, user2] = await ethers.getSigners();
    const AppleContract = await ethers.getContractFactory('APPLE');
    apple = await AppleContract.deploy()
  })

  describe("init", function () {

    it('initialiazes everyone owning zero apples', async () => {

      expect(await apple.balanceOf(owner.address)).to.equal(0);
      expect(await apple.balanceOf(user1.address)).to.equal(0);
      expect(await apple.balanceOf(user2.address)).to.equal(0);

    })

    it('initializes all nutrition scores to zero', async () => {

      expect(await apple.get_nutrition_score(owner.address)).to.equal(0);
      expect(await apple.get_nutrition_score(user1.address)).to.equal(0);
      expect(await apple.get_nutrition_score(user2.address)).to.equal(0);

    })

    it('initializes total supply of apples to zero (none minted up front)', async () => {

      expect(await apple.totalSupply()).to.equal(0);

    })

  });

  describe('minting apple', () => {

    it('can\'t be called by owner or user addresses', async () => {

      await expect(apple.mint(owner.address, 1)).to.be.revertedWith('Only the TREE contract can call this function');

    })

    describe('called by TREE contract', () => {

      it('mints apple to the specified user', () => {
        // TODO
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
