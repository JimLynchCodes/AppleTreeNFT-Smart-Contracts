pragma solidity >=0.8.13 <0.9.0;
//SPDX-License-Identifier: MIT

import "./APPLE.sol";
import "./Base64.sol";
import "./TreeHelpers.sol";
import "./BreedingHelpers.sol";
import "./ColorAverager.sol";

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract TREE is ERC721, ERC721Holder, Ownable, Pausable {
    uint256 public constant salesCommision = 2;
    uint256 public constant breedingCommision = 20;

    uint8 public constant salesBurnPercentage = 25;
    uint8 public constant breedingBurnPercentage = 50;

    uint8 public constant MIN_STRENGTH = 1;
    uint8 public constant MAX_STRENGTH = 10;

    uint16 public constant gen_zeros_max_supply = 10000; // 8 bytes, max value 65535

    address public APPLE_address;

    uint256 public constant MIN_GROWTH_SPEED = 72000; // 20 hours in seconds
    uint256 public constant MAX_GROWTH_SPEED = 1814400; // 3 weeks in seconds

    // TODO - choose a good time for this...
    uint256 public constant MIN_SAPLING_GROWN_TIME = 0;
    uint256 public constant MAX_SAPLING_GROWN_TIME = 60480000000000000; // 1 month in seconds

    uint256 public constant BREEDING_COOLDOWN = 604800; // 1 week in s

    uint256 public gen_zeros_minted;

    uint256 public next_tree_for_sale_index;
    uint256 public next_tree_for_breeding_index;
    uint256 public next_tree_token_id = 1;

    // tokenId => for_sale_index
    mapping(uint256 => uint256) trees_for_sale_index;

    // tokenId => for_sale_index
    mapping(uint256 => uint256) trees_for_breeding_index;

    mapping(uint256 => TreeData) trees;

    // uses tree index
    uint256[] trees_for_sale;

    // uses tree index
    uint256[] trees_for_breeding;

    struct TreeData {
        bool isForSale; // 1 byte
        bool isListedForBreeding; // 1 byte
        uint8 growthStrength; // 1 byte    // min value: 1, max value: 10
        string trunk_color; // 1 byte per char
        string leaf_primary_color; // 1 byte per char
        string leaf_secondary_color; // 1 byte per char
        uint256 gen; // 32 bytes
        uint256 growthSpeed; // 32 bytes  // min value, 6 hours - max value - 7 days
        uint256 sapling_growth_time; // 32 bytes
        uint256 tokenId; // 32 bytes
        uint256 birthday_timestamp; // 32 bytes
        uint256 last_picked_apple_timestamp; // 32 bytes
        uint256 last_breeding_time; // 32 bytes
        uint256 sellingPrice; // 32 bytes
        uint256 breedingPrice; // 32 bytes
        uint256 parent_a;
        uint256 parent_b;
    }

    constructor(address _APPLE_address)
        ERC721("APPLE TREE v0.3", "APPLE_TREE_V_3")
    {
        APPLE_address = _APPLE_address;
    }

    function pick_APPLEs(uint256 tree_token_id) external whenNotPaused {
        require(
            msg.sender == ownerOf(tree_token_id),
            "You are not the TREE owner!"
        );

        require(
            block.timestamp >
                (trees[tree_token_id].birthday_timestamp +
                    trees[tree_token_id].sapling_growth_time),
            "TREE is a wee sapling!"
        );

        require(
            block.timestamp >
                (trees[tree_token_id].last_picked_apple_timestamp +
                    trees[tree_token_id].growthSpeed),
            "The APPLE on this TREE is not done growing yet!"
        );

        trees[tree_token_id].last_picked_apple_timestamp = block.timestamp;

        APPLE(APPLE_address).mint(
            msg.sender,
            TreeHelpers.apples_to_mint_calculation(
                trees[tree_token_id].birthday_timestamp,
                trees[tree_token_id].growthStrength,
                APPLE(APPLE_address).decimals(),
                APPLE(APPLE_address).get_nutrition_score(msg.sender)
            )
        );
    }

    // breeding of TREEs
    function list_for_breeding(uint256 tokenId, uint256 breeding_price)
        external
        whenNotPaused
    {
        require(
            ownerOf(tokenId) == msg.sender,
            "Only the owner can call this function"
        );

        require(
            block.timestamp >=
                trees[tokenId].last_breeding_time + BREEDING_COOLDOWN,
            "Breeding cooldown has not finshed yet"
        );

        require(
            !trees[tokenId].isListedForBreeding,
            "This tree is already listed for breeding!"
        );

        require(
            breeding_price >=
                BreedingHelpers.min_breeding_price(
                    APPLE(APPLE_address).totalSupply(),
                    next_tree_token_id,
                    18
                ),
            "Price is less than min breeding price"
        );

        if (!trees[tokenId].isListedForBreeding) {
            trees_for_breeding.push(tokenId);
            trees_for_breeding_index[tokenId] = next_tree_for_breeding_index;
            next_tree_for_breeding_index++;
        }

        trees[tokenId].isListedForBreeding = true;
        trees[tokenId].breedingPrice = breeding_price;
    }

    function select_breeding_mate_calcs_simpler(
        uint256 my_tree_token,
        uint256 mate_tree_token
    )
        external
        view
        whenNotPaused
        returns (uint256 breeding_price, uint256 _breeding_commision)
    {
        return (trees[mate_tree_token].breedingPrice, breedingCommision);
    }

    function select_breeding_mate_calcs(
        uint256 my_tree_token,
        uint256 mate_tree_token
    )
        external
        view
        whenNotPaused
        returns (
            uint256 breeding_price,
            uint256 transfer_to_mate_owner_amount,
            uint256 transfer_to_contract_amount
        )
    {
        return (
            trees[mate_tree_token].breedingPrice,
            ((trees[mate_tree_token].breedingPrice *
                (100 - breedingCommision)) / 100),
            ((trees[mate_tree_token].breedingPrice * breedingCommision) / 100)
        );
    }

    function select_breeding_mate(
        uint256 my_tree_token,
        uint256 mate_tree_token
    ) external whenNotPaused {
        require(
            trees[mate_tree_token].isListedForBreeding,
            "That TREE is not listed for breeding!"
        );

        require(
            block.timestamp >=
                trees[my_tree_token].last_breeding_time + BREEDING_COOLDOWN,
            "Breeding cooldown has not expire yet"
        );

        require(
            ownerOf(my_tree_token) == msg.sender,
            "You are not the TREE owner!"
        );

        require(
            my_tree_token != mate_tree_token,
            "Cannot breed a tree with itself!"
        );

        require(
            APPLE(APPLE_address).balanceOf(msg.sender) >=
                trees[mate_tree_token].breedingPrice,
            "You don't have enough APPLEs to pay the breeding cost!"
        );

        // Assumes already approved this contract to take the correct amount of APPLE

        APPLE(APPLE_address).transferFrom(
            ownerOf(my_tree_token),
            address(this),
            (trees[mate_tree_token].breedingPrice * breedingCommision) / 100
        );

        APPLE(APPLE_address).transferFrom(
            ownerOf(my_tree_token),
            ownerOf(mate_tree_token),
            ((trees[mate_tree_token].breedingPrice *
                (100 - breedingCommision)) / 100)
        );

        uint256 offspring_generation = 1 +
            uint256(
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

        string memory offspring_trunk_color = ColorAverager.averageColors(
            trees[mate_tree_token].trunk_color,
            trees[my_tree_token].trunk_color
        );

        string memory offspring_leaf_primary_color = ColorAverager
            .averageColors(
                trees[mate_tree_token].leaf_primary_color,
                trees[my_tree_token].leaf_primary_color
            );

        string memory offspring_leaf_secondary_color = ColorAverager
            .averageColors(
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
            offspring_generation,
            offspring_growth_speed,
            offspring_sapling_growth_time,
            next_tree_token_id,
            block.timestamp,
            (block.timestamp - offspring_growth_speed),
            (block.timestamp - BREEDING_COOLDOWN),
            0,
            0,
            mate_tree_token,
            my_tree_token
        );

        cancel_breeding_listing(mate_tree_token);

        next_tree_token_id++;
    }

    function cancel_breeding_listing(uint256 tokenId) public whenNotPaused {
        trees[tokenId].isListedForBreeding = false;

        // swap n' pop removal from breeding array

        uint256 old_token_for_sale_index = trees_for_breeding_index[tokenId];

        uint256 last_element_token_id = trees_for_breeding[
            next_tree_for_breeding_index - 1
        ];

        // set last index value overwriting the element to delete
        trees_for_breeding[old_token_for_sale_index] = trees_for_breeding[
            next_tree_for_breeding_index - 1
        ];

        trees_for_breeding_index[
            last_element_token_id
        ] = old_token_for_sale_index;

        // pop off the end
        trees_for_breeding.pop();

        next_tree_for_breeding_index--;
    }

    function list_for_sale(uint256 tokenId, uint256 sell_price)
        external
        whenNotPaused
    {
        require(
            ownerOf(tokenId) == msg.sender,
            "Only the Tree owner can list it for sale!"
        );

        require(
            !trees[tokenId].isForSale,
            "This tree is already listed for sale!"
        );

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

        // Assumed already asked APPLE contract to transfer apples from buyer

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

        cancel_for_sale(tree_token_id);

        // transfer TREE NFT to the buyer
        _transfer(ownerOf(tree_token_id), msg.sender, tree_token_id);
    }

    function cancel_for_sale(uint256 tokenId) public whenNotPaused {
        // gives approval rights back to the current owner.
        trees[tokenId].isForSale = false;

        // swap n' pop removal from for sale array

        uint256 old_token_for_sale_index = trees_for_sale_index[tokenId];

        uint256 last_element_token_id = trees_for_sale[
            next_tree_for_sale_index - 1
        ];

        // set last index value overwriting the element to delete
        trees_for_sale[old_token_for_sale_index] = trees_for_sale[
            next_tree_for_sale_index - 1
        ];

        // update the map keeping track of indexes
        trees_for_sale_index[last_element_token_id] = old_token_for_sale_index;

        // pop off the end
        trees_for_sale.pop();

        next_tree_for_sale_index--;
    }

    // admin functions
    function list_gen_zero(
        bool listForSale,
        uint256 listingPrice,
        uint256 growthSpeed,
        uint8 growthStrength,
        uint256 sapling_growth_time,
        string memory trunk_color,
        string memory leaf_primary_color,
        string memory leaf_secondary_color,
        address beneficiary
    ) external onlyOwner {
        require(
            gen_zeros_minted < gen_zeros_max_supply,
            "The max number of gen zero TREEs have been minted!"
        );

        require(growthSpeed <= MAX_GROWTH_SPEED, "growthSpeed too high");

        require(growthSpeed >= MIN_GROWTH_SPEED, "growthSpeed too low");

        require(growthStrength <= MAX_STRENGTH, "growthStrength too high");
        require(growthStrength >= MIN_STRENGTH, "growthStrength too low");

        require(
            sapling_growth_time >= MIN_SAPLING_GROWN_TIME,
            "sapling time too low"
        );

        require(
            sapling_growth_time <= MAX_SAPLING_GROWN_TIME,
            "sapling time too high"
        );

        _safeMint(beneficiary, next_tree_token_id);

        trees[next_tree_token_id] = TreeData(
            listForSale,
            false,
            growthStrength,
            trunk_color,
            leaf_primary_color,
            leaf_secondary_color,
            0,
            growthSpeed,
            sapling_growth_time,
            next_tree_token_id,
            block.timestamp,
            (block.timestamp - growthSpeed),
            (block.timestamp - BREEDING_COOLDOWN),
            listingPrice,
            0,
            uint256(0),
            uint256(0)
        );

        if (listForSale) {
            trees_for_sale.push(next_tree_token_id);

            trees_for_sale_index[next_tree_token_id] = next_tree_for_sale_index;
            next_tree_for_sale_index++;
        }

        next_tree_token_id++;
        gen_zeros_minted++;
    }

    function update_APPLE_address(address newTreeAddress) external onlyOwner {
        APPLE_address = newTreeAddress;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        // string memory json = Base64.encode(
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "',
                                    "TREE: #",
                                    TreeHelpers.uintToString(tokenId),
                                    '",',
                                    '"image_data": "',
                                    TreeHelpers.getSvg(
                                        trees[tokenId].trunk_color,
                                        trees[tokenId].leaf_primary_color,
                                        trees[tokenId].leaf_secondary_color
                                    ),
                                    '","attributes": [',
                                    '{"trait_type": "Growth Strength", "value": ',
                                    TreeHelpers.uintToString(
                                        trees[tokenId].growthStrength
                                    ),
                                    "},",
                                    '{"trait_type": "Growth Speed (seconds)", "value": ',
                                    TreeHelpers.uintToString(
                                        trees[tokenId].growthSpeed
                                    ),
                                    "},",
                                    '{"trait_type": "Sapling Growth Time (seconds)", "value": ',
                                    TreeHelpers.uintToString(
                                        trees[tokenId].sapling_growth_time
                                    ),
                                    '},{"display_type": "date", "trait_type": "Birthday", "value": ',
                                    TreeHelpers.uintToString(
                                        trees[tokenId].birthday_timestamp
                                    ),
                                    '},{"display_type": "date", "trait_type": "Last Picked APPLE", "value": ',
                                    TreeHelpers.uintToString(
                                        trees[tokenId]
                                            .last_picked_apple_timestamp
                                    ),
                                    '},{"display_type": "date", "trait_type": "Last Breeding", "value": ',
                                    TreeHelpers.uintToString(
                                        trees[tokenId].last_breeding_time
                                    ),
                                    '},{"display_type": "number", "trait_type": "Generation", "value": "',
                                    TreeHelpers.uintToString(
                                        trees[tokenId].gen
                                    ),
                                    '"},{"trait_type": "Trunk", "value": "',
                                    trees[tokenId].trunk_color,
                                    '"},{"trait_type": "Leaf Primary", "value": "',
                                    trees[tokenId].leaf_primary_color,
                                    '"},{"trait_type": "Leaf Secondary", "value": "',
                                    trees[tokenId].leaf_secondary_color,
                                    '"}', // no comma here
                                    "]}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function getTreesForSale() external view returns (uint256[] memory) {
        return trees_for_sale;
    }

    function getTreesListedForBreeding()
        external
        view
        returns (uint256[] memory)
    {
        return trees_for_breeding;
    }

    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `safetransfer`. This function MAY throw to revert and reject the
    ///  transfer. This function MUST use 50,000 gas or less. Return of other
    ///  than the magic value MUST result in the transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _from The sending address
    /// @param _tokenId The NFT identifier which is being transfered
    /// @param _data Additional data with no specified format
    /// @return
    // `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    function onERC721Received(
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public returns (bytes4) {
        if (trees[_tokenId].isListedForBreeding)
            cancel_breeding_listing(_tokenId);
        if (trees[_tokenId].isForSale) cancel_for_sale(_tokenId);

        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function withdraw_apple(uint8 amount) public onlyOwner {
        APPLE(APPLE_address).transfer(owner(), amount);
    }
}
