// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/OrderManagerTestBase.sol";

contract ConfirmOrderTest is OrderManagerTestBase {
    uint public orderIndex;

    function setUp() public override {
        super.setUp();
        uint requiredShippingService = collateralManager
            .getRequiredShippingServiceCollateral(price, quantity);

        orderIndex = createCompleteOrder(
            product,
            price,
            quantity,
            seller1,
            customer1
        );

        setupShippingService(shipper1, requiredShippingService);
        vm.prank(shipper1);
        orderManager.takeOrder(orderIndex);
    }

    function testConfirmOrderSuccessful() public {
        uint initialReleaseSlotCount = getReleaseSlotCount();

        vm.prank(customer1);
        orderManager.confirmOrder(orderIndex);

        assertEq(getReleaseSlotCount(), initialReleaseSlotCount + 1);
        vm.expectRevert("Invalid order index");
        orderManager.takeOrder(orderIndex);
    }

    function testConfirmOrderRevertNotCustomer() public {
        vm.prank(customer2);
        vm.expectRevert("Only customer can confirm");
        orderManager.confirmOrder(orderIndex);
    }

    function testConfirmOrderRevertInvalidIndex() public {
        createTwoReleaseSlots();

        uint overIndex = orderManager.maxOrderCount() + 1;
        vm.prank(customer1);
        vm.expectRevert("Invalid order index");
        orderManager.confirmOrder(overIndex);

        uint invalidIndex = orderManager.getNextOrderIndex();
        vm.prank(customer1);
        vm.expectRevert("Invalid order index");
        orderManager.confirmOrder(invalidIndex);
    }

    function testConfirmOrderRevertNotTaken() public {
        uint newOrderIndex = createCompleteOrder(
            "notTaken",
            price,
            quantity,
            seller1,
            customer2
        );

        vm.prank(customer2);
        vm.expectRevert("Order not taken by shipping service");
        orderManager.confirmOrder(newOrderIndex);
    }

    function testConfirmOrderRevertAlreadyConfirmed() public {
        vm.prank(customer1);
        orderManager.confirmOrder(orderIndex);

        vm.prank(customer1);
        vm.expectRevert("Invalid order index");
        orderManager.confirmOrder(orderIndex);
    }
}
