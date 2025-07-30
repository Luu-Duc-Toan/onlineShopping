// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/OrderManagerTestBase.sol";

contract SetOrderMaxTimeTest is OrderManagerTestBase {
    uint orderIndex;

    function setUp() public override {
        super.setUp();
        orderIndex = 0;
        orderIndex = createCompleteOrder(
            product,
            price,
            quantity,
            seller1,
            customer1
        );
    }

    function testSetOrderMaxTimeSuccessful() public {
        uint newMaxTime = block.timestamp + 7 days;

        vm.prank(admin);
        orderManager.setOrderMaxTime(orderIndex, newMaxTime);

        (, , , , , uint maxTime, , ) = orderManager.orders(orderIndex);
        assertEq(maxTime, newMaxTime);
    }

    function testSetOrderMaxTimeRevertInvalidIndex() public {
        uint newMaxTime = block.timestamp + 7 days;

        uint overIndex = orderManager.maxOrderCount() + 1;
        vm.prank(admin);
        vm.expectRevert("Invalid order index");
        orderManager.setOrderMaxTime(overIndex, newMaxTime);

        createTwoReleaseSlots();
        uint releaseIndex = orderManager.getNextOrderIndex();
        vm.prank(admin);
        vm.expectRevert("Invalid order index");
        orderManager.setOrderMaxTime(releaseIndex, newMaxTime);
    }

    function testSetOrderMaxTimeRevertNotOwner() public {
        uint newMaxTime = block.timestamp + 7 days;

        console.log(customer1);
        console.log(admin);
        vm.prank(customer1);
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                customer1
            )
        );
        orderManager.setOrderMaxTime(orderIndex, newMaxTime);
    }

    function testSetOrderMaxTimeZeroValue() public {
        vm.prank(admin);
        orderManager.setOrderMaxTime(orderIndex, 0);

        (, , , , , uint maxTime, , ) = orderManager.orders(orderIndex);
        assertEq(maxTime, 0);
    }

    function testFuzzSetOrderMaxTime(uint128 fuzzMaxTime) public {
        vm.assume(
            fuzzMaxTime > block.timestamp &&
                fuzzMaxTime < block.timestamp + 365 days
        );

        vm.prank(admin);
        orderManager.setOrderMaxTime(orderIndex, fuzzMaxTime);

        (, , , , , uint maxTime, , ) = orderManager.orders(orderIndex);
        assertEq(maxTime, fuzzMaxTime);
    }
}
