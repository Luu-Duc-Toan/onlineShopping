// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/CollateralManagerTestBase.sol";

contract AddProductCollateralTest is CollateralManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testAddProductCollateralSuccess() public {
        uint requiredCollateral = collateralManager.getRequiredSellerCollateral(
            price,
            quantity
        );

        vm.prank(seller1);
        collateralManager.addProductCollateral{value: requiredCollateral}(
            product
        );

        assertEq(
            collateralManager.productCollaterals(product),
            requiredCollateral
        );
    }

    function testAddProductCollateralZeroValue() public {
        vm.prank(seller1);
        vm.expectRevert("Collateral must be greater than 0");
        collateralManager.addProductCollateral{value: 0}(product);
    }

    function testAddProductCollateralExcessValue() public {
        uint requiredCollateral = collateralManager.getRequiredSellerCollateral(
            price,
            quantity
        );
        uint excessAmount = requiredCollateral + amount;

        uint initialBalance = collateralManager.balances(seller1);

        vm.prank(seller1);
        collateralManager.addProductCollateral{value: excessAmount}(product);

        assertEq(collateralManager.productCollaterals(product), excessAmount);
        assertEq(collateralManager.balances(seller1), initialBalance);
    }

    function testAddProductCollateralEmptyProduct() public {
        vm.prank(seller1);
        collateralManager.addProductCollateral{value: amount}("");
        assertEq(collateralManager.productCollaterals(""), amount);
    }

    function testAddProductCollateralAlreadyExists() public {
        uint requiredCollateral = collateralManager.getRequiredSellerCollateral(
            price,
            quantity
        );

        vm.prank(seller1);
        collateralManager.addProductCollateral{value: requiredCollateral}(
            product
        );

        uint additionalCollateral = requiredCollateral;
        vm.prank(seller1);
        collateralManager.addProductCollateral{value: additionalCollateral}(
            product
        );

        assertEq(
            collateralManager.productCollaterals(product),
            requiredCollateral + additionalCollateral
        );
    }

    function testFuzzAddProductCollateralValidAmounts(
        uint _price,
        uint _quantity
    ) public {
        vm.assume(_price > 0 && _price < type(uint120).max);
        vm.assume(_quantity > 0 && _quantity < type(uint120).max);
        console.log("Fuzzing with price: %s, quantity: %s", _price, _quantity);

        uint requiredCollateral = (_price *
            _quantity *
            collateralPercent +
            99) / 100;
        vm.assume(requiredCollateral > 0);

        vm.deal(seller1, requiredCollateral);
        vm.prank(seller1);
        collateralManager.addProductCollateral{value: requiredCollateral}(
            product
        );

        assertEq(
            collateralManager.productCollaterals(product),
            requiredCollateral
        );
    }
}
