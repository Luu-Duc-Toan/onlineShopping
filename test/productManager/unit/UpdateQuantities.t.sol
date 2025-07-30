// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/ProductManagerTestBase.sol";

contract UpdateQuantitiesTest is ProductManagerTestBase {
    function setUp() public override {
        super.setUp();
        createCompleteProduct(product, price, quantity, seller1);
    }

    function testUpdateQuantitiesSuccess() public {
        uint additionalQuantity = 5;
        addQuantityToProduct(product, additionalQuantity);
        assertProductExists(
            product,
            price,
            quantity + additionalQuantity,
            seller1
        );
    }

    function testUpdateQuantitiesNotSellerReverts() public {
        uint newQuantity = quantity + 5;

        vm.expectRevert("Only the seller can call this");
        vm.prank(seller2);
        productManager.updateQuantities(product, newQuantity);
    }

    function testUpdateQuantitiesInsufficientCollateralReverts() public {
        uint newQuantity = quantity + 10;

        vm.expectRevert("Insufficient product collateral");
        vm.prank(seller1);
        productManager.updateQuantities(product, newQuantity);
    }

    function testUpdateQuantitiesDecrease() public {
        uint newQuantity = quantity - 2;

        vm.prank(seller1);
        productManager.updateQuantities(product, newQuantity);

        assertProductExists(product, price, newQuantity, seller1);
    }

    function testUpdateQuantitiesZero() public {
        uint newQuantity = 0;

        vm.expectRevert("Invalid quantity");
        vm.prank(seller1);
        productManager.updateQuantities(product, newQuantity);
    }

    function testUpdateQuantitiesNonExistentProduct() public {
        string memory nonExistentProduct = "nonExistent";
        uint newQuantity = 5;

        vm.expectRevert("Only the seller can call this");
        vm.prank(seller1);
        productManager.updateQuantities(nonExistentProduct, newQuantity);
    }

    function testUpdateQuantitiesSameValue() public {
        vm.prank(seller1);
        productManager.updateQuantities(product, quantity);

        assertProductExists(product, price, quantity, seller1);
    }

    function testUpdateQuantityMaxValue() public {
        uint newQuantity = type(uint120).max;

        addQuantityToProduct(product, newQuantity - quantity);
        assertProductExists(product, price, newQuantity, seller1);
    }

    function testFuzzUpdateQuantities(uint256 _newQuantity) public {
        vm.assume(_newQuantity > 0 && _newQuantity < type(uint120).max);

        if (_newQuantity <= quantity) {
            vm.prank(seller1);
            productManager.updateQuantities(product, _newQuantity);
        } else {
            addQuantityToProduct(product, _newQuantity - quantity);
        }
        assertProductExists(product, price, _newQuantity, seller1);
    }
}
