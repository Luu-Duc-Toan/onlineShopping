// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/OrderManagerTestBase.sol";

contract ResolveDisputeTest is OrderManagerTestBase {
    uint public orderIndex;

    function setUp() public override {
        super.setUp();
    }

    function createDisputedOrder(
        string memory productName
    ) internal returns (uint) {
        uint index = createCompleteOrder(
            productName,
            price,
            quantity,
            seller1,
            customer1
        );

        uint shippingDeposit = collateralManager
            .getRequiredShippingServiceCollateral(price, quantity);
        setupShippingService(shipper1, shippingDeposit);

        vm.prank(shipper1);
        orderManager.takeOrder(index);

        vm.prank(shipper1);
        orderManager.shippingServiceDispute(index);

        return index;
    }

    function testResolveDisputeCustomerWins() public {
        orderIndex = createDisputedOrder("customerWinsProduct");

        uint initialCustomerBalance = collateralManager.balances(customer1);
        uint initialSellerBalance = collateralManager.balances(seller1);
        uint initialShipperBalance = collateralManager.balances(shipper1);
        uint orderCollateral = collateralManager.orderCollaterals(orderIndex);

        vm.prank(admin);
        orderManager.resolveDispute(orderIndex, true);

        uint finalReleaseSlotCount = getReleaseSlotCount();
        assertTrue(finalReleaseSlotCount > 0, "Order index not released");
        uint sellerEarnings = price *
            quantity +
            collateralManager.getRequiredSellerCollateral(price, quantity);
        uint customerPayout = orderCollateral - sellerEarnings;
        assertEq(
            collateralManager.balances(customer1),
            initialCustomerBalance + customerPayout
        );
        assertEq(
            collateralManager.balances(seller1),
            initialSellerBalance + sellerEarnings
        );
        assertEq(collateralManager.balances(shipper1), initialShipperBalance);
        assertEq(collateralManager.orderCollaterals(orderIndex), 0);
        assertFalse(collateralManager.isOrderDisputed(orderIndex));
    }

    function testResolveDisputeShipperWins() public {
        orderIndex = createDisputedOrder("shipperWinsProduct");

        uint initialCustomerBalance = collateralManager.balances(customer1);
        uint initialSellerBalance = collateralManager.balances(seller1);
        uint initialShipperBalance = collateralManager.balances(shipper1);
        uint orderCollateral = collateralManager.orderCollaterals(orderIndex);

        vm.prank(admin);
        orderManager.resolveDispute(orderIndex, false);

        uint sellerEarnings = price *
            quantity +
            collateralManager.getRequiredSellerCollateral(price, quantity);
        uint shipperPayout = orderCollateral - sellerEarnings;

        assertEq(collateralManager.balances(customer1), initialCustomerBalance); // No change
        assertEq(
            collateralManager.balances(seller1),
            initialSellerBalance + sellerEarnings
        );
        assertEq(
            collateralManager.balances(shipper1),
            initialShipperBalance + shipperPayout
        );
        assertEq(collateralManager.orderCollaterals(orderIndex), 0);
        assertFalse(collateralManager.isOrderDisputed(orderIndex));
    }

    function testResolveDisputeRevertNotOwner() public {
        orderIndex = createDisputedOrder(product);

        vm.prank(customer1);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                customer1
            )
        );
        orderManager.resolveDispute(orderIndex, true);
    }

    function testResolveDisputeRevertInvalidIndex() public {
        uint overIndex = orderManager.maxOrderCount() + 1;
        vm.prank(customer1);
        vm.expectRevert("Invalid order index");
        orderManager.resolveDispute(overIndex, true);

        uint invalidIndex = orderManager.getNextOrderIndex();
        vm.prank(customer1);
        vm.expectRevert("Invalid order index");
        orderManager.resolveDispute(invalidIndex, true);
    }

    function testResolveDisputeRevertOrderNotDisputed() public {
        uint newOrderIndex = createCompleteOrder(
            "newProduct",
            price,
            quantity,
            seller1,
            customer2
        );

        uint shippingDeposit = collateralManager
            .getRequiredShippingServiceCollateral(price, quantity);
        setupShippingService(shipper2, shippingDeposit);

        vm.prank(shipper2);
        orderManager.takeOrder(newOrderIndex);

        vm.prank(admin);
        vm.expectRevert("Order is not disputed");
        orderManager.resolveDispute(newOrderIndex, true);
    }

    function testResolveDisputeRevertOrderDeleted() public {
        orderIndex = createDisputedOrder("deletedOrderProduct");

        vm.prank(admin);
        orderManager.resolveDispute(orderIndex, true);

        vm.prank(admin);
        vm.expectRevert("Invalid order index");
        orderManager.resolveDispute(orderIndex, true);
    }
}
