// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/OrderManagerTestBase.sol";

contract GetNextOrderIndexTest is OrderManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testGetNextOrderIndexSuccessWithoutReleaseSlots() public view {
        uint orderIndex = orderManager.getNextOrderIndex();
        uint maxOrderCount = orderManager.maxOrderCount();

        assertEq(orderIndex, maxOrderCount);
    }

    function testGetNextOrderIndexWithReleaseSlots() public {
        createTwoReleaseSlots();
        uint expectedIndex = 0;

        uint orderIndex = orderManager.getNextOrderIndex();
        assertEq(orderIndex, expectedIndex);
        assertEq(orderManager.releaseSlots(0), expectedIndex);
        assertNotEq(orderIndex, orderManager.maxOrderCount());
    }
}
