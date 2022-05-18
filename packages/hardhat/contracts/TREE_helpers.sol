// SPDX-License-Identifier: MIT

import "./APPLE.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

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
        string[3] memory parts;

        parts[0] = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><!-- License: PD. Made by gmgeo: https://github.com/gmgeo/osmic --><svg   xmlns:dc="http://purl.org/dc/elements/1.1/"   xmlns:cc="http://creativecommons.org/ns#"   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"   xmlns:svg="http://www.w3.org/2000/svg"   xmlns="http://www.w3.org/2000/svg"   version="1.1"   width="100%"   height="100%"   viewBox="0 0 14 14"   id="svg2">  <metadata     id="metadata8">    <rdf:RDF>      <cc:Work         rdf:about="">        <dc:format>image/svg+xml</dc:format>        <dc:type           rdf:resource="http://purl.org/dc/dcmitype/StillImage" />        <dc:title></dc:title>      </cc:Work>    </rdf:RDF>  </metadata>  <defs     id="defs6" />  <rect     width="14"     height="14"     x="0"     y="0"     id="canvas"     style="fill:none;stroke:none;visibility:hidden" />  <path     d="m 7.75,14 0,-3 L 9,11 C 11.524338,11 12.545311,7.5 10,6.5 11.496636,5.5 11,3 9,2.75 9,2.75 9,1 7,1 5,1 5,2.75 5,2.75 3,3 2.4614171,5.5 4,6.5 1.4966359,7.5 2.4966359,11 5,11 l 1.25,0 0,3 z"     id="tree-deciduous"     style="fill:';
        parts[1] = trunk_color;
        parts[2] = ';fill-opacity:1;stroke:none" /></svg>';

        return
            string(
                abi.encodePacked(
                    parts[0],
                    parts[1],
                    parts[2]
                )
            );
    }
}
