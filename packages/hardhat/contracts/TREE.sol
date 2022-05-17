pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./APPLE.sol";

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract TREE is ERC721, Ownable, Pausable {

  address APPLE_address;

  uint256 gen_zeros_minted;
  uint256 gen_zeros_max_supply = 10000;

  uint256 salesCommision = 2;
  uint256 breedingCommision = 2;

  struct TreeData {
    uint256 tokenId;
    
    uint256 birthday_timestamp;
    uint256 last_picked_apple_timestamp;
    
    bool isForSale;
    uint256 sellingPrice;
    bool isListedForBreeding;
    uint256 breedingPrice;
    uint256 gen;

    uint256 growthSpeed;
    uint256 growthStrength;

    string trunk_color;
    string trunk_style;
    string leaves_color;
    string leaves_style;

  }

  // tokenId => for_sale_index
  mapping(uint256 => uint256) trees_for_sale_index;
  uint256 next_tree_for_sale_index;

  // tokenId => for_sale_index
  mapping(uint256 => uint256) trees_for_breeding_index;
  uint256 next_tree_for_breeding_index;

  mapping(uint256 => TreeData) trees;

  // uses tree index
  uint256[] trees_for_sale;
  
  // uses tree index
  uint256[] trees_for_breeding;

  uint256 next_tree_token_id = 1;

  constructor() ERC721("Apples", "APPLE") {
    // Do nothing on delpoy...
  }

  function pick_APPLEs(uint256 tree_token_id) external whenNotPaused {

    require(msg.sender == ownerOf(tree_token_id));
    require(block.timestamp > (tree.last_picked_apple_timestamp + tree.growthSpeed));
    
    TreeData memory tree = trees[tree_token_id];

    uint256 amount_of_apples_to_mint = apples_to_mint_calculation(tree);

    trees[tree_token_id].last_picked_apple_timestamp = block.timestamp;

    APPLE(APPLE_address).mint(msg.sender, amount_of_apples_to_mint);

  }

  function apples_to_mint_calculation(TreeData memory tree) internal view returns (uint256) {

    uint256 age_ms = block.timestamp - tree.birthday_timestamp;

    return tree.growthStrength * ( age_ms ** 2 / 
      (age_ms ** 2 + APPLE(APPLE_address).get_nutrition_score(msg.sender)));
  }

  // gene splicing
  function mint() internal {

  }

  function list_for_breeding(uint256 tokenId, uint256 breeding_price) external whenNotPaused {
    require(ownerOf(tokenId) == msg.sender);

    if (!trees[tokenId].isListedForBreeding) {
      trees_for_breeding.push(tokenId);
      trees_for_breeding_index[tokenId] = next_tree_for_breeding_index;
      next_tree_for_breeding_index++;
    }

    trees[tokenId].isListedForBreeding = true;
    trees[tokenId].breedingPrice = breeding_price;

  }

  function select_breeding_mate(uint256 my_tree_token, uint256 mate_tree_token) external whenNotPaused {

    require(trees[mate_tree_token].isListedForBreeding, "That TREE is not listed for breeding!");
    require(ownerOf(my_tree_token) == msg.sender, "You are not the TREE owner!");
    require(balanceOf(msg.sender) >= trees[mate_tree_token].breedingPrice);

    // transfer APPLE payment
    APPLE(APPLE_address).approve(address(this), trees[mate_tree_token].breedingPrice);
    APPLE(APPLE_address).transferFrom(msg.sender, ownerOf(mate_tree_token), trees[mate_tree_token].breedingPrice * (100 - breedingCommision) / 100));
    APPLE(APPLE_address).transferFrom(msg.sender, address(this), trees[mate_tree_token].breedingPrice * breedingCommision / 100);

    uint256 offspring_generation = 1 + trees[mate_tree_token].gen >= trees[my_tree_token] ? trees[mate_tree_token].gen : trees[my_tree_token];
    uint256 offspring_growth_speed = (trees[mate_tree_token].growthSpeed + trees[my_tree_token].growthSpeed) / 2;
    uint256 offspring_growth_strength = (trees[mate_tree_token].growthStrength + trees[my_tree_token].growthStrength) / 2;

    // TODO - find "average" of colors and styles...
    uint256 offspring_trunk_color = trees[mate_tree_token].trunk_color;
    uint256 offspring_trunk_style = trees[mate_tree_token].trunk_style;
    uint256 offspring_leaves_color = trees[mate_tree_token].leaves_color;
    uint256 offspring_leaves_style = trees[mate_tree_token].leaves_style;

    TreeData memory new_tree = TreeData(
      next_tree_token_id,
      block.timestamp,
      block.timestamp,
      false,
      listingPrice,
      false,
      0,
      offspring_generation,  
      offspring_growth_speed,
      offspring_growth_strength,
      offspring_trunk_color, 
      offspring_trunk_style,
      offspring_leaves_color,
      offspring_leaves_style
    );

    _safeMint(msg.sender, next_tree_token_id);

    trees[next_tree_token_id] = new_tree;

    next_tree_token_id++;

  }

  // listing & purchasing

  function list_for_sale(uint256 tokenId, uint256 sell_price) external whenNotPaused {

    require(ownerOf(tokenId) == msg.sender);
    
    if (!trees[tokenId].isForSale) {
      trees_for_sale.push(tokenId);
      trees_for_sale_index[tokenId] = next_tree_for_sale_index;
      next_tree_for_sale_index++;
    }

    trees[tokenId].isForSale = true;
    trees[tokenId].sellingPrice = sell_price;

    approve(address(this), tokenId);

  }

  function cancel_for_sale(uint tokenId) external whenNotPaused {
    // gives approval rights back to the current owner.
    approve(ownerOf(tokenId), tokenId);

    // swap n' pop removal from for sale array

    uint256 old_token_for_sale_index = trees_for_sale_index[tokenId];

    uint256 last_element_token_id = trees_for_sale[next_tree_for_sale_index];

    // set last index value overwriting the element to delete
    trees_for_sale[old_token_for_sale_index] = trees_for_sale[next_tree_for_sale_index];
    trees_for_sale_index[last_element_token_id] = old_token_for_sale_index;

    // pop off the end
    trees_for_sale.pop();

  }

  function purchase(uint256 tree_token_id) external whenNotPaused {

    address current_owner = ownerOf(tree_token_id);

    require(msg.sender != current_owner, "Can't buy your own TREE!");
    require(trees[tree_token_id].isForSale, "Can't buy a TREE that isn't for sale!");
    require(APPLE(APPLE_address).balanceOf(msg.sender) >= trees[tree_token_id].sellingPrice, "You don\'t have enough APPLEs to buy this TREE!");

    // transfer APPLE to the seller
    APPLE(APPLE_address).approve(address(this), trees[tree_token_id].sellingPrice);
    APPLE(APPLE_address).transferFrom(msg.sender, current_owner, trees[tree_token_id].sellingPrice * (100 - salesCommision) / 100);
    APPLE(APPLE_address).transferFrom(msg.sender, address(this), trees[tree_token_id].sellingPrice * salesCommision / 100);

    // transfer TREE NFT to the buyer
    transferFrom(current_owner, msg.sender, tree_token_id);

  }

  // admin functions
  function list_gen_zero(

    uint256 listingPrice,

    uint256 growthSpeed,
    uint256 growthStrength,

    string memory trunk_color, 
    string memory trunk_style,
    string memory leaves_color,
    string memory leaves_style

  ) external onlyOwner {

    require(gen_zeros_minted < gen_zeros_max_supply);

    TreeData memory new_tree = TreeData(
      next_tree_token_id,
      block.timestamp,
      block.timestamp,
      true,
      listingPrice,
      false,
      0,
      0,
      growthSpeed,
      growthStrength,
      trunk_color, 
      trunk_style,
      leaves_color,
      leaves_style
    );

    _safeMint(address(this), next_tree_token_id);

    trees[next_tree_token_id] = new_tree;

    trees_for_sale.push(next_tree_token_id);

    next_tree_token_id++;
  }

  function update_APPLE_address(address newTreeAddress) external onlyOwner {
    APPLE_address = newTreeAddress;
  }

}
