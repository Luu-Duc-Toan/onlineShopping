// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/CollateralManagerTestBase.sol";

contract ResolveDisputeTest is CollateralManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testResolveDisputeCustomerWinsSuccess() public {
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

        vm.prank(address(orderManager));
        collateralManager.dispute(orderIndex);

        uint initialCustomerBalance = collateralManager.balances(customer1);
        uint initialSellerBalance = collateralManager.balances(seller1);
        uint sellerEarnings = collateralManager.getRequiredSellerCollateral(
            price,
            quantity
        ) + price * quantity;
        uint customerEarnings = totalOrderCollateral - sellerEarnings;

        vm.prank(address(orderManager));
        collateralManager.resolveDispute(
            orderIndex,
            price,
            quantity,
            customer1,
            seller1,
            shipper1,
            true
        );

        assertEq(collateralManager.isOrderDisputed(orderIndex), false);
        assertEq(
            collateralManager.balances(customer1),
            initialCustomerBalance + customerEarnings
        );
        assertEq(
            collateralManager.balances(seller1),
            initialSellerBalance + sellerEarnings
        );
        assertEq(collateralManager.orderCollaterals(orderIndex), 0);
    }

    function testResolveDisputeSellerWinsSuccess() public {
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
            keccak256(abi.encode(orderIndex, uint256(6))),
            bytes32(totalOrderCollateral)
        );

        vm.prank(address(orderManager));
        collateralManager.dispute(orderIndex);

        uint initialSellerBalance = collateralManager.balances(seller1);
        uint initialShippingBalance = collateralManager.balances(shipper1);
        uint sellerEarnings = price *
            quantity +
            collateralManager.getRequiredSellerCollateral(price, quantity);
        uint shippingEarnings = shippingFee +
            collateralManager.getRequiredShippingServiceCollateral(
                price,
                quantity
            );

        vm.prank(address(orderManager));
        collateralManager.resolveDispute(
            orderIndex,
            price,
            quantity,
            customer1,
            seller1,
            shipper1,
            false
        );

        assertEq(collateralManager.isOrderDisputed(orderIndex), false);
        assertEq(
            collateralManager.balances(seller1),
            initialSellerBalance + sellerEarnings
        );
        assertEq(
            collateralManager.balances(shipper1),
            initialShippingBalance + shippingEarnings
        );
        assertEq(collateralManager.orderCollaterals(orderIndex), 0);
    }

    function testResolveDisputeNotOrderManagerReverts() public {
        uint orderIndex = 0;

        vm.expectRevert("Only OrderManager can call this");
        vm.prank(seller1);
        collateralManager.resolveDispute(
            orderIndex,
            price,
            quantity,
            customer1,
            seller1,
            shipper1,
            true
        );
    }

    function testResolveDisputeOrderNotDisputedReverts() public {
        uint orderIndex = 0;

        vm.expectRevert("Order is not disputed");
        vm.prank(address(orderManager));
        collateralManager.resolveDispute(
            orderIndex,
            price,
            quantity,
            customer1,
            seller1,
            shipper1,
            true
        );
    }

    function testFuzzResolveDisputeCustomerWins(
        uint256 _orderIndex,
        uint256 _price,
        uint256 _quantity
    ) public {
        vm.assume(_orderIndex <= type(uint32).max);
        vm.assume(_price > 0 && _price <= type(uint120).max);
        vm.assume(_quantity > 0 && _quantity <= type(uint120).max);

        uint requiredSellerCollateral = collateralManager
            .getRequiredSellerCollateral(_price, _quantity);
        uint requiredCustomerCollateral = collateralManager
            .getRequiredCustomerCollateral(_price, _quantity);
        uint requiredShippingCollateral = collateralManager
            .getRequiredShippingServiceCollateral(_price, _quantity);
        uint shippingFee = amount;
        uint totalOrderCollateral = requiredSellerCollateral +
            requiredCustomerCollateral +
            requiredShippingCollateral +
            shippingFee;

        vm.deal(address(collateralManager), totalOrderCollateral);
        vm.store(
            address(collateralManager),
            keccak256(abi.encode(_orderIndex, uint256(6))),
            bytes32(totalOrderCollateral)
        );

        vm.prank(address(orderManager));
        collateralManager.dispute(_orderIndex);

        uint initialCustomerBalance = collateralManager.balances(customer1);
        uint initialSellerBalance = collateralManager.balances(seller1);
        uint sellerEarnings = requiredSellerCollateral + _price * _quantity;
        uint customerEarnings = totalOrderCollateral - sellerEarnings;

        vm.prank(address(orderManager));
        collateralManager.resolveDispute(
            _orderIndex,
            _price,
            _quantity,
            customer1,
            seller1,
            shipper1,
            true
        );

        assertEq(collateralManager.isOrderDisputed(_orderIndex), false);
        assertEq(
            collateralManager.balances(customer1),
            initialCustomerBalance + customerEarnings
        );
        assertEq(
            collateralManager.balances(seller1),
            initialSellerBalance + sellerEarnings
        );
        assertEq(collateralManager.orderCollaterals(_orderIndex), 0);
    }

    function testFuzzResolveDisputeShippingServiceWins(
        uint256 _orderIndex,
        uint256 _price,
        uint256 _quantity
    ) public {
        vm.assume(_orderIndex <= type(uint32).max);
        vm.assume(_price > 0 && _price <= type(uint120).max);
        vm.assume(_quantity > 0 && _quantity <= type(uint120).max);

        uint requiredSellerCollateral = collateralManager
            .getRequiredSellerCollateral(_price, _quantity);
        uint requiredCustomerCollateral = collateralManager
            .getRequiredCustomerCollateral(_price, _quantity);
        uint requiredShippingCollateral = collateralManager
            .getRequiredShippingServiceCollateral(_price, _quantity);
        uint shippingFee = amount;
        uint totalOrderCollateral = requiredSellerCollateral +
            requiredCustomerCollateral +
            requiredShippingCollateral +
            shippingFee;

        vm.deal(address(collateralManager), totalOrderCollateral);
        vm.store(
            address(collateralManager),
            keccak256(abi.encode(_orderIndex, uint256(6))),
            bytes32(totalOrderCollateral)
        );

        vm.prank(address(orderManager));
        collateralManager.dispute(_orderIndex);

        uint initialSellerBalance = collateralManager.balances(seller1);
        uint initialShippingBalance = collateralManager.balances(shipper1);
        uint sellerEarnings = _price *
            _quantity +
            collateralManager.getRequiredSellerCollateral(_price, _quantity);
        uint shippingServiceEarnings = shippingFee + requiredShippingCollateral;

        vm.prank(address(orderManager));
        collateralManager.resolveDispute(
            _orderIndex,
            _price,
            _quantity,
            customer1,
            seller1,
            shipper1,
            false
        );

        assertEq(collateralManager.isOrderDisputed(_orderIndex), false);
        assertEq(collateralManager.orderCollaterals(_orderIndex), 0);
        assertEq(
            collateralManager.balances(seller1),
            initialSellerBalance + sellerEarnings
        );
        assertEq(
            collateralManager.balances(shipper1),
            initialShippingBalance + shippingServiceEarnings
        );
    }
}
