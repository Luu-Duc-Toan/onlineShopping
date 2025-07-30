// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/CollateralManagerTestBase.sol";

contract IsEnoughProductCollateralTest is CollateralManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testIsEnoughProductCollateralTrue() public {
        uint requiredCollateral = collateralManager.getRequiredSellerCollateral(
            price,
            quantity
        );

        vm.prank(seller1);
        collateralManager.addProductCollateral{value: requiredCollateral}(
            product
        );
        bool result = collateralManager.isEnoughProductCollateral(
            product,
            price,
            quantity
        );

        assertTrue(result);
    }

    function testIsEnoughProductCollateralFalse() public {
        uint requiredCollateral = collateralManager.getRequiredSellerCollateral(
            price,
            quantity
        );
        uint insufficientCollateral = requiredCollateral - 1;

        vm.prank(seller1);
        collateralManager.addProductCollateral{value: insufficientCollateral}(
            product
        );
        bool result = collateralManager.isEnoughProductCollateral(
            product,
            price,
            quantity
        );

        assertFalse(result);
    }

    function testIsEnoughProductCollateralExcessAmount() public {
        uint requiredCollateral = collateralManager.getRequiredSellerCollateral(
            price,
            quantity
        );
        uint excessCollateral = requiredCollateral + amount;

        vm.prank(seller1);
        collateralManager.addProductCollateral{value: excessCollateral}(
            product
        );
        bool result = collateralManager.isEnoughProductCollateral(
            product,
            price,
            quantity
        );

        assertTrue(result);
    }

    function testIsEnoughProductCollateralZeroQuantity() public {
        vm.expectRevert("Invalid quantity");
        bool result = collateralManager.isEnoughProductCollateral(
            product,
            price,
            0
        );

        assertTrue(!result);
    }

    function testIsEnoughProductCollateralZeroPrice() public {
        vm.expectRevert("Invalid price");
        bool result = collateralManager.isEnoughProductCollateral(
            product,
            0,
            quantity
        );

        assertTrue(!result);
    }

    function testIsEnoughProductCollateralNoCollateralAdded() public view {
        bool result = collateralManager.isEnoughProductCollateral(
            product,
            price,
            quantity
        );
        assertFalse(result);
    }

    function testFuzzIsEnoughProductCollateral(
        uint256 _price,
        uint256 _quantity
    ) public {
        vm.assume(_price > 0 && _price < type(uint120).max);
        vm.assume(_quantity > 0 && _quantity < type(uint120).max);

        uint requiredCollateral = collateralManager.getRequiredSellerCollateral(
            _price,
            _quantity
        );

        vm.deal(seller1, requiredCollateral + 1 ether);
        vm.prank(seller1);
        collateralManager.addProductCollateral{value: requiredCollateral}(
            product
        );

        bool result = collateralManager.isEnoughProductCollateral(
            product,
            _price,
            _quantity
        );

        assertTrue(result);
    }
}
