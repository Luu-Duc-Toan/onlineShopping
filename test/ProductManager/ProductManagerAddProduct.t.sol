// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ProductManagerTestBase} from "./ProductManagerTestBase.sol";

/**
 * @title ProductManagerAddProductTest
 * @dev Tests for the addProduct functionality
 */
contract ProductManagerAddProductTest is ProductManagerTestBase {
    /*//////////////////////////////////////////////////////////////
                        ADD PRODUCT TESTS
    //////////////////////////////////////////////////////////////*/

    function testAddProductSuccess() public {
        uint requiredCollateral = calculateRequiredCollateral(
            PRICE_1,
            QUANTITY_1
        );

        vm.prank(seller1);
        productManager.addProduct{value: requiredCollateral}(
            PRODUCT_1,
            QUANTITY_1,
            PREPARING_TIME_1,
            PRICE_1
        );

        // Verify product was added correctly
        assertEq(productManager.quantities(PRODUCT_1), QUANTITY_1);
        assertEq(productManager.sellers(PRODUCT_1), seller1);
        assertEq(productManager.preparingTimes(PRODUCT_1), PREPARING_TIME_1);
        assertEq(productManager.prices(PRODUCT_1), PRICE_1);
        assertEq(productManager.collaterals(PRODUCT_1), requiredCollateral);
    }

    function testAddProductRevertWhenProductAlreadyExists() public {
        uint requiredCollateral = calculateRequiredCollateral(
            PRICE_1,
            QUANTITY_1
        );

        // Add product first time
        vm.prank(seller1);
        productManager.addProduct{value: requiredCollateral}(
            PRODUCT_1,
            QUANTITY_1,
            PREPARING_TIME_1,
            PRICE_1
        );

        // Try to add same product again
        vm.prank(seller2);
        vm.expectRevert("Product already exists");
        productManager.addProduct{value: requiredCollateral}(
            PRODUCT_1,
            5,
            2 days,
            2000
        );
    }

    function testAddProductRevertWhenInsufficientCollateral() public {
        uint requiredCollateral = calculateRequiredCollateral(
            PRICE_1,
            QUANTITY_1
        );
        uint insufficientAmount = requiredCollateral - 1;

        vm.prank(seller1);
        vm.expectRevert("Insufficient collateral");
        productManager.addProduct{value: insufficientAmount}(
            PRODUCT_1,
            QUANTITY_1,
            PREPARING_TIME_1,
            PRICE_1
        );
    }

    function testAddProductAcceptExcessCollateral() public {
        uint requiredCollateral = calculateRequiredCollateral(
            PRICE_1,
            QUANTITY_1
        );
        uint excessAmount = requiredCollateral + 500;

        vm.prank(seller1);
        productManager.addProduct{value: excessAmount}(
            PRODUCT_1,
            QUANTITY_1,
            PREPARING_TIME_1,
            PRICE_1
        );

        // Should succeed and store the excess amount
        assertEq(productManager.sellers(PRODUCT_1), seller1);
        assertEq(productManager.collaterals(PRODUCT_1), excessAmount);
    }

    function testAddProductWithZeroValues() public {
        // Test with zero price and quantity (edge case)
        vm.prank(seller1);
        productManager.addProduct{value: 0}(
            PRODUCT_1,
            0, // zero quantity
            0, // zero preparing time
            0 // zero price
        );

        assertEq(productManager.quantities(PRODUCT_1), 0);
        assertEq(productManager.prices(PRODUCT_1), 0);
        assertEq(productManager.preparingTimes(PRODUCT_1), 0);
        assertEq(productManager.collaterals(PRODUCT_1), 0);
    }

    function testAddProductWithLargeNumbers() public {
        uint quantity = 1000000;
        uint price = 999999;
        uint preparingTime = 30 days;

        uint requiredCollateral = calculateRequiredCollateral(price, quantity);
        vm.assume(requiredCollateral <= 5 ether); // Keep within reasonable bounds

        vm.prank(seller1);
        productManager.addProduct{value: requiredCollateral}(
            PRODUCT_1,
            quantity,
            preparingTime,
            price
        );

        assertEq(productManager.quantities(PRODUCT_1), quantity);
        assertEq(productManager.prices(PRODUCT_1), price);
        assertEq(productManager.preparingTimes(PRODUCT_1), preparingTime);
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzzAddProduct(
        uint256 quantity,
        uint256 preparingTime,
        uint256 price
    ) public {
        // Bound the inputs to reasonable ranges
        quantity = bound(quantity, 0, type(uint32).max);
        preparingTime = bound(preparingTime, 0, 365 days);
        price = bound(price, 0, type(uint32).max);

        uint requiredCollateral = calculateRequiredCollateral(price, quantity);

        // Ensure we have enough ETH for the test
        vm.assume(requiredCollateral <= 5 ether);

        vm.prank(seller1);
        productManager.addProduct{value: requiredCollateral}(
            PRODUCT_1,
            quantity,
            preparingTime,
            price
        );

        assertEq(productManager.quantities(PRODUCT_1), quantity);
        assertEq(productManager.sellers(PRODUCT_1), seller1);
        assertEq(productManager.preparingTimes(PRODUCT_1), preparingTime);
        assertEq(productManager.prices(PRODUCT_1), price);
        assertEq(productManager.collaterals(PRODUCT_1), requiredCollateral);
    }
}
