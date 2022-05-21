// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

import "./APPLE.sol";
import "hardhat/console.sol";

import "abdk-libraries-solidity/ABDKMath64x64.sol";

library Other_helpers {

    function min_breeding_price(uint256 supply_of_apples, uint256 supply_of_trees) public pure returns (uint256) {
        
        return ABDKMath64x64.toUInt(
                ABDKMath64x64.mul(
                    ABDKMath64x64.div(
                        ABDKMath64x64.pow(ABDKMath64x64.fromUInt(supply_of_trees), 2),
                        ABDKMath64x64.add(ABDKMath64x64.pow(ABDKMath64x64.fromUInt(supply_of_trees), 2),ABDKMath64x64.fromUInt(10000000))
                    ),
                    ABDKMath64x64.sqrt(ABDKMath64x64.fromUInt(supply_of_apples))   
                )
            );
    }

}
