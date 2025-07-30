// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/ProductManagerTestBase.sol";

contract AddProductTest is ProductManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testAddProductSuccess() public {
        createCompleteProduct(product, price, quantity, seller1);
        assertProductExists(product, price, quantity, seller1);
    }

    function testAddProductInsufficientCollateralReverts() public {
        vm.expectRevert("Insufficient product collateral");
        vm.prank(seller1);
        productManager.addProduct(product, quantity, price);
    }

    function testAddProductAlreadyExistsReverts() public {
        createCompleteProduct(product, price, quantity, seller1);

        vm.expectRevert("Product already exists");
        vm.prank(seller2);
        productManager.addProduct(product, quantity, price);
    }

    function testAddProductEmptyName() public {
        createCompleteProduct("", price, quantity, seller1);
        assertProductExists("", price, quantity, seller1);
    }

    function testAddProductZeroQuantity() public {
        uint zeroQuantity = 0;

        vm.expectRevert("Invalid quantity");
        vm.prank(seller1);
        productManager.addProduct(product, zeroQuantity, price);
    }

    function testAddProductZeroPrice() public {
        uint zeroPrice = 0;

        vm.expectRevert("Invalid price");
        vm.prank(seller1);
        productManager.addProduct(product, quantity, zeroPrice);
    }

    function testFuzzAddProduct(uint256 _price, uint256 _quantity) public {
        vm.assume(_price > 0 && _price <= type(uint120).max);
        vm.assume(_quantity > 0 && _quantity <= type(uint120).max);

        createCompleteProduct(product, _price, _quantity, seller1);
        assertProductExists(product, _price, _quantity, seller1);
    }
}
