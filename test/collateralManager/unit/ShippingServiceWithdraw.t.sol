// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/CollateralManagerTestBase.sol";

contract ShippingServiceWithdraw is CollateralManagerTestBase {
    uint public requiredShippingService;

    function setUp() public override {
        super.setUp();
        requiredShippingService = collateralManager
            .getRequiredShippingServiceCollateral(price, quantity);
        setupShippingService(shipper1, requiredShippingService);
    }

    function testShippingServiceWithdrawSuccessful() public {
        uint withdrawAmount = 1;
        uint initialBalance = address(collateralManager).balance;

        vm.prank(shipper1);
        collateralManager.shippingServiceWithdraw(withdrawAmount);

        assertEq(
            address(collateralManager).balance,
            initialBalance - withdrawAmount
        );
        assertEq(
            collateralManager.shippingDeposits(shipper1),
            requiredShippingService - withdrawAmount
        );
    }

    function testShippingServiceWithdrawZeroAmount() public {
        uint initialBalance = address(collateralManager).balance;

        vm.prank(shipper1);
        collateralManager.shippingServiceWithdraw(0);

        assertEq(address(collateralManager).balance, initialBalance);
        assertEq(
            collateralManager.shippingDeposits(shipper1),
            requiredShippingService
        );
    }

    function testShippingServiceWithdrawRevertInsufficientDeposit() public {
        uint insufficientWithdrawAmount = requiredShippingService + 1;

        vm.prank(shipper1);
        vm.expectRevert("Insufficient shipping deposit");
        collateralManager.shippingServiceWithdraw(insufficientWithdrawAmount);
    }

    function testFuzzShippingServiceWithdraw(
        uint256 _quantity,
        uint256 _price,
        uint256 _withdrawAmount
    ) public {
        vm.assume(_quantity > 0 && _quantity < type(uint120).max);
        vm.assume(_price > 0 && _price < type(uint120).max);

        requiredShippingService = collateralManager
            .getRequiredShippingServiceCollateral(_price, _quantity);
        vm.assume(
            _withdrawAmount > 0 && _withdrawAmount <= requiredShippingService
        );

        setupShippingService(shipper2, requiredShippingService);
        vm.assume(
            _withdrawAmount > 0 && _withdrawAmount <= requiredShippingService
        );
        uint initialBalance = address(collateralManager).balance;

        vm.prank(shipper2);
        collateralManager.shippingServiceWithdraw(_withdrawAmount);

        assertEq(
            address(collateralManager).balance,
            initialBalance - _withdrawAmount
        );
        assertEq(
            collateralManager.shippingDeposits(shipper2),
            requiredShippingService - _withdrawAmount
        );
    }
}
