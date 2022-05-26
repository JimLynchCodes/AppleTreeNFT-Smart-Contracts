// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9.0;

import "./APPLE.sol";
import "hardhat/console.sol";

import "abdk-libraries-solidity/ABDKMath64x64.sol";

library Other_helpers {
    uint256 constant floor = 10;
    uint256 constant percentage_factor = 5;

    function min_breeding_price(
        uint256 supply_of_apples,
        uint256 supply_of_trees
    ) public pure returns (uint256) {
        // =$C$2+SQRT(H$5)*$G$2*SQRT($C13)

        return
            ABDKMath64x64.toUInt(
                ABDKMath64x64.add(
                    ABDKMath64x64.fromUInt(floor),
                    ABDKMath64x64.mul(
                        ABDKMath64x64.mul(
                            ABDKMath64x64.sqrt(
                                ABDKMath64x64.fromUInt(supply_of_trees)
                            ),
                            ABDKMath64x64.sqrt(
                                ABDKMath64x64.fromUInt(supply_of_apples)
                            )
                        ),
                        ABDKMath64x64.divu(percentage_factor, 100)
                    )
                )
            );
    }

    // return ABDKMath64x64.toUInt(
    //         ABDKMath64x64.mul(
    //             ABDKMath64x64.div(
    //                 ABDKMath64x64.pow(ABDKMath64x64.fromUInt(supply_of_trees), 2),
    //                 ABDKMath64x64.add(ABDKMath64x64.pow(ABDKMath64x64.fromUInt(supply_of_trees), 2),ABDKMath64x64.fromUInt(10000000))
    //             ),
    //             ABDKMath64x64.sqrt(ABDKMath64x64.fromUInt(supply_of_apples))
    //         )
    //     );
}
