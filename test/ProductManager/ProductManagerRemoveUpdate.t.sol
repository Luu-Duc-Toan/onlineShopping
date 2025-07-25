// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ProductManagerTestBase} from "./ProductManagerTestBase.sol";

/**
 * @title ProductManagerRemoveUpdateTest
 * @dev Tests for remove product and update preparing time functionality
 */
contract ProductManagerRemoveUpdateTest is ProductManagerTestBase {
    /*//////////////////////////////////////////////////////////////
                        REMOVE PRODUCT TESTS
    //////////////////////////////////////////////////////////////*/

    function testRemoveProductSuccess() public {
        addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );
        uint collateral = productManager.collaterals(PRODUCT_1);
        uint balanceBeforeRemoval = seller1.balance;

        vm.prank(seller1);
        productManager.removeProduct(PRODUCT_1);

        assertEq(seller1.balance, balanceBeforeRemoval + collateral);
        assertEq(productManager.quantities(PRODUCT_1), 0);
        assertEq(productManager.sellers(PRODUCT_1), address(0));
        assertEq(productManager.preparingTimes(PRODUCT_1), 0);
        assertEq(productManager.prices(PRODUCT_1), 0);
        assertEq(productManager.collaterals(PRODUCT_1), 0);
    }

    function testRemoveProductWithExcessCollateral() public {
        uint excessCollateral = 100;
        addProductWithExcessHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1,
            excessCollateral
        );
        uint collateral = productManager.collaterals(PRODUCT_1);
        uint balanceBeforeRemoval = seller1.balance;

        vm.prank(seller1);
        productManager.removeProduct(PRODUCT_1);

        assertEq(seller1.balance, balanceBeforeRemoval + collateral);
        assertEq(productManager.quantities(PRODUCT_1), 0);
        assertEq(productManager.sellers(PRODUCT_1), address(0));
        assertEq(productManager.preparingTimes(PRODUCT_1), 0);
        assertEq(productManager.prices(PRODUCT_1), 0);
        assertEq(productManager.collaterals(PRODUCT_1), 0);
    }

    function testRemoveProductRevertWhenNotSeller() public {
        addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );

        vm.prank(seller2);
        vm.expectRevert("Only the seller can call this");
        productManager.removeProduct(PRODUCT_1);
    }

    function testRemoveProductRevertWhenProductNotExists() public {
        vm.prank(seller1);
        vm.expectRevert("Only the seller can call this");
        productManager.removeProduct("NonExistentProduct");
    }

    /*//////////////////////////////////////////////////////////////
                        INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testFullProductLifecycle() public {
        uint initialCollateral = calculateRequiredCollateral(
            PRICE_1,
            QUANTITY_1
        );

        vm.startPrank(seller1);

        // 1. Add product
        productManager.addProduct{value: initialCollateral}(
            PRODUCT_1,
            QUANTITY_1,
            PREPARING_TIME_1,
            PRICE_1
        );

        // 2. Update preparing time
        productManager.updatePreparingTime(PRODUCT_1, 5 days);

        // 3. Update quantity (increase)
        uint newQuantity = 15;
        uint additionalCollateral = calculateRequiredCollateral(
            PRICE_1,
            newQuantity
        ) - initialCollateral;
        productManager.updateQuantities{value: additionalCollateral}(
            PRODUCT_1,
            newQuantity
        );

        // 4. Update price (increase)
        uint newPrice = 1200;
        uint morePriceCollateral = calculateRequiredCollateral(
            newPrice,
            newQuantity
        ) - (initialCollateral + additionalCollateral);
        productManager.updatePrice{value: morePriceCollateral}(
            PRODUCT_1,
            newPrice
        );

        // 5. Verify final state
        assertEq(productManager.quantities(PRODUCT_1), newQuantity);
        assertEq(productManager.prices(PRODUCT_1), newPrice);
        assertEq(productManager.preparingTimes(PRODUCT_1), 5 days);

        // 6. Remove product
        uint finalBalance = seller1.balance;
        productManager.removeProduct(PRODUCT_1);

        // Verify all collateral returned
        uint totalCollateralPaid = initialCollateral +
            additionalCollateral +
            morePriceCollateral;
        assertEq(seller1.balance, finalBalance + totalCollateralPaid);

        vm.stopPrank();
    }

    function testMultipleProductsManagement() public {
        // Add multiple products without startPrank to avoid conflicts
        addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );
        addProductHelper(PRODUCT_2, 5, seller1, 2 days, 2000);

        // Update one product
        vm.prank(seller1);
        productManager.updatePreparingTime(PRODUCT_1, 7 days);

        // Remove one product
        uint balanceBefore = seller1.balance;
        vm.prank(seller1);
        productManager.removeProduct(PRODUCT_2);

        // Verify only PRODUCT_2 was removed
        assertEq(productManager.sellers(PRODUCT_1), seller1); // Still exists
        assertEq(productManager.sellers(PRODUCT_2), address(0)); // Removed

        // Verify collateral returned for PRODUCT_2
        uint expectedReturn = calculateRequiredCollateral(2000, 5);
        assertEq(seller1.balance, balanceBefore + expectedReturn);
    }
}
