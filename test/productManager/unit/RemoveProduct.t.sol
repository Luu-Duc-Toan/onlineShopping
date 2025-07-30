// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/ProductManagerTestBase.sol";

contract RemoveProductTest is ProductManagerTestBase {
    function setUp() public override {
        super.setUp();
        createCompleteProduct(product, price, quantity, seller1);
    }

    function testRemoveProductSuccess() public {
        uint initialSellerBalance = seller1.balance;
        uint productCollateral = collateralManager.productCollaterals(product);

        vm.prank(seller1);
        productManager.removeProduct(product);

        assertProductNotExists(product);
        assertEq(seller1.balance, initialSellerBalance + productCollateral);
        assertEq(collateralManager.productCollaterals(product), 0);
    }

    function testRemoveProductNotSellerReverts() public {
        vm.expectRevert("Only the seller can call this");
        vm.prank(seller2);
        productManager.removeProduct(product);
    }

    function testRemoveProductNonExistentReverts() public {
        string memory nonExistentProduct = "nonExistent";

        vm.expectRevert("Only the seller can call this");
        vm.prank(seller1);
        productManager.removeProduct(nonExistentProduct);
    }

    function testRemoveProductEmptyName() public {
        string memory emptyProduct = "";
        createCompleteProduct(emptyProduct, price, quantity, seller1);

        uint initialSellerBalance = seller1.balance;
        uint productCollateral = collateralManager.productCollaterals(
            emptyProduct
        );

        vm.prank(seller1);
        productManager.removeProduct(emptyProduct);

        assertProductNotExists(emptyProduct);
        assertEq(seller1.balance, initialSellerBalance + productCollateral);
    }
}
