// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/OrderManagerTestBase.sol";

contract CustomerDisputeTest is OrderManagerTestBase {
    uint public requiredSellerCollateral;
    uint public requiredCustomerCollateral;
    uint public orderIndex;

    function setUp() public override {
        super.setUp();
        requiredSellerCollateral = collateralManager
            .getRequiredSellerCollateral(price, quantity);
        requiredCustomerCollateral = collateralManager
            .getRequiredCustomerCollateral(price, quantity);

        orderIndex = createCompleteOrder(
            product,
            price,
            quantity,
            seller1,
            customer1
        );
        uint pastMaxTime = block.timestamp - 1;
        vm.prank(admin);
        orderManager.setOrderMaxTime(orderIndex, pastMaxTime);
    }

    function testCustomerDisputeWithShippingService() public {
        uint requiredShippingService = collateralManager
            .getRequiredShippingServiceCollateral(price, quantity);
        setupShippingService(shipper1, requiredShippingService);
        vm.prank(shipper1);
        orderManager.takeOrder(orderIndex);

        vm.prank(customer1);
        orderManager.customerDispute(orderIndex);

        (, , , , address customer, , address service, ) = orderManager.orders(
            orderIndex
        );
        assertEq(customer, customer1);
        assertEq(service, shipper1);
        assertTrue(collateralManager.isOrderDisputed(orderIndex));
    }

    function testCustomerDisputeWithoutShippingService() public {
        uint initialReleaseSlotCount = getReleaseSlotCount();

        vm.prank(customer1);
        orderManager.customerDispute(orderIndex);

        vm.expectRevert("Invalid order index");
        orderManager.takeOrder(orderIndex);
        assertEq(getReleaseSlotCount(), initialReleaseSlotCount + 1);
    }

    function testCustomerDisputeRevertNotCustomer() public {
        vm.prank(seller1);
        vm.expectRevert("Only customer can dispute");
        orderManager.customerDispute(orderIndex);
    }

    function testCustomerDisputeRevertInvalidIndex() public {
        uint overIndex = orderManager.maxOrderCount() + 1;
        vm.prank(customer1);
        vm.expectRevert("Invalid order index");
        orderManager.customerDispute(overIndex);

        uint invalidIndex = orderManager.getNextOrderIndex();
        vm.prank(customer1);
        vm.expectRevert("Invalid order index");
        orderManager.customerDispute(invalidIndex);
    }

    function testCustomerDisputeRevertDisputePeriodNotStarted() public {
        uint futureTime = block.timestamp + 7 days;
        vm.prank(admin);
        orderManager.setOrderMaxTime(orderIndex, futureTime);

        vm.prank(customer1);
        vm.expectRevert("Dispute period not yet started");
        orderManager.customerDispute(orderIndex);
    }
}
