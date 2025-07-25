// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ProductManagerTestBase} from "./ProductManagerTestBase.sol";

/**
 * @title ProductManagerUpdateQuantityTest
 * @dev Tests for the updateQuantities functionality
 */
contract ProductManagerUpdateQuantityTest is ProductManagerTestBase {
    /*//////////////////////////////////////////////////////////////
                        UPDATE QUANTITY TESTS
    //////////////////////////////////////////////////////////////*/

    function testUpdateQuantitiesSuccess() public {
        uint requiredCollateral = addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );

        uint newQuantity = QUANTITY_1 + 100;
        uint newRequiredCollateral = calculateRequiredCollateral(
            PRICE_1,
            newQuantity
        );
        uint additionalCollateral = newRequiredCollateral - requiredCollateral;

        vm.prank(seller1);
        productManager.updateQuantities{value: additionalCollateral}(
            PRODUCT_1,
            newQuantity
        );

        assertEq(productManager.quantities(PRODUCT_1), newQuantity);
        assertEq(
            productManager.collaterals(PRODUCT_1),
            requiredCollateral + additionalCollateral
        );
    }

    function testUpdateQuantitiesWithExcessCollateral() public {
        uint higherQuantity = QUANTITY_1 + 100;
        uint excessAmount = ((higherQuantity - QUANTITY_1) *
            calculateRequiredCollateral(PRICE_1, higherQuantity)) / QUANTITY_1;
        uint totalCollateral = addProductWithExcessHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1,
            excessAmount
        );

        vm.prank(seller1);
        productManager.updateQuantities{value: 0}(PRODUCT_1, higherQuantity);

        assertEq(productManager.quantities(PRODUCT_1), higherQuantity);
        assertEq(productManager.collaterals(PRODUCT_1), totalCollateral);
    }

    function testUpdateQuantitiesRevertWhenNotSeller() public {
        addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );

        uint newQuantity = QUANTITY_1 + 100;
        vm.prank(seller2);
        vm.expectRevert("Only the seller can call this");
        productManager.updateQuantities{value: 0}(PRODUCT_1, newQuantity);
    }

    function testUpdateQuantitiesRevertWhenInsufficientCollateral() public {
        addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );

        uint higherQuantity = QUANTITY_1 + 100;
        vm.prank(seller1);
        vm.expectRevert("Insufficient collateral");
        productManager.updateQuantities{value: 0}(PRODUCT_1, higherQuantity);
    }

    function testUpdateQuantitiesDecreaseQuantity() public {
        addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );

        uint lowerQuantity = QUANTITY_1 - 1;
        vm.prank(seller1);
        productManager.updateQuantities{value: 0}(PRODUCT_1, lowerQuantity);
        assertEq(productManager.quantities(PRODUCT_1), lowerQuantity);
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzzUpdateQuantities(uint256 newQuantity) public {
        // Bound the input to reasonable range
        newQuantity = bound(newQuantity, 0, type(uint32).max);

        // First add a product
        uint requiredCollateral = addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );

        uint newRequiredCollateral = calculateRequiredCollateral(
            PRICE_1,
            newQuantity
        );

        vm.assume(newRequiredCollateral <= 5 ether);

        vm.prank(seller1);
        if (newRequiredCollateral <= requiredCollateral) {
            productManager.updateQuantities{value: 0}(PRODUCT_1, newQuantity);
        } else {
            uint additionalNeeded = newRequiredCollateral - requiredCollateral;
            productManager.updateQuantities{value: additionalNeeded}(
                PRODUCT_1,
                newQuantity
            );
        }

        assertEq(productManager.quantities(PRODUCT_1), newQuantity);
    }
}
