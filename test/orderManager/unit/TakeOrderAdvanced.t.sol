// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.19;

// import "../base/OrderManagerTestBase.sol";

// contract TakeOrderAdvancedTest is OrderManagerTestBase {
//     uint public productCollateral;
//     uint public totalCollateral;

//     function setUp() public override {
//         super.setUp();
//         createCompleteProduct(product, price, quantity, seller1);
//         productCollateral = collateralManager.getRequiredSellerCollateral(
//             price,
//             quantity
//         );
//         totalCollateral = collateralManager.getRequiredCustomerCollateral(
//             price,
//             quantity
//         );
//     }

//     function testTakeOrderWithComplexVmStoreSetup() public {
//         // Setup complex state with vm.store
//         // Simulate a scenario where we have:
//         // - maxOrderCount = 5
//         // - releaseSlots = [0, 2, 4] (3 released slots)
//         // - Active orders at indices 1 and 3

//         vm.store(
//             address(orderManager),
//             bytes32(uint256(3)),
//             bytes32(uint256(5))
//         ); // maxOrderCount = 5
//         vm.store(
//             address(orderManager),
//             bytes32(uint256(4)),
//             bytes32(uint256(3))
//         ); // releaseSlots.length = 3
//         vm.store(
//             address(orderManager),
//             bytes32(uint256(5)),
//             bytes32(uint256(0))
//         ); // releaseSlots[0] = 0
//         vm.store(
//             address(orderManager),
//             bytes32(uint256(6)),
//             bytes32(uint256(2))
//         ); // releaseSlots[1] = 2
//         vm.store(
//             address(orderManager),
//             bytes32(uint256(7)),
//             bytes32(uint256(4))
//         ); // releaseSlots[2] = 4

//         // Create orders that will reuse the released slots
//         createCompleteProduct("product1", price, quantity, seller1);
//         createCompleteProduct("product2", price, quantity, seller1);
//         createCompleteProduct("product3", price, quantity, seller1);

//         vm.deal(customer1, totalCollateral * 3);

//         // Create three orders (should use slots 4, 2, 0 in LIFO order)
//         vm.prank(customer1);
//         uint orderIndex1 = orderManager.order{value: totalCollateral}(
//             "product1",
//             quantity
//         );
//         assertEq(orderIndex1, 4);

//         vm.prank(customer1);
//         uint orderIndex2 = orderManager.order{value: totalCollateral}(
//             "product2",
//             quantity
//         );
//         assertEq(orderIndex2, 2);

//         vm.prank(customer1);
//         uint orderIndex3 = orderManager.order{value: totalCollateral}(
//             "product3",
//             quantity
//         );
//         assertEq(orderIndex3, 0);

//         // Now test takeOrder on these reused indices
//         vm.prank(shipper1);
//         orderManager.takeOrder(orderIndex1); // Take order at index 4

//         vm.prank(shipper2);
//         orderManager.takeOrder(orderIndex2); // Take order at index 2

//         vm.prank(shipper1);
//         orderManager.takeOrder(orderIndex3); // Take order at index 0

//         // Verify all orders were taken correctly
//         (, , , , , , address service1, ) = orderManager.orders(orderIndex1);
//         (, , , , , , address service2, ) = orderManager.orders(orderIndex2);
//         (, , , , , , address service3, ) = orderManager.orders(orderIndex3);

//         assertEq(service1, shipper1);
//         assertEq(service2, shipper2);
//         assertEq(service3, shipper1);
//     }

//     function testTakeOrderWithVmStoreAfterPartialCompletion() public {
//         // Simulate a scenario where some orders were completed and we want to test
//         // takeOrder on newly created orders using released slots

//         // Setup: maxOrderCount = 3, releaseSlots = [1] (one released slot)
//         vm.store(
//             address(orderManager),
//             bytes32(uint256(3)),
//             bytes32(uint256(3))
//         ); // maxOrderCount = 3
//         vm.store(
//             address(orderManager),
//             bytes32(uint256(4)),
//             bytes32(uint256(1))
//         ); // releaseSlots.length = 1
//         vm.store(
//             address(orderManager),
//             bytes32(uint256(5)),
//             bytes32(uint256(1))
//         ); // releaseSlots[0] = 1

