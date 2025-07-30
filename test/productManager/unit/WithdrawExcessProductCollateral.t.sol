// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/ProductManagerTestBase.sol";

contract WithdrawExcessProductCollateralTest is ProductManagerTestBase {
    function setUp() public override {
        super.setUp();
        createCompleteProduct(product, price, quantity, seller1);
    }

    function testWithdrawExcessProductCollateralSuccess() public {
        uint extraCollateral = 5 ether;
        vm.deal(seller1, extraCollateral + 1 ether);
        vm.prank(seller1);
        collateralManager.addProductCollateral{value: extraCollateral}(product);

        uint requiredCollateral = collateralManager.getRequiredSellerCollateral(
            price,
            quantity
        );

        uint initialBalance = collateralManager.balances(seller1);

        vm.prank(seller1);
        productManager.withdrawExcessProductCollateral(product);

        assertEq(
            collateralManager.balances(seller1),
            initialBalance + extraCollateral
        );
        assertEq(
            collateralManager.productCollaterals(product),
            requiredCollateral
        );
    }

    function testWithdrawExcessProductCollateralNotSellerReverts() public {
        vm.expectRevert("Only the seller can call this");
        vm.prank(seller2);
        productManager.withdrawExcessProductCollateral(product);
    }

    function testWithdrawExcessProductCollateralNonExistentProductReverts()
        public
    {
        string memory nonExistentProduct = "nonExistent";

        vm.expectRevert("Only the seller can call this");
        vm.prank(seller1);
        productManager.withdrawExcessProductCollateral(nonExistentProduct);
    }

    function testWithdrawExcessProductCollateralNoExcess() public {
        uint initialBalance = collateralManager.balances(seller1);
        uint initialProductCollateral = collateralManager.productCollaterals(
            product
        );

        vm.prank(seller1);
        productManager.withdrawExcessProductCollateral(product);

        assertEq(collateralManager.balances(seller1), initialBalance);
        assertEq(
            collateralManager.productCollaterals(product),
            initialProductCollateral
        );
    }

    function testFuzzWithdrawExcessProductCollateral(
        uint256 _price,
        uint256 _quantity,
        uint256 _extraCollateral
    ) public {
        vm.assume(_price > 0 && _price <= type(uint120).max);
        vm.assume(_quantity > 0 && _quantity <= type(uint120).max);
        vm.assume(
            _extraCollateral > 0 && _extraCollateral <= type(uint120).max
        );

        string memory fuzzProduct = "fuzzProduct";
        createCompleteProduct(fuzzProduct, _price, _quantity, seller2);
        vm.deal(seller2, _extraCollateral + 1 ether);
        vm.prank(seller2);
        collateralManager.addProductCollateral{value: _extraCollateral}(
            fuzzProduct
        );

        uint requiredCollateral = collateralManager.getRequiredSellerCollateral(
            _price,
            _quantity
        );
        uint totalCollateral = collateralManager.productCollaterals(
            fuzzProduct
        );
        uint expectedExcess = totalCollateral - requiredCollateral;
        uint initialBalance = collateralManager.balances(seller2);

        vm.prank(seller2);
        productManager.withdrawExcessProductCollateral(fuzzProduct);

        assertEq(
            collateralManager.balances(seller2),
            initialBalance + expectedExcess
        );
        assertEq(
            collateralManager.productCollaterals(fuzzProduct),
            requiredCollateral
        );
    }
}
