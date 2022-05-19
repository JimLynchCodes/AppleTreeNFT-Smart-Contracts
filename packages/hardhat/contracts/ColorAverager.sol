// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

library ColorAverager {

    function averageColors(string memory color_a, string memory color_b) public pure returns (string memory) {

        uint256[3] memory color_a_rgb = [
            convertString(substring(color_a,1,3)),
            convertString(substring(color_a,3,5)),
            convertString(substring(color_a,5,7))
        ];

        uint256[3] memory color_b_rgb = [
            convertString(substring(color_b,1,3)),
            convertString(substring(color_b,3,5)),
            convertString(substring(color_b,5,7))
        ];

        uint256[3] memory avg_rgb = [
            ((color_a_rgb[0] + color_b_rgb[0]) / 2),
            ((color_a_rgb[1] + color_b_rgb[1]) / 2),
            ((color_a_rgb[2] + color_b_rgb[2]) / 2)
        ];

        return string(
            abi.encodePacked(
                "#",
                uintToHexString(avg_rgb[0]),
                uintToHexString(avg_rgb[1]),
                uintToHexString(avg_rgb[2])
            )
        );

    }

    function uintToHexString(uint i) internal pure returns (string memory) {
        if (i == 0) return "00";
        if (i < 10) return string(abi.encodePacked("0", Strings.toString(i)));
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j = j >> 4;
        }
        uint mask = 15;
        bytes memory bstr = new bytes(length);
        uint k = length;
        while (i != 0) {
            uint curr = (i & mask);
            bstr[--k] = curr > 9 ?
                bytes1(uint8(55 + curr)) :
                bytes1(uint8(48 + curr)); // 55 = 65 - 10
            i = i >> 4;
        }
        return string(bstr);
    }

    function convertString(string memory str) internal pure returns (uint256 value) {

        bytes memory b = bytes(str);
        uint256 number = 0;
        for(uint i=0;i<b.length;i++){
            number = number << 4; // or number = number * 16
            number += numberFromAscII(b[i]);
        }
        return number;
    }
    
    function numberFromAscII(bytes1 b) internal pure returns (uint8 value) {
        if (b>="0" && b<="9") {
            return uint8(b) - uint8(bytes1("0"));
        } else if (b>="A" && b<="F") {
            return 10 + uint8(b) - uint8(bytes1("A"));
        } else if (b>="a" && b<="f") {
            return 10 + uint8(b) - uint8(bytes1("a"));
        }
        return uint8(b); // or return error ...
    }

    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

}