// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/OrderManagerTestBase.sol";

contract ShippingServiceDisputeTest is OrderManagerTestBase {
    uint public orderIndex;

    function setUp() public override {
        super.setUp();

        orderIndex = createCompleteOrder(
            product,
            price,
            quantity,
            seller1,
            customer1
        );
        setupShippingService(
            shipper1,
            collateralManager.getRequiredShippingServiceCollateral(
                price,
                quantity
            )
        );
        vm.prank(shipper1);
        orderManager.takeOrder(orderIndex);
    }

    function testShippingServiceDisputeSuccessful() public {
        vm.prank(shipper1);
        orderManager.shippingServiceDispute(orderIndex);

        (, , , , address customer, , address service, ) = orderManager.orders(
            orderIndex
        );
        assertEq(customer, customer1);
        assertEq(service, shipper1);
        assertTrue(collateralManager.isOrderDisputed(orderIndex));
    }

    function testShippingServiceDisputeRevertInvalidIndex() public {
        uint overIndex = orderManager.maxOrderCount() + 1;
        vm.prank(customer1);
        vm.expectRevert("Invalid order index");
        orderManager.shippingServiceDispute(overIndex);

        uint invalidIndex = orderManager.getNextOrderIndex();
        vm.prank(customer1);
        vm.expectRevert("Invalid order index");
        orderManager.shippingServiceDispute(invalidIndex);
    }

    function testShippingServiceDisputeRevertNotShippingService() public {
        vm.prank(customer1);
        vm.expectRevert("Only shipping service can dispute");
        orderManager.shippingServiceDispute(orderIndex);
    }

    function testShippingServiceDisputeRevertOrderNotTaken() public {
        uint newOrderIndex = createCompleteOrder(
            "notTaken",
            price,
            quantity,
            seller1,
            customer2
        );

        vm.prank(shipper1);
        vm.expectRevert("Only shipping service can dispute");
        orderManager.shippingServiceDispute(newOrderIndex);
    }

    function testShippingServiceDisputeRevertDeletedOrder() public {
        vm.prank(customer1);
        orderManager.confirmOrder(orderIndex);

        vm.prank(shipper1);
        vm.expectRevert("Invalid order index");
        orderManager.shippingServiceDispute(orderIndex);
    }
}
