pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract APPLE is ERC20, Ownable, Pausable {

  address TREE_address;

  mapping(address => uint256) nutrition_score;

  constructor() ERC20("Apples", "APPLE") {
    // Do nothing on delpoy...
  }

  function get_nutrition_score(address account) public view returns (uint256) {
    return nutrition_score[account];
  }

  modifier onlyCalledByTREE() {
    require(msg.sender == TREE_address, 'Only the TREE contract can call this function');
    _;
  }

  // created by TREE breeding
  function mint(address account, uint256 amount) public onlyCalledByTREE {
    _mint(account, amount);
  }

  function eat(uint256 amount) external whenNotPaused {
    _burn(msg.sender, amount);
    nutrition_score[msg.sender] += amount;
  }

  // admin functions
  function update_TREE_address(address newTreeAddress) external onlyOwner {
    TREE_address = newTreeAddress;
  }

}
