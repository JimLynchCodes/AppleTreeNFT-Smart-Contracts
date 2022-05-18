pragma solidity >=0.8.13 <0.9.0;
//SPDX-License-Identifier: MIT

import "./APPLE.sol";
import "./Base64.sol";
import "./TREE_helpers.sol";

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TREE is ERC721, ERC721Holder, Ownable, Pausable {
    address public APPLE_address;

    uint16 constant gen_zeros_max_supply = 10000; // 8 bytes, max value 65535

    uint8 constant salesCommision = 2;
    uint8 constant breedingCommision = 2;

    uint256 gen_zeros_minted;

    uint256 next_tree_for_sale_index;
    uint256 next_tree_for_breeding_index;
    uint256 next_tree_token_id = 1;

    // tokenId => for_sale_index
    mapping(uint256 => uint256) trees_for_sale_index;

    // tokenId => for_sale_index
    mapping(uint256 => uint256) trees_for_breeding_index;

    mapping(uint256 => TreeData) trees;

    // uses tree index
    uint256[] public trees_for_sale;

    // uses tree index
    uint256[] public trees_for_breeding;

    struct TreeData {
        bool isForSale; // 1 byte
        bool isListedForBreeding; // 1 byte
        uint8 growthStrength; // 1 byte    // min value: 1, max value: 10
        string trunk_color; // 1 byte per char
        string leaf_primary_color; // 1 byte per char
        string leaf_secondary_color; // 1 byte per char
        uint256 tokenId; // 32 bytes
        uint256 birthday_timestamp; // 32 bytes
        uint256 last_picked_apple_timestamp; // 32 bytes
        uint256 sapling_growth_time; // 32 bytes
        uint256 sellingPrice; // 32 bytes
        uint256 breedingPrice; // 32 bytes
        uint256 gen; // 32 bytes
        uint256 growthSpeed; // 32 bytes  // min value, 6 hours - max value - 7 days
    }

    constructor(address _APPLE_address) ERC721("APPLE TREE", "APPLETREE") {
        APPLE_address = _APPLE_address;
    }

    function pick_APPLEs(uint256 tree_token_id) external whenNotPaused {
        require(
            msg.sender == ownerOf(tree_token_id)
            // ,"You are not the TREE owner!"
        );

        require(
            block.timestamp >
                (trees[tree_token_id].birthday_timestamp +
                    trees[tree_token_id].sapling_growth_time)
            // ,"This TREE is still a wee sapling!"
        );

        require(
            block.timestamp >
                (trees[tree_token_id].last_picked_apple_timestamp +
                    trees[tree_token_id].growthSpeed)
            // ,"The APPLE on this TREE is not done growing yet!"
        );

        trees[tree_token_id].last_picked_apple_timestamp = block.timestamp;

        APPLE(APPLE_address).mint(
            msg.sender,
            TREE_helpers.apples_to_mint_calculation(
                trees[tree_token_id].birthday_timestamp,
                trees[tree_token_id].growthStrength,
                APPLE_address
            )
        );
    }

    // breeding of TREEs
    function list_for_breeding(uint256 tokenId, uint256 breeding_price)
        external
        whenNotPaused
    {
        require(ownerOf(tokenId) == msg.sender);

        if (!trees[tokenId].isListedForBreeding) {
            trees_for_breeding.push(tokenId);
            trees_for_breeding_index[tokenId] = next_tree_for_breeding_index;
            next_tree_for_breeding_index++;
        }

        trees[tokenId].isListedForBreeding = true;
        trees[tokenId].breedingPrice = breeding_price;
    }

    function select_breeding_mate(
        uint256 my_tree_token,
        uint256 mate_tree_token
    ) external whenNotPaused {
        require(
            trees[mate_tree_token].isListedForBreeding
            // ,
            // "That TREE is not listed for breeding!"
        );
        require(
            ownerOf(my_tree_token) == msg.sender
            // ,
            // "You are not the TREE owner!"
        );

        require(
            balanceOf(msg.sender) >= trees[mate_tree_token].breedingPrice
            // ,
            // "You don't have enough APPLEs to pay the breeding cost!"
        );

        // transfer APPLE payment
        APPLE(APPLE_address).approve(
            address(this),
            trees[mate_tree_token].breedingPrice
        );
        APPLE(APPLE_address).transferFrom(
            msg.sender,
            ownerOf(mate_tree_token),
            (trees[mate_tree_token].breedingPrice * (100 - breedingCommision)) /
                100
        );
        APPLE(APPLE_address).transferFrom(
            msg.sender,
            address(this),
            (trees[mate_tree_token].breedingPrice * breedingCommision) / 100
        );

        uint256 offspring_generation = 1 +
            (
                trees[mate_tree_token].gen >= trees[my_tree_token].gen
                    ? trees[mate_tree_token].gen
                    : trees[my_tree_token].gen
            );

        uint256 offspring_growth_speed = (trees[mate_tree_token].growthSpeed +
            trees[my_tree_token].growthSpeed) / 2;

        uint8 offspring_growth_strength = (trees[mate_tree_token]
            .growthStrength + trees[my_tree_token].growthStrength) / 2;

        uint256 offspring_sapling_growth_time = (trees[mate_tree_token]
            .sapling_growth_time + trees[my_tree_token].sapling_growth_time) /
            2;

        // TODO - find "average" of colors and styles...
        string memory offspring_trunk_color = TREE_helpers.averageOfColors(
            trees[mate_tree_token].trunk_color,
            trees[my_tree_token].trunk_color
        );

        string memory offspring_leaf_primary_color = TREE_helpers
            .averageOfColors(
                trees[mate_tree_token].leaf_primary_color,
                trees[my_tree_token].leaf_primary_color
            );

        string memory offspring_leaf_secondary_color = TREE_helpers
            .averageOfColors(
                trees[mate_tree_token].leaf_secondary_color,
                trees[my_tree_token].leaf_secondary_color
            );

        _safeMint(msg.sender, next_tree_token_id);

        trees[next_tree_token_id] = TreeData(
            false,
            false,
            offspring_growth_strength,
            offspring_trunk_color,
            offspring_leaf_primary_color,
            offspring_leaf_secondary_color,
            next_tree_token_id,
            block.timestamp,
            block.timestamp,
            offspring_sapling_growth_time,
            0,
            0,
            offspring_generation,
            offspring_growth_speed
        );

        next_tree_token_id++;
    }

    function cancel_breeding_listing(uint256 tokenId) external whenNotPaused {
        trees[tokenId].isListedForBreeding = false;

        // swap n' pop removal from breeding array

        uint256 old_token_for_sale_index = trees_for_breeding_index[tokenId];

        uint256 last_element_token_id = trees_for_breeding[
            next_tree_for_breeding_index
        ];

        // set last index value overwriting the element to delete
        trees_for_breeding[old_token_for_sale_index] = trees_for_breeding[
            next_tree_for_breeding_index
        ];
        trees_for_breeding_index[
            last_element_token_id
        ] = old_token_for_sale_index;

        // pop off the end
        trees_for_breeding.pop();
    }

    // In-app buying & selling of TREEs

    function list_for_sale(uint256 tokenId, uint256 sell_price)
        external
        whenNotPaused
    {
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

    function purchase(uint256 tree_token_id) external whenNotPaused {
        // address current_owner = ownerOf(tree_token_id);

        require(
            msg.sender != ownerOf(tree_token_id),
            "Can't buy your own TREE!"
        );
        require(
            trees[tree_token_id].isForSale,
            "Can't buy a TREE that isn't for sale!"
        );
        require(
            APPLE(APPLE_address).balanceOf(msg.sender) >=
                trees[tree_token_id].sellingPrice,
            "You don't have enough APPLEs to buy this TREE!"
        );

        // transfer APPLE to the seller
        APPLE(APPLE_address).approve(
            address(this),
            trees[tree_token_id].sellingPrice
        );
        APPLE(APPLE_address).transferFrom(
            msg.sender,
            ownerOf(tree_token_id),
            (trees[tree_token_id].sellingPrice * (100 - salesCommision)) / 100
        );
        APPLE(APPLE_address).transferFrom(
            msg.sender,
            address(this),
            (trees[tree_token_id].sellingPrice * salesCommision) / 100
        );

        // transfer TREE NFT to the buyer
        _transfer(ownerOf(tree_token_id), msg.sender, tree_token_id);
    }

    function cancel_for_sale(uint256 tokenId) external whenNotPaused {
        // gives approval rights back to the current owner.
        approve(ownerOf(tokenId), tokenId);

        trees[tokenId].isForSale = false;

        // swap n' pop removal from for sale array

        uint256 old_token_for_sale_index = trees_for_sale_index[tokenId];

        uint256 last_element_token_id = trees_for_sale[
            next_tree_for_sale_index
        ];

        // set last index value overwriting the element to delete
        trees_for_sale[old_token_for_sale_index] = trees_for_sale[
            next_tree_for_sale_index
        ];
        trees_for_sale_index[last_element_token_id] = old_token_for_sale_index;

        // pop off the end
        trees_for_sale.pop();
    }

    // admin functions
    function list_gen_zero(
        uint256 listingPrice,
        uint256 growthSpeed,
        uint8 growthStrength,
        uint256 sapling_growth_time,
        string memory trunk_color,
        string memory leaf_primary_color,
        string memory leaf_secondary_color
    ) external onlyOwner {
        require(
            gen_zeros_minted < gen_zeros_max_supply,
            "The max number of gen zero TREEs have been minted!"
        );

        _safeMint(address(this), next_tree_token_id);

        trees[next_tree_token_id] = TreeData(
            true,
            false,
            growthStrength,
            trunk_color,
            leaf_primary_color,
            leaf_secondary_color,
            next_tree_token_id,
            block.timestamp,
            block.timestamp,
            sapling_growth_time,
            listingPrice,
            0,
            0,
            growthSpeed
        );

        trees_for_sale.push(next_tree_token_id);

        next_tree_token_id++;
    }

    function update_APPLE_address(address newTreeAddress) external onlyOwner {
        APPLE_address = newTreeAddress;
    }

    // function tokenURI(uint256 tokenId)
    //     public
    //     view
    //     override(ERC721)
    //     returns (string memory)
    // {
    //     string memory json = Base64.encode(
    //         bytes(
    //             string(
    //                 abi.encodePacked(
    //                     '{"name": "',
    //                     "NAME",
    //                     '",',
    //                     '"image_data": "',
    //                     TREE_helpers.getSvg("brown"),
    //                     '",',
    //                     '"attributes": [{"trait_type": "Speed", "value": ',
    //                     TREE_helpers.uint2str(42),
    //                     "},",
    //                     '{"trait_type": "Attack", "value": ',
    //                     TREE_helpers.uint2str(55),
    //                     "},",
    //                     '{"trait_type": "Defence", "value": ',
    //                     TREE_helpers.uint2str(1000),
    //                     "},",
    //                     '{"trait_type": "Growth Strength", "value": ',
    //                     TREE_helpers.uint2str(trees[tokenId].growthStrength),
    //                     "},",
    //                     '{"trait_type": "Growth Speed", "value": ',
    //                     TREE_helpers.uint2str(trees[tokenId].growthSpeed),
    //                     "},",
    //                     '{"trait_type": "Sapling Growth Time", "value": ',
    //                     TREE_helpers.uint2str(
    //                         trees[tokenId].sapling_growth_time
    //                     ),
    //                     "},",
    //                     '{"trait_type": "Leaves Color", "value": "',
    //                     trees[tokenId].leaves_color,
    //                     '"}',
    //                     '{"trait_type": "Trunk Color", "value": "',
    //                     trees[tokenId].trunk_color,
    //                     '"}',
    //                     "]}"
    //                 )
    //             )
    //         )
    //     );
    //     return string(abi.encodePacked("data:application/json;base64,", json));
    // }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        "TREE #",
                        TREE_helpers.uint2str(tokenId),
                        '",',
                        '"image_data": "',
                        TREE_helpers.getSvg(
                            trees[tokenId].trunk_color,
                            trees[tokenId].leaf_primary_color,
                            trees[tokenId].leaf_secondary_color
                        ),
                        '",',
                        '"description": "A nice little description...",',
                        '"attributes": [',
                        '{"trait_type": "Growth Strength", "value": ',
                        TREE_helpers.uint2str(trees[tokenId].growthStrength),
                        "},",
                        '{"trait_type": "Growth Speed", "value": ',
                        TREE_helpers.uint2str(trees[tokenId].growthSpeed),
                        "},",
                        '{"trait_type": "Sapling Growth Time", "value": ',
                        TREE_helpers.uint2str(
                            trees[tokenId].sapling_growth_time
                        ),
                        "},",
                        '{"display_type": "date", "trait_type": "Birthday", "value": ',
                        TREE_helpers.uint2str(
                            trees[tokenId].birthday_timestamp
                        ),
                        "},",
                        '{"display_type": "date", "trait_type": "Last Picked APPLE", "value": ',
                        TREE_helpers.uint2str(
                            trees[tokenId].last_picked_apple_timestamp
                        ),
                        "},",
                        '{"display_type": "number", "trait_type": "Generation", "value": "',
                        TREE_helpers.uint2str(trees[tokenId].gen),
                        '"},',
                        '{"trait_type": "Trunk", "value": "',
                        trees[tokenId].trunk_color,
                        '"},',
                        '{"trait_type": "Leaf Primary", "value": "',
                        trees[tokenId].leaf_primary_color,
                        '"},',
                        '{"trait_type": "Leaf Secondary", "value": "',
                        trees[tokenId].leaf_secondary_color,
                        '"}', // no comma here
                        "]}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    // function getTreesForSale() external view returns (uint256[] memory) {
    //     return trees_for_sale;
    // }

    // function getTreesListedForBreeding()
    //     external
    //     view
    //     returns (uint256[] memory)
    // {
    //     return trees_for_breeding;
    // }
}