//         // Create order that will reuse slot 1
//         createCompleteProduct("reuseProduct", price * 2, quantity, seller2);
//         vm.deal(customer2, price * 2 * quantity);
//         vm.prank(customer2);
//         uint reusedOrderIndex = orderManager.order{value: price * 2 * quantity}(
//             "reuseProduct",
//             quantity
//         );

//         assertEq(reusedOrderIndex, 1); // Should reuse slot 1

//         // Test takeOrder on this reused slot
//         vm.prank(shipper2);
//         orderManager.takeOrder(reusedOrderIndex);

//         // Verify the order was taken correctly
//         (
//             string memory productName,
//             uint orderQuantity,
//             uint orderPrice,
//             address orderSeller,
//             address orderCustomer,
//             uint maxTime,
//             address shippingService,
//             uint shippingFee
//         ) = orderManager.orders(reusedOrderIndex);

//         assertEq(productName, "reuseProduct");
//         assertEq(orderQuantity, quantity);
//         assertEq(orderPrice, price * 2);
//         assertEq(orderSeller, seller2);
//         assertEq(orderCustomer, customer2);
//         assertEq(maxTime, 0);
//         assertEq(shippingService, shipper2);
//         assertEq(shippingFee, 0);
//     }

//     function testTakeOrderSequenceWithVmStore() public {
//         // Test a complete workflow: setup with vm.store -> create orders -> take orders -> complete some orders

//         // Initial setup: clean state
//         vm.store(
//             address(orderManager),
//             bytes32(uint256(3)),
//             bytes32(uint256(0))
//         ); // maxOrderCount = 0
//         vm.store(
//             address(orderManager),
//             bytes32(uint256(4)),
//             bytes32(uint256(0))
//         ); // releaseSlots.length = 0

//         // Create three orders normally
//         uint orderIndex1 = createCompleteOrder(
//             "seq1",
//             price,
//             quantity,
//             seller1,
//             customer1
//         );
//         uint orderIndex2 = createCompleteOrder(
//             "seq2",
//             price,
//             quantity,
//             seller1,
//             customer1
//         );
//         uint orderIndex3 = createCompleteOrder(
//             "seq3",
//             price,
//             quantity,
//             seller1,
//             customer1
//         );

//         assertEq(orderIndex1, 0);
//         assertEq(orderIndex2, 1);
//         assertEq(orderIndex3, 2);

//         // Take all orders
//         vm.prank(shipper1);
//         orderManager.takeOrder(orderIndex1);

//         vm.prank(shipper2);
//         orderManager.takeOrder(orderIndex2);

//         vm.prank(shipper1);
//         orderManager.takeOrder(orderIndex3);

//         // Complete first and third orders (this will add slots to releaseSlots)
//         vm.prank(customer1);
//         orderManager.confirmOrder(orderIndex1); // Releases slot 0

//         vm.prank(customer1);
//         orderManager.confirmOrder(orderIndex3); // Releases slot 2

//         // Now create new orders that should reuse the released slots
//         createCompleteProduct("newSeq1", price, quantity, seller2);
//         createCompleteProduct("newSeq2", price, quantity, seller2);

//         vm.deal(customer2, totalCollateral * 2);

//         vm.prank(customer2);
//         uint newOrderIndex1 = orderManager.order{value: totalCollateral}(
//             "newSeq1",
//             quantity
//         );

//         vm.prank(customer2);
//         uint newOrderIndex2 = orderManager.order{value: totalCollateral}(
//             "newSeq2",
//             quantity
//         );

//         // These should reuse slots in LIFO order (2, then 0)
//         assertEq(newOrderIndex1, 2);
//         assertEq(newOrderIndex2, 0);

//         // Take the new orders
//         vm.prank(shipper2);
//         orderManager.takeOrder(newOrderIndex1);

