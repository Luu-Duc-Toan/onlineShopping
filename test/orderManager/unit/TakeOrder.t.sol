// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/OrderManagerTestBase.sol";

contract TakeOrderTest is OrderManagerTestBase {
    uint public requiredShippingService;
    uint public orderIndex;

    function setUp() public override {
        super.setUp();
        requiredShippingService = collateralManager
            .getRequiredShippingServiceCollateral(price, quantity);
        orderIndex = createCompleteOrder(
            product,
            price,
            quantity,
            seller1,
            customer1
        );
        setupShippingService(shipper1, requiredShippingService);
    }

    function testTakeOrderSuccessful() public {
        vm.prank(shipper1);
        orderManager.takeOrder(orderIndex);

        (, , , , , , address shippingService, ) = orderManager.orders(
            orderIndex
        );
        assertEq(shippingService, shipper1);
    }

    function testTakeOrderRevertInvalidIndex() public {
        createTwoReleaseSlots();

        uint overIndex = orderManager.maxOrderCount() + 1;
        vm.prank(shipper1);
        vm.expectRevert("Invalid order index");
        orderManager.takeOrder(overIndex);

        uint releaseIndex = orderManager.getNextOrderIndex();
        vm.prank(shipper1);
        vm.expectRevert("Invalid order index");
        orderManager.takeOrder(releaseIndex);
    }

    function testTakeOrderRevertAlreadyTaken() public {
        vm.prank(shipper1);
        orderManager.takeOrder(orderIndex);

        vm.prank(shipper2);
        vm.expectRevert("Order already has a shipping service");
        orderManager.takeOrder(orderIndex);
    }

    function testTakeOrderRevertInsufficientShippingServiceCollateral() public {
        uint insufficientShippingServiceCollateral = requiredShippingService -
            1;
        vm.prank(shipper1);
        collateralManager.shippingServiceWithdraw(requiredShippingService);
        setupShippingService(shipper1, insufficientShippingServiceCollateral);

        vm.prank(shipper1);
        vm.expectRevert("Insufficient shipping deposit");
        orderManager.takeOrder(orderIndex);
    }
}
