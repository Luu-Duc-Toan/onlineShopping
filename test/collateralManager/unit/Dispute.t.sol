// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/CollateralManagerTestBase.sol";

contract DisputeTest is CollateralManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testDisputeSuccess() public {
        uint orderIndex = 0;

        assertEq(collateralManager.isOrderDisputed(orderIndex), false);
        vm.prank(address(orderManager));
        collateralManager.dispute(orderIndex);
        assertEq(collateralManager.isOrderDisputed(orderIndex), true);
    }

    function testDisputeNotOrderManagerReverts() public {
        uint orderIndex = 0;

        vm.expectRevert("Only OrderManager can call this");
        vm.prank(seller1);
        collateralManager.dispute(orderIndex);
    }

    function testDisputeAlreadyDisputedReverts() public {
        uint orderIndex = 0;

        vm.prank(address(orderManager));
        collateralManager.dispute(orderIndex);

        vm.expectRevert("Order already disputed");
        vm.prank(address(orderManager));
        collateralManager.dispute(orderIndex);
    }
}
