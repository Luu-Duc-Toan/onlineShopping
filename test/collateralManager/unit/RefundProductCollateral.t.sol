// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/CollateralManagerTestBase.sol";

contract RefundProductCollateralTest is CollateralManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testRefundProductCollateralSuccess() public {
        uint collateralAmount = amount;

        vm.prank(seller1);
        collateralManager.addProductCollateral{value: collateralAmount}(
            product
        );

        uint initialSellerBalance = seller1.balance;
        uint initialContractBalance = address(collateralManager).balance;

        vm.prank(address(productManager));
        collateralManager.refundProductCollateral(seller1, product);

        assertEq(collateralManager.productCollaterals(product), 0);
        assertEq(seller1.balance, initialSellerBalance + collateralAmount);
        assertEq(
            address(collateralManager).balance,
            initialContractBalance - collateralAmount
        );
    }

    function testRefundProductCollateralNotProductManagerReverts() public {
        uint collateralAmount = amount;

        vm.prank(seller1);
        collateralManager.addProductCollateral{value: collateralAmount}(
            product
        );

        vm.expectRevert("Only ProductManager can call this");
        vm.prank(seller1);
        collateralManager.refundProductCollateral(seller1, product);
    }

    function testRefundProductCollateralZeroCollateral() public {
        uint initialSellerBalance = seller1.balance;
        uint initialContractBalance = address(collateralManager).balance;

        vm.prank(address(productManager));
        collateralManager.refundProductCollateral(seller1, product);

        assertEq(collateralManager.productCollaterals(product), 0);
        assertEq(seller1.balance, initialSellerBalance);
        assertEq(address(collateralManager).balance, initialContractBalance);
    }

    function testRefundProductCollateralEmptyProductName() public {
        uint collateralAmount = amount;

        vm.prank(seller1);
        collateralManager.addProductCollateral{value: collateralAmount}("");

        uint initialSellerBalance = seller1.balance;

        vm.prank(address(productManager));
        collateralManager.refundProductCollateral(seller1, "");

        assertEq(collateralManager.productCollaterals(""), 0);
        assertEq(seller1.balance, initialSellerBalance + collateralAmount);
    }

    function testRefundProductCollateralFuzzValidInputs(
        uint256 _collateralAmount
    ) public {
        vm.assume(
            _collateralAmount > 0 && _collateralAmount <= type(uint128).max
        );

        vm.deal(seller1, _collateralAmount + 1 ether);
        vm.prank(seller1);
        collateralManager.addProductCollateral{value: _collateralAmount}(
            product
        );

        uint initialSellerBalance = seller1.balance;

        vm.prank(address(productManager));
        collateralManager.refundProductCollateral(seller1, product);

        assertEq(collateralManager.productCollaterals(product), 0);
        assertEq(seller1.balance, initialSellerBalance + _collateralAmount);
    }
}
