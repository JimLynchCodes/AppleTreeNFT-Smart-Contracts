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

    uint256 gen_zeros_minted;
    uint256 constant gen_zeros_max_supply = 10000;

    uint8 constant salesCommision = 2;
    uint8 constant breedingCommision = 2;

    uint256 next_tree_for_sale_index;
    uint256 next_tree_for_breeding_index;
    // uses tree index
    uint256[] public trees_for_sale;

    // uses tree index
    uint256[] public trees_for_breeding;

    uint256 next_tree_token_id = 1;

    // tokenId => for_sale_index
    mapping(uint256 => uint256) trees_for_sale_index;

    // tokenId => for_sale_index
    mapping(uint256 => uint256) trees_for_breeding_index;

    struct TreeData {
        bool isForSale;
        bool isListedForBreeding;
        uint256 tokenId;
        uint256 birthday_timestamp;
        uint256 last_picked_apple_timestamp;
        uint256 sapling_growth_time;
        uint256 sellingPrice;
        uint256 breedingPrice;
        uint256 gen;
        uint256 growthSpeed;
        uint256 growthStrength;
        string trunk_color;
        string trunk_style;
        string leaves_color;
        string leaves_style;
    }

    mapping(uint256 => TreeData) trees;

    constructor() ERC721("Trees2", "TREE2") {
        // Do nothing on delpoy...
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

        uint256 offspring_generation = 1 + trees[mate_tree_token].gen >=
            trees[my_tree_token].gen
            ? trees[mate_tree_token].gen
            : trees[my_tree_token].gen;
        uint256 offspring_growth_speed = (trees[mate_tree_token].growthSpeed +
            trees[my_tree_token].growthSpeed) / 2;
        uint256 offspring_growth_strength = (trees[mate_tree_token]
            .growthStrength + trees[my_tree_token].growthStrength) / 2;
        uint256 offspring_sapling_growth_time = (trees[mate_tree_token]
            .sapling_growth_time + trees[my_tree_token].sapling_growth_time) /
            2;

        // TODO - find "average" of colors and styles...
        string memory offspring_trunk_color = trees[mate_tree_token]
            .trunk_color;
        string memory offspring_trunk_style = trees[mate_tree_token]
            .trunk_style;
        string memory offspring_leaves_color = trees[mate_tree_token]
            .leaves_color;
        string memory offspring_leaves_style = trees[mate_tree_token]
            .leaves_style;

        _safeMint(msg.sender, next_tree_token_id);

        trees[next_tree_token_id] = TreeData(
            false,
            false,
            next_tree_token_id,
            block.timestamp,
            block.timestamp,
            offspring_sapling_growth_time,
            0,
            0,
            offspring_generation,
            offspring_growth_speed,
            offspring_growth_strength,
            offspring_trunk_color,
            offspring_trunk_style,
            offspring_leaves_color,
            offspring_leaves_style
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

        require(msg.sender != ownerOf(tree_token_id), "Can't buy your own TREE!");
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
        uint256 growthStrength,
        uint256 sapling_growth_time,
        string memory trunk_color,
        string memory trunk_style,
        string memory leaves_color,
        string memory leaves_style
    ) external onlyOwner {
        require(
            gen_zeros_minted < gen_zeros_max_supply,
            "The max number of gen zero TREEs have been minted!"
        );

        _safeMint(address(this), next_tree_token_id);

        trees[next_tree_token_id] = TreeData(
            true,
            false,
            next_tree_token_id,
            block.timestamp,
            block.timestamp,
            sapling_growth_time,
            listingPrice,
            0,
            0,
            growthSpeed,
            growthStrength,
            trunk_color,
            trunk_style,
            leaves_color,
            leaves_style
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
    //     override
    //     returns (string memory)
    // {
    //     // string memory json = 

    //     return string(abi.encodePacked("data:application/json;base64,", Base64.encode(
    //         bytes(
    //             string(
    //                 abi.encodePacked(
    //                     "{",
    //                     '"name": "TREEEE",',
    //                     '"description": "Some interesting description...",',
    //                     '"image_data": "',
    //                     TREE_helpers.getSvg(trees[tokenId].trunk_color),
    //                     '"',
    //                     // '"attributes": [{',
    //                     // '"birthday": ',
    //                     // Strings.toString(trees[tokenId].birthday_timestamp),
    //                     // // trees[tokenId].birthday_timestamp,
    //                     // "},{",
    //                     // '"last picked": ',
    //                     // Strings.toString(
    //                     //     trees[tokenId].last_picked_apple_timestamp
    //                     // ),
    //                     // "},{",
    //                     // '"generation": ',
    //                     // Strings.toString(
    //                     //     trees[tokenId].gen
    //                     //     ),
    //                     // "},{",
    //                     // '"growth speed": ',
    //                     // Strings.toString(
    //                     //     trees[tokenId].growthSpeed
    //                     //     ),
    //                     // "},{",
    //                     // '"growth strength": ',
    //                     // Strings.toString(
    //                     //     trees[tokenId].growthStrength
    //                     //     ),
    //                     // "},{",
    //                     // '"trunk color": "',
    //                     // trees[tokenId].trunk_color,
    //                     // '"},{',
    //                     // '"trunk style": "',
    //                     // trees[tokenId].trunk_style,
    //                     // '"},{',
    //                     // '"leaves color": "',
    //                     // trees[tokenId].leaves_color,
    //                     // '"},{',
    //                     // '"leaves style": "',
    //                     // trees[tokenId].leaves_style,
    //                     // '"',
    //                     // "}]",
    //                     "}"
    //                 )
    //             )
    //         )
    //     )));
    // }

    function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {
        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "', "NAME", '",',
                    '"image_data": "', 
                    TREE_helpers.getSvg("brown"), 
                    '",',
                    '"attributes": [{"trait_type": "Speed", "value": ', TREE_helpers.uint2str(42), '},',
                    '{"trait_type": "Attack", "value": ', TREE_helpers.uint2str(55), '},',
                    '{"trait_type": "Defence", "value": ', TREE_helpers.uint2str(1000), '},',
                    '{"trait_type": "Material", "value": "', "Foo", '"}',
                    ']}'
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
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