//         vm.prank(shipper1);
//         orderManager.takeOrder(newOrderIndex2);

//         // Verify everything is correct
//         (, , , , , , address service1, ) = orderManager.orders(newOrderIndex1);
//         (, , , , , , address service2, ) = orderManager.orders(newOrderIndex2);

//         assertEq(service1, shipper2);
//         assertEq(service2, shipper1);
//     }

//     function testTakeOrderFailuresWithVmStore() public {
//         // Test various failure scenarios with vm.store setup

//         // Setup: maxOrderCount = 2, releaseSlots = [0, 1] (all slots released)
//         vm.store(
//             address(orderManager),
//             bytes32(uint256(3)),
//             bytes32(uint256(2))
//         ); // maxOrderCount = 2
//         vm.store(
//             address(orderManager),
//             bytes32(uint256(4)),
//             bytes32(uint256(2))
//         ); // releaseSlots.length = 2
//         vm.store(
//             address(orderManager),
//             bytes32(uint256(5)),
//             bytes32(uint256(0))
//         ); // releaseSlots[0] = 0
//         vm.store(
//             address(orderManager),
//             bytes32(uint256(6)),
//             bytes32(uint256(1))
//         ); // releaseSlots[1] = 1

//         // Try to take order at index 0 (should fail - no order exists)
//         vm.prank(shipper1);
//         vm.expectRevert("Invalid order index");
//         orderManager.takeOrder(0);

//         // Try to take order at index 1 (should fail - no order exists)
//         vm.prank(shipper1);
//         vm.expectRevert("Invalid order index");
//         orderManager.takeOrder(1);

//         // Try to take order beyond maxOrderCount
//         vm.prank(shipper1);
//         vm.expectRevert("Invalid order index");
//         orderManager.takeOrder(2);

//         // Now create one order and test proper taking
//         createCompleteProduct("testProduct", price, quantity, seller1);
//         vm.deal(customer1, totalCollateral);
//         vm.prank(customer1);
//         uint orderIndex = orderManager.order{value: totalCollateral}(
//             "testProduct",
//             quantity
//         );

//         assertEq(orderIndex, 1); // Should reuse slot 1 (LIFO)

//         // This should work
//         vm.prank(shipper1);
//         orderManager.takeOrder(orderIndex);

//         // Try to take the same order again (should fail)
//         vm.prank(shipper2);
//         vm.expectRevert("Order already has a shipping service");
//         orderManager.takeOrder(orderIndex);
//     }

//     function testTakeOrderWithMixedOperationsAndVmStore() public {
//         // Test takeOrder combined with other operations using vm.store setup

//         // Setup initial state
//         vm.store(
//             address(orderManager),
//             bytes32(uint256(3)),
//             bytes32(uint256(1))
//         ); // maxOrderCount = 1
//         vm.store(
//             address(orderManager),
//             bytes32(uint256(4)),
//             bytes32(uint256(0))
//         ); // releaseSlots.length = 0

//         // Create order
//         createCompleteProduct("mixedOps", price, quantity, seller1);
//         vm.deal(customer1, totalCollateral);
//         vm.prank(customer1);
//         uint orderIndex = orderManager.order{value: totalCollateral}(
//             "mixedOps",
//             quantity
//         );

//         // Set max time
//         uint maxTime = block.timestamp + 10 days;
//         vm.prank(admin);
//         orderManager.setOrderMaxTime(orderIndex, maxTime);

//         // Deposit shipping fee
//         uint shippingFee = 0.2 ether;
//         vm.deal(customer1, shippingFee);
//         vm.prank(customer1);
//         orderManager.depositShippingFee{value: shippingFee}(orderIndex);

//         // Take order
//         vm.prank(shipper1);
//         orderManager.takeOrder(orderIndex);

//         // Verify all operations worked together
//         (
//             string memory productName,
//             uint orderQuantity,
//             uint orderPrice,
//             address orderSeller,
//             address orderCustomer,
//             uint storedMaxTime,
//             address shippingService,
//             uint storedShippingFee
//         ) = orderManager.orders(orderIndex);

