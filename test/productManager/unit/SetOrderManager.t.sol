// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/ProductManagerTestBase.sol";

contract SetOrderManagerTest is ProductManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testSetOrderManagerSuccess() public {
        address newOrderManager = makeAddr("newOrderManager");

        vm.prank(address(collateralManager));
        productManager.setOrderManager(newOrderManager);

        assertEq(productManager.orderManager(), newOrderManager);
    }

    function testSetOrderManagerNotCollateralManagerReverts() public {
        address newOrderManager = makeAddr("newOrderManager");

        vm.expectRevert("Only CollateralManager can call this");
        vm.prank(seller1);
        productManager.setOrderManager(newOrderManager);
    }

    function testSetOrderManagerZeroAddressReverts() public {
        vm.expectRevert("Invalid OrderManager address");
        vm.prank(address(collateralManager));
        productManager.setOrderManager(address(0));
    }

    function testSetOrderManagerMultipleTimes() public {
        address firstOrderManager = makeAddr("firstOrderManager");
        address secondOrderManager = makeAddr("secondOrderManager");

        vm.prank(address(collateralManager));
        productManager.setOrderManager(firstOrderManager);
        assertEq(productManager.orderManager(), firstOrderManager);

        vm.prank(address(collateralManager));
        productManager.setOrderManager(secondOrderManager);
        assertEq(productManager.orderManager(), secondOrderManager);
    }

    function testFuzzSetOrderManager(address _newOrderManager) public {
        vm.assume(_newOrderManager != address(0));

        vm.prank(address(collateralManager));
        productManager.setOrderManager(_newOrderManager);

        assertEq(productManager.orderManager(), _newOrderManager);
    }
}
