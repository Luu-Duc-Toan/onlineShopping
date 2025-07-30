// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/CollateralManagerTestBase.sol";

contract DepositShippingFeeTest is CollateralManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testDepositShippingFeeSuccess() public {
        uint orderIndex = 0;
        uint shippingFee = amount;

        uint initialOrderCollateral = collateralManager.orderCollaterals(
            orderIndex
        );

        vm.deal(address(orderManager), shippingFee + 1 ether);
        vm.prank(address(orderManager));
        collateralManager.depositShippingFee{value: shippingFee}(orderIndex);

        assertEq(
            collateralManager.orderCollaterals(orderIndex),
            initialOrderCollateral + shippingFee
        );
    }

    function testDepositShippingFeeNotOrderManagerReverts() public {
        uint orderIndex = 0;
        uint shippingFee = amount;

        vm.expectRevert("Only OrderManager can call this");
        vm.prank(seller1);
        collateralManager.depositShippingFee{value: shippingFee}(orderIndex);
    }

    function testDepositShippingFeeZeroValue() public {
        uint orderIndex = 0;

        uint initialOrderCollateral = collateralManager.orderCollaterals(
            orderIndex
        );

        vm.prank(address(orderManager));
        collateralManager.depositShippingFee{value: 0}(orderIndex);

        assertEq(
            collateralManager.orderCollaterals(orderIndex),
            initialOrderCollateral
        );
    }

    function testDepositShippingFeeFuzzValidInputs(
        uint256 _orderIndex,
        uint256 _shippingFee
    ) public {
        vm.assume(_orderIndex <= type(uint128).max);
        vm.assume(_shippingFee > 0 && _shippingFee <= type(uint128).max);

        uint initialOrderCollateral = collateralManager.orderCollaterals(
            _orderIndex
        );

        vm.deal(address(orderManager), _shippingFee + 1 ether);
        vm.prank(address(orderManager));
        collateralManager.depositShippingFee{value: _shippingFee}(_orderIndex);

        assertEq(
            collateralManager.orderCollaterals(_orderIndex),
            initialOrderCollateral + _shippingFee
        );
    }
}