//         assertEq(productName, "mixedOps");
//         assertEq(orderQuantity, quantity);
//         assertEq(orderPrice, price);
//         assertEq(orderSeller, seller1);
//         assertEq(orderCustomer, customer1);
//         assertEq(storedMaxTime, maxTime);
//         assertEq(shippingService, shipper1);
//         assertEq(storedShippingFee, shippingFee);
//     }

//     function testTakeOrderGasComparisonNewVsReused() public {
//         // Test gas difference between taking orders at new vs reused indices

//         // Create order at new index
//         uint newOrderIndex = createCompleteOrder(
//             "newIndex",
//             price,
//             quantity,
//             seller1,
//             customer1
//         );

//         // Measure gas for taking order at new index
//         vm.prank(shipper1);
//         uint gasBefore1 = gasleft();
//         orderManager.takeOrder(newOrderIndex);
//         uint gasUsedNew = gasBefore1 - gasleft();

//         // Complete the order to release the slot
//         vm.prank(customer1);
//         orderManager.confirmOrder(newOrderIndex);

//         // Create another order that will reuse the slot
//         createCompleteProduct("reusedIndex", price, quantity, seller1);
//         vm.deal(customer2, totalCollateral);
//         vm.prank(customer2);
//         uint reusedOrderIndex = orderManager.order{value: totalCollateral}(
//             "reusedIndex",
//             quantity
//         );

//         // Should reuse the same index
//         assertEq(reusedOrderIndex, newOrderIndex);

//         // Measure gas for taking order at reused index
//         vm.prank(shipper2);
//         uint gasBefore2 = gasleft();
//         orderManager.takeOrder(reusedOrderIndex);
//         uint gasUsedReused = gasBefore2 - gasleft();

//         console.log("Gas used for takeOrder (new index):", gasUsedNew);
//         console.log("Gas used for takeOrder (reused index):", gasUsedReused);

//         // Both should be reasonably efficient
//         assertLt(gasUsedNew, 150000);
//         assertLt(gasUsedReused, 150000);

//         // The difference should be minimal since takeOrder doesn't directly interact with slot management
//         uint gassDifference = gasUsedNew > gasUsedReused
//             ? gasUsedNew - gasUsedReused
//             : gasUsedReused - gasUsedNew;
//         assertLt(gassDifference, 10000); // Should be less than 10k gas difference
//     }

//     function testFuzzTakeOrderWithVmStoreSetup(
//         uint8 numOrders,
//         uint8 numReleased
//     ) public {
//         vm.assume(numOrders > 0 && numOrders <= 10);
//         vm.assume(numReleased <= numOrders);

//         // Setup state with vm.store
//         vm.store(
//             address(orderManager),
//             bytes32(uint256(3)),
//             bytes32(uint256(numOrders))
//         ); // maxOrderCount
//         vm.store(
//             address(orderManager),
//             bytes32(uint256(4)),
//             bytes32(uint256(numReleased))
//         ); // releaseSlots.length

//         // Setup released slots
//         for (uint i = 0; i < numReleased; i++) {
//             vm.store(
//                 address(orderManager),
//                 bytes32(uint256(5 + i)),
//                 bytes32(uint256(i))
//             );
//         }

//         // Create a product and order
//         createCompleteProduct("fuzzProduct", price, quantity, seller1);
//         vm.deal(customer1, totalCollateral);
//         vm.prank(customer1);
//         uint orderIndex = orderManager.order{value: totalCollateral}(
//             "fuzzProduct",
//             quantity
//         );

//         // Take the order
//         vm.prank(shipper1);
//         orderManager.takeOrder(orderIndex);

//         // Verify the order was taken
//         (, , , , , , address shippingService, ) = orderManager.orders(
//             orderIndex
//         );
//         assertEq(shippingService, shipper1);

//         // Verify the index is valid
//         assertLt(orderIndex, numOrders);
//     }
// }
