// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/CollateralManagerTestBase.sol";

contract CustomerRefundTest is CollateralManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testCustomerRefundSuccess() public {
        uint orderIndex = 0;
        uint requiredSellerCollateral = collateralManager
            .getRequiredSellerCollateral(price, quantity);
        uint requiredCustomerCollateral = collateralManager
            .getRequiredCustomerCollateral(price, quantity);
        uint totalOrderCollateral = requiredSellerCollateral +
            requiredCustomerCollateral;

        vm.deal(address(collateralManager), totalOrderCollateral);
        vm.store(
            address(collateralManager),
            keccak256(abi.encode(orderIndex, uint256(6))), // orderCollaterals mapping at slot 6
            bytes32(totalOrderCollateral)
        );

        uint initialCustomerBalance = collateralManager.balances(customer1);

        vm.prank(address(orderManager));
        collateralManager.customerRefund(orderIndex, customer1);

        assertEq(
            collateralManager.balances(customer1),
            initialCustomerBalance + totalOrderCollateral
        );
        assertEq(collateralManager.orderCollaterals(orderIndex), 0);
    }

    function testCustomerRefundNotOrderManagerReverts() public {
        uint orderIndex = 0;

        vm.expectRevert("Only OrderManager can call this");
        vm.prank(seller1);
        collateralManager.customerRefund(orderIndex, customer1);
    }

    function testCustomerRefundZeroCollateral() public {
        uint orderIndex = 0;
        uint initialCustomerBalance = collateralManager.balances(customer1);

        vm.prank(address(orderManager));
        collateralManager.customerRefund(orderIndex, customer1);

        assertEq(collateralManager.balances(customer1), initialCustomerBalance);
        assertEq(collateralManager.orderCollaterals(orderIndex), 0);
    }

    function testFuzzCustomerRefund(
        uint256 _orderIndex,
        uint256 _collateralAmount
    ) public {
        vm.assume(_orderIndex <= type(uint32).max);
        vm.assume(_collateralAmount <= type(uint128).max);

        if (_collateralAmount > 0) {
            vm.deal(address(collateralManager), _collateralAmount);
            vm.store(
                address(collateralManager),
                keccak256(abi.encode(_orderIndex, uint256(6))),
                bytes32(_collateralAmount)
            );
        }

        uint initialCustomerBalance = collateralManager.balances(customer1);

        vm.prank(address(orderManager));
        collateralManager.customerRefund(_orderIndex, customer1);

        assertEq(
            collateralManager.balances(customer1),
            initialCustomerBalance + _collateralAmount
        );
        assertEq(collateralManager.orderCollaterals(_orderIndex), 0);
    }
}
