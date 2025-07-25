// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {ProductManager} from "../../src/ProductManager.sol";

/**
 * @title ProductManagerTestBase
 * @dev Base contract for ProductManager tests with shared setup and utilities
 */
contract ProductManagerTestBase is Test {
    ProductManager public productManager;

    // Test accounts
    address public seller1 = makeAddr("seller1");
    address public seller2 = makeAddr("seller2");
    address public buyer = makeAddr("buyer");

    // Test data constants
    string constant PRODUCT_1 = "iPhone15";
    string constant PRODUCT_2 = "MacBook";
    uint constant QUANTITY_1 = 10;
    uint constant PRICE_1 = 1000;
    uint constant PREPARING_TIME_1 = 3 days;

    function setUp() public virtual {
        productManager = new ProductManager();

        vm.deal(seller1, 10 ether);
        vm.deal(seller2, 10 ether);
        vm.deal(buyer, 10 ether);
    }

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function calculateRequiredCollateral(
        uint price,
        uint quantity
    ) internal view returns (uint) {
        return (price * productManager.collateralPercent() * quantity) / 100;
    }

    function addProductHelper(
        string memory product,
        uint quantity,
        address seller,
        uint preparingTime,
        uint price
    ) internal returns (uint requiredCollateral) {
        requiredCollateral = calculateRequiredCollateral(price, quantity);

        vm.prank(seller);
        productManager.addProduct{value: requiredCollateral}(
            product,
            quantity,
            preparingTime,
            price
        );
    }

    function addProductWithExcessHelper(
        string memory product,
        uint quantity,
        address seller,
        uint preparingTime,
        uint price,
        uint excessAmount
    ) internal returns (uint totalCollateral) {
        uint requiredCollateral = calculateRequiredCollateral(price, quantity);
        totalCollateral = requiredCollateral + excessAmount;

        vm.prank(seller);
        productManager.addProduct{value: totalCollateral}(
            product,
            quantity,
            preparingTime,
            price
        );
    }
}
