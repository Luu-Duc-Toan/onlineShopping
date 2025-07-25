// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ProductManagerTestBase} from "./ProductManagerTestBase.sol";

/**
 * @title ProductManagerUpdatePriceTest
 * @dev Tests for the updatePrice functionality
 */
contract ProductManagerUpdatePriceTest is ProductManagerTestBase {
    /*//////////////////////////////////////////////////////////////
                        UPDATE PRICE TESTS
    //////////////////////////////////////////////////////////////*/

    function testUpdatePriceSuccess() public {
        uint requiredCollateral = addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );

        uint newPrice = PRICE_1 + 1000;
        uint newRequiredCollateral = calculateRequiredCollateral(
            newPrice,
            QUANTITY_1
        );
        uint additionalCollateral = newRequiredCollateral - requiredCollateral;

        vm.prank(seller1);
        productManager.updatePrice{value: additionalCollateral}(
            PRODUCT_1,
            newPrice
        );

        assertEq(productManager.prices(PRODUCT_1), newPrice);
        assertEq(
            productManager.collaterals(PRODUCT_1),
            requiredCollateral + additionalCollateral
        );
    }

    function testUpdatePriceWithExcessCollateral() public {
        uint higherPrice = PRICE_1 + 1000;
        uint excessAmount = ((higherPrice - PRICE_1) *
            calculateRequiredCollateral(higherPrice, QUANTITY_1)) / PRICE_1;

        uint totalCollateral = addProductWithExcessHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1,
            excessAmount
        );
        vm.prank(seller1);
        productManager.updatePrice{value: 0}(PRODUCT_1, higherPrice);

        assertEq(productManager.prices(PRODUCT_1), higherPrice);
        assertEq(productManager.collaterals(PRODUCT_1), totalCollateral);
    }

    function testUpdatePriceRevertWhenNotSeller() public {
        addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );

        uint newPrice = 1500;
        vm.prank(seller2);
        vm.expectRevert("Only the seller can call this");
        productManager.updatePrice{value: 0}(PRODUCT_1, newPrice);
    }

    function testUpdatePriceRevertWhenInsufficientCollateral() public {
        addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );

        uint higherPrice = PRICE_1 + 1;
        vm.prank(seller1);
        vm.expectRevert("Insufficient collateral");
        productManager.updatePrice{value: 0}(PRODUCT_1, higherPrice);
    }

    function testUpdatePriceDecrease() public {
        addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );

        uint newPrice = PRICE_1 - 1;
        vm.prank(seller1);
        productManager.updatePrice{value: 0}(PRODUCT_1, newPrice);

        assertEq(productManager.prices(PRODUCT_1), newPrice);
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzzUpdatePrice(uint256 newPrice) public {
        // Bound the input to reasonable range
        newPrice = bound(newPrice, 0, type(uint32).max);

        // First add a product
        uint requiredCollateral = addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );

        uint newRequiredCollateral = calculateRequiredCollateral(
            newPrice,
            QUANTITY_1
        );

        vm.assume(newRequiredCollateral <= 5 ether);

        vm.prank(seller1);
        if (newRequiredCollateral <= requiredCollateral) {
            productManager.updatePrice{value: 0}(PRODUCT_1, newPrice);
        } else {
            uint additionalNeeded = newRequiredCollateral - requiredCollateral;
            productManager.updatePrice{value: additionalNeeded}(
                PRODUCT_1,
                newPrice
            );
        }

        assertEq(productManager.prices(PRODUCT_1), newPrice);
    }
}
