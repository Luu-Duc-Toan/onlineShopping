// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ProductManagerTestBase} from "./ProductManagerTestBase.sol";

/**
 * @title ProductManagerCollateralTest
 * @dev Tests for collateral management functionality
 */
contract ProductManagerCollateralTest is ProductManagerTestBase {
    /*//////////////////////////////////////////////////////////////
                        WITHDRAW EXCESS COLLATERAL TESTS
    //////////////////////////////////////////////////////////////*/

    function testWithdrawExcessCollateralSuccess() public {
        // Add product with excess collateral
        uint requiredCollateral = calculateRequiredCollateral(
            PRICE_1,
            QUANTITY_1
        );
        uint excessAmount = 500;
        uint totalCollateral = requiredCollateral + excessAmount;

        vm.prank(seller1);
        productManager.addProduct{value: totalCollateral}(
            PRODUCT_1,
            QUANTITY_1,
            PREPARING_TIME_1,
            PRICE_1
        );

        uint balanceBefore = seller1.balance;

        // Withdraw excess collateral
        vm.prank(seller1);
        productManager.withdrawExcessCollateral(PRODUCT_1);

        // Check balances
        assertEq(seller1.balance, balanceBefore + excessAmount);
        assertEq(productManager.collaterals(PRODUCT_1), requiredCollateral);
    }

    function testWithdrawExcessCollateralRevertWhenNoExcess() public {
        // Add product with exact collateral
        addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );

        // Try to withdraw excess when there is none
        vm.prank(seller1);
        vm.expectRevert("No excess collateral");
        productManager.withdrawExcessCollateral(PRODUCT_1);
    }

    function testWithdrawExcessCollateralRevertWhenNotSeller() public {
        // Add product with excess collateral
        uint totalCollateral = addProductWithExcessHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1,
            500
        );

        // Try to withdraw from different account
        vm.prank(seller2);
        vm.expectRevert("Only the seller can call this");
        productManager.withdrawExcessCollateral(PRODUCT_1);
    }

    /*//////////////////////////////////////////////////////////////
                        COLLATERAL CALCULATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testCollateralCalculation() public {
        uint quantity = 5;
        uint price = 200;
        uint expectedCollateral = calculateRequiredCollateral(price, quantity);
        // Expected: (200 * 10 * 5) / 100 = 100

        vm.prank(seller1);
        productManager.addProduct{value: expectedCollateral}(
            PRODUCT_1,
            quantity,
            PREPARING_TIME_1,
            price
        );

        assertEq(productManager.collaterals(PRODUCT_1), expectedCollateral);
        assertEq(expectedCollateral, 100);
    }

    function testComplexCollateralWorkflow() public {
        // Add initial product with excess collateral
        uint initialCollateral = calculateRequiredCollateral(
            PRICE_1,
            QUANTITY_1
        );
        uint excess = 1000;

        vm.startPrank(seller1);
        productManager.addProduct{value: initialCollateral + excess}(
            PRODUCT_1,
            QUANTITY_1,
            PREPARING_TIME_1,
            PRICE_1
        );

        // Update quantity to higher value
        uint newQuantity = 15;
        uint totalRequiredForNewQuantity = calculateRequiredCollateral(
            PRICE_1,
            newQuantity
        );
        uint currentCollateral = initialCollateral + excess;

        if (totalRequiredForNewQuantity > currentCollateral) {
            uint additionalNeeded = totalRequiredForNewQuantity -
                currentCollateral;
            productManager.updateQuantities{value: additionalNeeded}(
                PRODUCT_1,
                newQuantity
            );
        } else {
            productManager.updateQuantities{value: 0}(PRODUCT_1, newQuantity);
        }

        // Now withdraw some excess
        uint balanceBefore = seller1.balance;
        productManager.withdrawExcessCollateral(PRODUCT_1);
        uint balanceAfter = seller1.balance;

        // Calculate expected withdrawal amount
        uint finalRequired = calculateRequiredCollateral(PRICE_1, newQuantity);
        uint actualExcess = (initialCollateral + excess) - finalRequired;

        // Should have withdrawn the actual excess
        assertEq(balanceAfter - balanceBefore, actualExcess);

        // Final collateral should be exactly what's required
        assertEq(productManager.collaterals(PRODUCT_1), finalRequired);

        vm.stopPrank();
    }

    function testCollateralAccumulationAcrossUpdates() public {
        // Add initial product
        uint initialCollateral = addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );

        vm.startPrank(seller1);

        // Update quantity - adds more collateral
        uint newQuantity = 15;
        uint quantityCollateralNeeded = calculateRequiredCollateral(
            PRICE_1,
            newQuantity
        );
        uint additionalForQuantity = quantityCollateralNeeded -
            initialCollateral;

        productManager.updateQuantities{value: additionalForQuantity}(
            PRODUCT_1,
            newQuantity
        );

        // Update price - adds more collateral
        uint newPrice = 1500;
        uint priceCollateralNeeded = calculateRequiredCollateral(
            newPrice,
            newQuantity
        );
        uint currentCollateral = initialCollateral + additionalForQuantity;
        uint additionalForPrice = priceCollateralNeeded - currentCollateral;

        productManager.updatePrice{value: additionalForPrice}(
            PRODUCT_1,
            newPrice
        );

        // Total should be sum of all collaterals
        uint expectedTotal = initialCollateral +
            additionalForQuantity +
            additionalForPrice;
        assertEq(productManager.collaterals(PRODUCT_1), expectedTotal);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzzWithdrawExcessCollateral(uint256 excessAmount) public {
        // Bound excess amount to reasonable range
        excessAmount = bound(excessAmount, 1, 1 ether);

        uint requiredCollateral = calculateRequiredCollateral(
            PRICE_1,
            QUANTITY_1
        );
        uint totalCollateral = requiredCollateral + excessAmount;

        vm.prank(seller1);
        productManager.addProduct{value: totalCollateral}(
            PRODUCT_1,
            QUANTITY_1,
            PREPARING_TIME_1,
            PRICE_1
        );

        uint balanceBefore = seller1.balance;

        vm.prank(seller1);
        productManager.withdrawExcessCollateral(PRODUCT_1);

        assertEq(seller1.balance, balanceBefore + excessAmount);
        assertEq(productManager.collaterals(PRODUCT_1), requiredCollateral);
    }

    function testFuzzCollateralCalculation(
        uint256 price,
        uint256 quantity
    ) public {
        // Bound inputs to reasonable ranges
        price = bound(price, 1, type(uint32).max);
        quantity = bound(quantity, 1, type(uint32).max);

        uint expectedCollateral = calculateRequiredCollateral(price, quantity);
        vm.assume(expectedCollateral <= 5 ether);

        vm.prank(seller1);
        productManager.addProduct{value: expectedCollateral}(
            PRODUCT_1,
            quantity,
            PREPARING_TIME_1,
            price
        );

        assertEq(productManager.collaterals(PRODUCT_1), expectedCollateral);

        // Verify calculation matches contract logic
        uint contractCollateral = (price *
            productManager.collateralPercent() *
            quantity) / 100;
        assertEq(expectedCollateral, contractCollateral);
    }
}
