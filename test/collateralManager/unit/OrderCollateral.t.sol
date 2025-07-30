// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/CollateralManagerTestBase.sol";

contract OrderCollateralTest is CollateralManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testOrderSuccess() public {
        uint orderIndex = 0;
        uint requiredSellerCollateral = collateralManager
            .getRequiredSellerCollateral(price, quantity);
        uint requiredCustomerCollateral = collateralManager
            .getRequiredCustomerCollateral(price, quantity);

        vm.prank(seller1);
        collateralManager.addProductCollateral{value: requiredSellerCollateral}(
            product
        );

        uint initialProductCollateral = collateralManager.productCollaterals(
            product
        );
        uint initialOrderCollateral = collateralManager.orderCollaterals(
            orderIndex
        );

        vm.deal(address(orderManager), requiredCustomerCollateral + 1 ether);
        vm.prank(address(orderManager));
        collateralManager.order{value: requiredCustomerCollateral}(
            orderIndex,
            product,
            price,
            quantity
        );

        assertEq(
            collateralManager.productCollaterals(product),
            initialProductCollateral - requiredSellerCollateral
        );
        assertEq(
            collateralManager.orderCollaterals(orderIndex),
            initialOrderCollateral +
                requiredCustomerCollateral +
                requiredSellerCollateral
        );
    }

    function testOrderInsufficientCustomerCollateralReverts() public {
        uint orderIndex = 0;
        uint requiredSellerCollateral = collateralManager
            .getRequiredSellerCollateral(price, quantity);
        uint requiredCustomerCollateral = collateralManager
            .getRequiredCustomerCollateral(price, quantity);
        uint insufficientCustomerCollateral = requiredCustomerCollateral - 1;

        vm.prank(seller1);
        collateralManager.addProductCollateral{value: requiredSellerCollateral}(
            product
        );

        vm.deal(
            address(orderManager),
            insufficientCustomerCollateral + 1 ether
        );
        vm.expectRevert("Invalid customer collateral");
        vm.prank(address(orderManager));
        collateralManager.order{value: insufficientCustomerCollateral}(
            orderIndex,
            product,
            price,
            quantity
        );
    }

    function testOrderExcessCustomerCollateralReverts() public {
        uint orderIndex = 0;
        uint requiredSellerCollateral = collateralManager
            .getRequiredSellerCollateral(price, quantity);
        uint requiredCustomerCollateral = collateralManager
            .getRequiredCustomerCollateral(price, quantity);
        uint excessCustomerCollateral = requiredCustomerCollateral + 1;

        vm.prank(seller1);
        collateralManager.addProductCollateral{value: requiredSellerCollateral}(
            product
        );

        vm.deal(address(orderManager), excessCustomerCollateral + 1 ether);
        vm.expectRevert("Invalid customer collateral");
        vm.prank(address(orderManager));
        collateralManager.order{value: excessCustomerCollateral}(
            orderIndex,
            product,
            price,
            quantity
        );
    }

    function testOrderNotOrderManagerReverts() public {
        uint orderIndex = 0;
        uint requiredSellerCollateral = collateralManager
            .getRequiredSellerCollateral(price, quantity);
        uint requiredCustomerCollateral = collateralManager
            .getRequiredCustomerCollateral(price, quantity);

        vm.prank(seller1);
        collateralManager.addProductCollateral{value: requiredSellerCollateral}(
            product
        );

        vm.deal(address(orderManager), requiredCustomerCollateral + 1 ether);

        vm.expectRevert("Only OrderManager can call this");
        vm.prank(seller1);
        collateralManager.order{value: requiredCustomerCollateral}(
            orderIndex,
            product,
            price,
            quantity
        );
    }

    function testOrderMultipleOrders() public {
        uint requiredSellerCollateral = collateralManager
            .getRequiredSellerCollateral(price, quantity);
        uint requiredCustomerCollateral = collateralManager
            .getRequiredCustomerCollateral(price, quantity);

        vm.prank(seller1);
        collateralManager.addProductCollateral{
            value: requiredSellerCollateral * 2
        }(product);

        uint sellerCollateralBeforeOrdering = collateralManager
            .productCollaterals(product);

        vm.deal(
            address(orderManager),
            requiredCustomerCollateral * 2 + 1 ether
        );
        vm.prank(address(orderManager));
        collateralManager.order{value: requiredCustomerCollateral}(
            0,
            product,
            price,
            quantity
        );
        vm.prank(address(orderManager));
        collateralManager.order{value: requiredCustomerCollateral}(
            1,
            product,
            price,
            quantity
        );

        assertEq(
            collateralManager.orderCollaterals(0),
            requiredSellerCollateral + requiredCustomerCollateral
        );
        assertEq(
            collateralManager.orderCollaterals(1),
            requiredSellerCollateral + requiredCustomerCollateral
        );
        assertEq(
            collateralManager.productCollaterals(product),
            sellerCollateralBeforeOrdering - 2 * requiredSellerCollateral
        );
    }

    function testOrderZeroPrice() public {
        uint orderIndex = 0;
        uint customerCollateral = amount;

        vm.deal(address(orderManager), customerCollateral + 1 ether);
        vm.prank(address(orderManager));
        vm.expectRevert("Invalid price");
        collateralManager.order{value: customerCollateral}(
            orderIndex,
            product,
            0,
            quantity
        );
    }

    function testOrderZeroQuantity() public {
        uint orderIndex = 0;
        uint customerCollateral = amount;

        vm.deal(address(orderManager), customerCollateral + 1 ether);
        vm.prank(address(orderManager));
        vm.expectRevert("Invalid quantity");
        collateralManager.order{value: customerCollateral}(
            orderIndex,
            product,
            price,
            0
        );
    }

    function testFuzzOrder(uint _price, uint _quantity) public {
        uint orderIndex = 0;
        vm.assume(_price > 0 && _price < type(uint32).max);
        vm.assume(_quantity > 0 && _quantity < type(uint32).max);

        uint requiredSellerCollateral = collateralManager
            .getRequiredSellerCollateral(_price, _quantity);
        uint requiredCustomerCollateral = collateralManager
            .getRequiredCustomerCollateral(_price, _quantity);

        vm.prank(seller1);
        collateralManager.addProductCollateral{value: requiredSellerCollateral}(
            product
        );

        vm.deal(address(orderManager), requiredCustomerCollateral + 1 ether);
        vm.prank(address(orderManager));
        collateralManager.order{value: requiredCustomerCollateral}(
            orderIndex,
            product,
            _price,
            _quantity
        );

        assertEq(collateralManager.productCollaterals(product), 0);
        assertEq(
            collateralManager.orderCollaterals(orderIndex),
            requiredSellerCollateral + requiredCustomerCollateral
        );
    }
}
