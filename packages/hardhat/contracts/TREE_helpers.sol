// SPDX-License-Identifier: MIT

import "./APPLE.sol";

pragma solidity ^0.8.0;

library TREE_helpers {
    function apples_to_mint_calculation(
        uint256 birthday_timestamp,
        uint256 growthStrength,
        address APPLE_address
    ) public view returns (uint256) {
        uint256 age_ms = block.timestamp - birthday_timestamp;

        return
            growthStrength *
            (age_ms**2 /
                (age_ms**2 +
                    APPLE(APPLE_address).get_nutrition_score(msg.sender)));
    }

    // handling images on chain
    function getSvg(uint256 tokenId, string memory trunk_color)
        internal
        pure
        returns (string memory)
    {
        string[5] memory parts;
        parts[0] = "<svg viewBox='0 0 350 350'><style>.a { fill: ";
        parts[1] = trunk_color;
        parts[
            2
        ] = "; font-size: 18px; }</style><text x='10' y='10' class='a'>Token #";
        parts[3] = Strings.toString(tokenId);
        parts[4] = "</text></svg>";

        return
            string(
                abi.encodePacked(
                    parts[0],
                    parts[1],
                    parts[2],
                    parts[3],
                    parts[4]
                )
            );
    }
}
