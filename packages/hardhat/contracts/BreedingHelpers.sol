// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

import "./APPLE.sol";
import "hardhat/console.sol";

import "abdk-libraries-solidity/ABDKMath64x64.sol";

library BreedingHelpers {
    uint256 constant floor = 10;
    uint256 constant percentage_factor = 5;

    function min_breeding_price(
        uint256 supply_of_apples,
        uint256 supply_of_trees,
        uint256 appleDecimals
    ) public pure returns (uint256) {
        return
            floor *
            10**appleDecimals +
            ((10**appleDecimals *
                sqrt(supply_of_apples) *
                sqrt(supply_of_trees)) * percentage_factor) /
            100;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
