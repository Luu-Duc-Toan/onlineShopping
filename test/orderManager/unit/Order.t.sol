// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/OrderManagerTestBase.sol";

contract OrderTest is OrderManagerTestBase {
    uint public productCollateral;
    uint public totalCollateral;

    function setUp() public override {
        super.setUp();
        createCompleteProduct(product, price, quantity, seller1);
        productCollateral = collateralManager.getRequiredSellerCollateral(
            price,
            quantity
        );
        totalCollateral = collateralManager.getRequiredCustomerCollateral(
            price,
            quantity
        );
    }

    function testOrderSuccessfulWithNewIndex() public {
        uint initialMaxOrderCount = getMaxOrderCount();
        uint initialCollateralBalance = address(collateralManager).balance;

        vm.deal(customer1, totalCollateral);
        vm.prank(customer1);
        uint orderIndex = orderManager.order{value: totalCollateral}(
            "testProduct",
            quantity
        );

        assertEq(orderIndex, initialMaxOrderCount);
        assertEq(getMaxOrderCount(), initialMaxOrderCount + 1);
        (
            string memory _product,
            uint _orderQuantity,
            uint _orderPrice,
            address _orderSeller,
            address _orderCustomer,
            uint _maxTime,
            address _shippingService,
            uint _shippingFee
        ) = orderManager.orders(orderIndex);
        assertEq(_product, product);
        assertEq(_orderQuantity, quantity);
        assertEq(_orderPrice, price);
        assertEq(_orderSeller, seller1);
        assertEq(_orderCustomer, customer1);
        assertEq(_maxTime, 0);
        assertEq(_shippingService, address(0));
        assertEq(_shippingFee, 0);
        assertEq(
            address(collateralManager).balance,
            initialCollateralBalance + totalCollateral
        );
    }

    function testOrderSuccessfulWithReusedIndex() public {
        createTwoReleaseSlots();

        uint initialMaxOrderCount = orderManager.maxOrderCount();
        console.log(initialMaxOrderCount);
        uint initialCollateralBalance = address(collateralManager).balance;

        vm.deal(customer1, totalCollateral);
        vm.prank(customer1);
        uint orderIndex = orderManager.order{value: totalCollateral}(
            product,
            quantity
        );
        assertEq(orderIndex, 0);
        assertEq(orderManager.maxOrderCount(), initialMaxOrderCount);
        assertEq(orderManager.releaseSlots(0), 1);
        (
            string memory _product,
            uint _orderQuantity,
            uint _orderPrice,
            address _orderSeller,
            address _orderCustomer,
            uint _maxTime,
            address _shippingService,
            uint _shippingFee
        ) = orderManager.orders(orderIndex);
        assertEq(_product, product);
        assertEq(_orderQuantity, quantity);
        assertEq(_orderPrice, price);
        assertEq(_orderSeller, seller1);
        assertEq(_orderCustomer, customer1);
        assertEq(_maxTime, 0);
        assertEq(_shippingService, address(0));
        assertEq(_shippingFee, 0);
        assertEq(
            address(collateralManager).balance,
            initialCollateralBalance + totalCollateral
        );
    }

    function testOrderRevertWithZeroQuantity() public {
        vm.deal(customer1, totalCollateral);
        vm.prank(customer1);
        vm.expectRevert("Quantity must be greater than 0");
        orderManager.order{value: totalCollateral}("testProduct", 0);
    }

    function testOrderRevertWithNonExistentProduct() public {
        vm.deal(customer1, totalCollateral);
        vm.prank(customer1);
        vm.expectRevert("Not enough product quantity");
        orderManager.order{value: totalCollateral}(
            "nonExistentProduct",
            quantity
        );
    }

    function testOrderRevertWithInsufficientQuantity() public {
        uint excessiveQuantity = quantity + 1;
        vm.deal(customer1, totalCollateral);
        vm.prank(customer1);
        vm.expectRevert("Not enough product quantity");
        orderManager.order{value: totalCollateral}(
            "testProduct",
            excessiveQuantity
        );
    }

    function testOrderRevertWithInsufficientPayment() public {
        uint insufficientPayment = totalCollateral - 1;
        vm.deal(customer1, insufficientPayment);
        vm.prank(customer1);
        vm.expectRevert("Invalid customer collateral");
        orderManager.order{value: insufficientPayment}("testProduct", quantity);
    }

    function testOrderRevertWithExcessPayment() public {
        uint excessPayment = totalCollateral + 1 ether;
        vm.deal(customer1, excessPayment);
        vm.prank(customer1);

        vm.expectRevert("Invalid customer collateral");
        orderManager.order{value: excessPayment}("testProduct", quantity);
    }
}
