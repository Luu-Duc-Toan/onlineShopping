// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/CollateralManagerTestBase.sol";

contract TakeOrderTest is CollateralManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testTakeOrderSuccess() public {
        uint orderIndex = 0;
        uint requiredShippingCollateral = collateralManager
            .getRequiredShippingServiceCollateral(price, quantity);

        setupShippingService(shipper1, requiredShippingCollateral);

        uint initialOrderCollateral = collateralManager.orderCollaterals(
            orderIndex
        );
        uint initialShippingDeposit = collateralManager.shippingDeposits(
            shipper1
        );

        vm.prank(address(orderManager));
        collateralManager.takeOrder(orderIndex, price, quantity, shipper1);

        assertEq(
            collateralManager.orderCollaterals(orderIndex),
            initialOrderCollateral + requiredShippingCollateral
        );
        assertEq(
            collateralManager.shippingDeposits(shipper1),
            initialShippingDeposit - requiredShippingCollateral
        );
    }

    function testTakeOrderNotOrderManagerReverts() public {
        uint orderIndex = 0;
        uint requiredShippingCollateral = collateralManager
            .getRequiredShippingServiceCollateral(price, quantity);

        setupShippingService(shipper1, requiredShippingCollateral);

        vm.expectRevert("Only OrderManager can call this");
        vm.prank(seller1);
        collateralManager.takeOrder(orderIndex, price, quantity, shipper1);
    }

    function testTakeOrderInsufficientShippingDepositReverts() public {
        uint orderIndex = 0;
        uint requiredShippingCollateral = collateralManager
            .getRequiredShippingServiceCollateral(price, quantity);
        uint insufficientDeposit = requiredShippingCollateral - 1;

        setupShippingService(shipper1, insufficientDeposit);

        vm.expectRevert("Insufficient shipping deposit");
        vm.prank(address(orderManager));
        collateralManager.takeOrder(orderIndex, price, quantity, shipper1);
    }

    function testTakeOrderNoShippingDeposit() public {
        uint orderIndex = 0;

        vm.expectRevert("Insufficient shipping deposit");
        vm.prank(address(orderManager));
        collateralManager.takeOrder(orderIndex, price, quantity, shipper1);
    }

    function testTakeOrderFuzzValidInputs(
        uint256 _price,
        uint256 _quantity
    ) public {
        console.log(
            "Fuzzing takeOrder with price:",
            _price,
            "and quantity:",
            _quantity
        );
        uint _orderIndex = 0;
        vm.assume(_price > 0 && _price <= type(uint120).max);
        vm.assume(_quantity > 0 && _quantity <= type(uint120).max);

        uint requiredShippingCollateral = collateralManager
            .getRequiredShippingServiceCollateral(_price, _quantity);
        vm.assume(requiredShippingCollateral > 0);

        setupShippingService(shipper1, requiredShippingCollateral);

        uint initialOrderCollateral = collateralManager.orderCollaterals(
            _orderIndex
        );
        uint initialShippingDeposit = collateralManager.shippingDeposits(
            shipper1
        );

        vm.prank(address(orderManager));
        collateralManager.takeOrder(_orderIndex, _price, _quantity, shipper1);

        assertEq(
            collateralManager.orderCollaterals(_orderIndex),
            initialOrderCollateral + requiredShippingCollateral
        );
        assertEq(
            collateralManager.shippingDeposits(shipper1),
            initialShippingDeposit - requiredShippingCollateral
        );
    }
}
