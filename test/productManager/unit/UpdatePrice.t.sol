// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/ProductManagerTestBase.sol";

contract UpdatePriceTest is ProductManagerTestBase {
    function setUp() public override {
        super.setUp();
        createCompleteProduct(product, price, quantity, seller1);
    }

    function testUpdatePriceSuccess() public {
        uint newPrice = price + 100;

        updateProductPrice(product, newPrice);
        assertProductExists(product, newPrice, quantity, seller1);
    }

    function testUpdatePriceNotSellerReverts() public {
        uint newPrice = price + 100;

        vm.expectRevert("Only the seller can call this");
        vm.prank(seller2);
        productManager.updatePrice(product, newPrice);
    }

    function testUpdatePriceInsufficientCollateralReverts() public {
        uint newPrice = price + 1;

        vm.expectRevert("Insufficient product collateral");
        vm.prank(seller1);
        productManager.updatePrice(product, newPrice);
    }

    function testUpdatePriceDecrease() public {
        uint newPrice = price - 100;

        vm.prank(seller1);
        productManager.updatePrice(product, newPrice);

        assertProductExists(product, newPrice, quantity, seller1);
    }

    function testUpdatePriceZero() public {
        uint newPrice = 0;

        vm.expectRevert("Invalid price");
        vm.prank(seller1);
        productManager.updatePrice(product, newPrice);
    }

    function testUpdatePriceNonExistentProduct() public {
        string memory nonExistentProduct = "nonExistent";
        uint newPrice = 500;

        vm.expectRevert("Only the seller can call this");
        vm.prank(seller1);
        productManager.updatePrice(nonExistentProduct, newPrice);
    }

    function testUpdatePriceSameValue() public {
        vm.prank(seller1);
        productManager.updatePrice(product, price);

        assertProductExists(product, price, quantity, seller1);
    }

    function testUpdatePriceMaxValue() public {
        uint newPrice = type(uint120).max;

        updateProductPrice(product, newPrice);
        assertProductExists(product, newPrice, quantity, seller1);
    }

    function testFuzzUpdatePrice(uint256 _newPrice) public {
        vm.assume(_newPrice > 0 && _newPrice <= type(uint120).max);

        updateProductPrice(product, _newPrice);
        assertProductExists(product, _newPrice, quantity, seller1);
    }
}
