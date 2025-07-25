// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ProductManagerTestBase} from "./ProductManagerTestBase.sol";

/**
 * @title ProductManagerUpdatePriceTest
 * @dev Tests for the updatePrice functionality
 */
contract ProductManagerUpdatePriceTest is ProductManagerTestBase {
    /*//////////////////////////////////////////////////////////////
                        UPDATE PREPARING TIME TESTS
    //////////////////////////////////////////////////////////////*/

    function testUpdatePreparingTimeSuccess() public {
        addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );

        uint newPreparingTime = PREPARING_TIME_1 + 3 days;
        vm.prank(seller1);
        productManager.updatePreparingTime(PRODUCT_1, newPreparingTime);

        assertEq(productManager.preparingTimes(PRODUCT_1), newPreparingTime);
    }

    function testUpdatePreparingTimeRevertWhenNotSeller() public {
        addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );

        vm.prank(seller2);
        vm.expectRevert("Only the seller can call this");
        productManager.updatePreparingTime(PRODUCT_1, 5 days);
    }

    function testUpdatePreparingTimeToZero() public {
        addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );

        vm.prank(seller1);
        productManager.updatePreparingTime(PRODUCT_1, 0);

        assertEq(productManager.preparingTimes(PRODUCT_1), 0);
    }

    function testUpdatePreparingTimeMultipleTimes() public {
        addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );

        vm.startPrank(seller1);

        productManager.updatePreparingTime(PRODUCT_1, 1 days);
        assertEq(productManager.preparingTimes(PRODUCT_1), 1 days);

        productManager.updatePreparingTime(PRODUCT_1, 7 days);
        assertEq(productManager.preparingTimes(PRODUCT_1), 7 days);

        productManager.updatePreparingTime(PRODUCT_1, 30 days);
        assertEq(productManager.preparingTimes(PRODUCT_1), 30 days);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzzUpdatePreparingTime(uint256 newPreparingTime) public {
        // Bound to reasonable range
        newPreparingTime = bound(newPreparingTime, 0, 365 days);

        // Add a product first
        addProductHelper(
            PRODUCT_1,
            QUANTITY_1,
            seller1,
            PREPARING_TIME_1,
            PRICE_1
        );

        vm.prank(seller1);
        productManager.updatePreparingTime(PRODUCT_1, newPreparingTime);

        assertEq(productManager.preparingTimes(PRODUCT_1), newPreparingTime);
    }
}
