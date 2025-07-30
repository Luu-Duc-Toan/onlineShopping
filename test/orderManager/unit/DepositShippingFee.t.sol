// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/OrderManagerTestBase.sol";

contract DepositShippingFeeTest is OrderManagerTestBase {
    uint public productCollateral;
    uint public totalCollateral;
    uint orderIndex;

    function setUp() public override {
        super.setUp();
        orderIndex = createCompleteOrder(
            product,
            price,
            quantity,
            seller1,
            customer1
        );
        productCollateral = collateralManager.getRequiredSellerCollateral(
            price,
            quantity
        );
        totalCollateral = collateralManager.getRequiredCustomerCollateral(
            price,
            quantity
        );
    }

    function testDepositShippingFeeSuccessful() public {
        uint shippingFee = 0.1 ether;
        uint initialCollateralBalance = address(collateralManager).balance;

        vm.deal(customer1, shippingFee);
        vm.prank(customer1);
        orderManager.depositShippingFee{value: shippingFee}(orderIndex);

        (, , , , , , , uint storedShippingFee) = orderManager.orders(
            orderIndex
        );
        assertEq(storedShippingFee, shippingFee);
        assertEq(
            address(collateralManager).balance,
            initialCollateralBalance + shippingFee
        );
    }

    function testDepositShippingFeeRevertInvalidIndex() public {
        uint shippingFee = 0.1 ether;
        createTwoReleaseSlots();

        uint overIndex = orderManager.maxOrderCount() + 1;
        vm.deal(customer1, shippingFee);
        vm.prank(customer1);
        vm.expectRevert("Invalid order index");
        orderManager.depositShippingFee{value: shippingFee}(overIndex);

        uint invalidIndex = orderManager.getNextOrderIndex();
        vm.deal(customer1, shippingFee);
        vm.prank(customer1);
        vm.expectRevert("Invalid order index");
        orderManager.depositShippingFee{value: shippingFee}(invalidIndex);
    }

    function testDepositShippingFeeZeroAmount() public {
        vm.prank(customer1);
        orderManager.depositShippingFee{value: 0}(orderIndex);

        (, , , , , , , uint storedShippingFee) = orderManager.orders(
            orderIndex
        );
        assertEq(storedShippingFee, 0);
    }

    function testFuzzDepositShippingFee(uint64 fuzzFee) public {
        vm.assume(fuzzFee > 0);
        vm.assume(fuzzFee <= type(uint120).max);

        uint initialCollateralBalance = address(collateralManager).balance;

        vm.deal(customer1, fuzzFee);
        vm.prank(customer1);
        orderManager.depositShippingFee{value: fuzzFee}(orderIndex);

        (, , , , , , , uint storedShippingFee) = orderManager.orders(
            orderIndex
        );
        assertEq(storedShippingFee, fuzzFee);
        assertEq(
            address(collateralManager).balance,
            initialCollateralBalance + fuzzFee
        );
    }
}
