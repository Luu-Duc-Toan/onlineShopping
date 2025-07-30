// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/CollateralManagerTestBase.sol";
import "forge-std/console.sol";

contract GetRequiredSellerCollateralTest is CollateralManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testGetRequiredSellerCollateralCalculation() public view {
        uint price = 1000;
        uint quantity = 2;
        uint expected = (price * quantity * collateralPercent + 99) / 100;

        uint result = collateralManager.getRequiredSellerCollateral(
            price,
            quantity
        );
        assertEq(result, expected);
    }

    function testGetRequiredSellerCollateralZeroPrice() public {
        vm.expectRevert("Invalid price");
        collateralManager.getRequiredSellerCollateral(0, 5);
    }

    function testGetRequiredSellerCollateralZeroQuantity() public {
        vm.expectRevert("Invalid quantity");
        collateralManager.getRequiredSellerCollateral(1000, 0);
    }

    function testFuzzGetRequiredSellerCollateral(
        uint256 price,
        uint256 quantity
    ) public view {
        vm.assume(price > 0 && price < type(uint120).max);
        vm.assume(quantity > 0 && quantity < type(uint120).max);

        uint expected = (price * quantity * collateralPercent + 99) / 100;
        uint result = collateralManager.getRequiredSellerCollateral(
            price,
            quantity
        );
        assertEq(result, expected);
    }
}
