// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/CollateralManagerTestBase.sol";

contract ConfirmTest is CollateralManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testConfirmSuccess() public {
        uint orderIndex = 0;
        uint requiredSellerCollateral = collateralManager
            .getRequiredSellerCollateral(price, quantity);
        uint requiredCustomerCollateral = collateralManager
            .getRequiredCustomerCollateral(price, quantity);
        uint requiredShippingCollateral = collateralManager
            .getRequiredShippingServiceCollateral(price, quantity);
        uint shippingFee = amount;

        uint totalOrderCollateral = requiredSellerCollateral +
            requiredCustomerCollateral +
            requiredShippingCollateral +
            shippingFee;

        vm.deal(address(collateralManager), totalOrderCollateral);
        vm.store(
            address(collateralManager),
            keccak256(abi.encode(orderIndex, uint256(6))), // orderCollaterals mapping at slot 6
            bytes32(totalOrderCollateral)
        );

        uint sellerEarning = requiredSellerCollateral + price * quantity;
        uint shippingEarning = totalOrderCollateral - sellerEarning;

        uint initialSellerBalance = collateralManager.balances(seller1);
        uint initialShippingBalance = collateralManager.balances(shipper1);

        vm.prank(address(orderManager));
        collateralManager.confirm(
            orderIndex,
            price,
            quantity,
            seller1,
            shipper1
        );

        assertEq(collateralManager.orderCollaterals(orderIndex), 0);
        assertEq(
            collateralManager.balances(seller1),
            initialSellerBalance + sellerEarning
        );
        assertEq(
            collateralManager.balances(shipper1),
            initialShippingBalance + shippingEarning
        );
    }

    function testConfirmNotOrderManagerReverts() public {
        uint orderIndex = 0;

        vm.expectRevert("Only OrderManager can call this");
        vm.prank(seller1);
        collateralManager.confirm(
            orderIndex,
            price,
            quantity,
            seller1,
            shipper1
        );
    }

    function testConfirmDisputedOrderReverts() public {
        uint orderIndex = 0;
        uint requiredSellerCollateral = collateralManager
            .getRequiredSellerCollateral(price, quantity);
        uint requiredCustomerCollateral = collateralManager
            .getRequiredCustomerCollateral(price, quantity);
        uint requiredShippingCollateral = collateralManager
            .getRequiredShippingServiceCollateral(price, quantity);
        uint totalOrderCollateral = requiredSellerCollateral +
            requiredCustomerCollateral +
            requiredShippingCollateral;
        vm.deal(address(collateralManager), totalOrderCollateral);
        vm.store(
            address(collateralManager),
            keccak256(abi.encode(orderIndex, uint256(6))),
            bytes32(totalOrderCollateral)
        );

        // Mark order as disputed
        vm.store(
            address(collateralManager),
            keccak256(abi.encode(orderIndex, uint256(8))), // isOrderDisputed mapping at slot 8
            bytes32(uint256(1))
        );

        vm.expectRevert("Order is disputed");
        vm.prank(address(orderManager));
        collateralManager.confirm(
            orderIndex,
            price,
            quantity,
            seller1,
            shipper1
        );
    }

    function testConfirmZeroOrderCollateral() public {
        uint orderIndex = 0;

        vm.prank(address(orderManager));
        vm.expectRevert("panic: arithmetic underflow or overflow (0x11)");
        collateralManager.confirm(
            orderIndex,
            price,
            quantity,
            seller1,
            shipper1
        );
    }

    function testConfirmFuzzValidInputs(
        uint256 _orderIndex,
        uint256 _price,
        uint256 _quantity
    ) public {
        console.log("Fuzzing with orderIndex:", _orderIndex);
        console.log("Fuzzing with price:", _price);
        console.log("Fuzzing with quantity:", _quantity);

        vm.assume(_orderIndex <= type(uint32).max);
        vm.assume(_price > 0 && _price < type(uint120).max);
        vm.assume(_quantity > 0 && _quantity < type(uint120).max);

        uint requiredSellerCollateral = collateralManager
            .getRequiredSellerCollateral(_price, _quantity);
        uint requiredCustomerCollateral = collateralManager
            .getRequiredCustomerCollateral(_price, _quantity);
        uint requiredShippingCollateral = collateralManager
            .getRequiredShippingServiceCollateral(_price, _quantity);
        uint totalOrderCollateral = requiredSellerCollateral +
            requiredCustomerCollateral +
            requiredShippingCollateral;
        vm.assume(requiredSellerCollateral > 0);

        vm.deal(address(collateralManager), totalOrderCollateral);
        vm.store(
            address(collateralManager),
            keccak256(abi.encode(_orderIndex, uint256(6))),
            bytes32(totalOrderCollateral)
        );

        uint sellerEarning = requiredSellerCollateral + _price * _quantity;
        uint initialSellerBalance = collateralManager.balances(seller1);
        uint initialShippingBalance = collateralManager.balances(shipper1);

        vm.prank(address(orderManager));
        collateralManager.confirm(
            _orderIndex,
            _price,
            _quantity,
            seller1,
            shipper1
        );

        assertEq(collateralManager.orderCollaterals(_orderIndex), 0);
        assertEq(
            collateralManager.balances(seller1),
            initialSellerBalance + sellerEarning
        );

        assertEq(
            collateralManager.balances(shipper1),
            initialShippingBalance + (totalOrderCollateral - sellerEarning)
        );
    }
}
