// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/CollateralManagerTestBase.sol";
import "forge-std/console.sol";

contract WithdrawExcessProductCollateralTest is CollateralManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testWithdrawExcessProductCollateralSuccess() public {
        uint requiredCollateral = collateralManager.getRequiredSellerCollateral(
            price,
            quantity
        );
        uint excessCollateral = requiredCollateral + amount;

        vm.prank(seller1);
        collateralManager.addProductCollateral{value: excessCollateral}(
            product
        );

        uint initialBalance = collateralManager.balances(seller1);

        vm.prank(address(productManager));
        collateralManager.withdrawExcessProductCollateral(
            product,
            price,
            quantity,
            seller1
        );

        assertEq(collateralManager.balances(seller1), initialBalance + amount);
        assertEq(
            collateralManager.productCollaterals(product),
            requiredCollateral
        );
    }

    function testWithdrawExcessProductCollateralNotProductManagerReverts()
        public
    {
        vm.expectRevert("Only ProductManager can call this");
        vm.prank(seller1);
        collateralManager.withdrawExcessProductCollateral(
            product,
            price,
            quantity,
            seller1
        );
    }

    function testWithdrawExcessProductCollateralExactCollateral() public {
        uint requiredCollateral = collateralManager.getRequiredSellerCollateral(
            price,
            quantity
        );

        vm.prank(seller1);
        collateralManager.addProductCollateral{value: requiredCollateral}(
            product
        );

        uint initialBalance = collateralManager.balances(seller1);

        vm.prank(address(productManager));
        collateralManager.withdrawExcessProductCollateral(
            product,
            price,
            quantity,
            seller1
        );

        assertEq(collateralManager.balances(seller1), initialBalance);
        assertEq(
            collateralManager.productCollaterals(product),
            requiredCollateral
        );
    }

    function testWithdrawExcessProductCollateralWithZeroPrice() public {
        vm.prank(seller1);
        collateralManager.addProductCollateral{value: amount}(product);

        vm.prank(address(productManager));
        vm.expectRevert("Invalid price");
        collateralManager.withdrawExcessProductCollateral(
            product,
            0,
            quantity,
            seller1
        );
    }

    function testWithdrawExcessProductCollateralWithZeroQuantity() public {
        vm.prank(seller1);
        collateralManager.addProductCollateral{value: amount}(product);

        vm.prank(address(productManager));
        vm.expectRevert("Invalid quantity");
        collateralManager.withdrawExcessProductCollateral(
            product,
            price,
            0,
            seller1
        );
    }

    function testWithdrawExcessProductCollateralFuzzValidInputs(
        uint256 _price,
        uint256 _quantity,
        uint256 _excessAmount
    ) public {
        vm.assume(_price > 0 && _price < type(uint120).max);
        vm.assume(_quantity > 0 && _quantity < type(uint120).max);

        uint requiredCollateral = collateralManager.getRequiredSellerCollateral(
            _price,
            _quantity
        );
        vm.assume(type(uint256).max - requiredCollateral >= _excessAmount);
        uint totalCollateral = requiredCollateral + _excessAmount;

        vm.deal(seller1, totalCollateral);
        vm.prank(seller1);
        collateralManager.addProductCollateral{value: totalCollateral}(product);

        uint initialBalance = collateralManager.balances(seller1);

        vm.prank(address(productManager));
        collateralManager.withdrawExcessProductCollateral(
            product,
            _price,
            _quantity,
            seller1
        );

        assertEq(
            collateralManager.balances(seller1),
            initialBalance + _excessAmount
        );
        assertEq(
            collateralManager.productCollaterals(product),
            requiredCollateral
        );
    }
}
