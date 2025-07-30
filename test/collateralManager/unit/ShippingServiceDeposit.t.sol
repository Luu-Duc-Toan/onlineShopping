// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/CollateralManagerTestBase.sol";

contract ShippingServiceDepositTest is CollateralManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testShippingServiceDepositZeroValue() public {
        vm.prank(shipper1);
        vm.expectRevert("Deposit must be greater than 0");
        collateralManager.shippingServiceDeposit{value: 0}();
    }

    function testShippingServiceDepositSuccess() public {
        uint depositAmount = amount;

        vm.prank(shipper1);
        collateralManager.shippingServiceDeposit{value: depositAmount}();

        assertEq(collateralManager.shippingDeposits(shipper1), depositAmount);
    }

    function testShippingServiceDepositMultipleDeposits() public {
        uint depositAmount = amount;

        vm.prank(shipper1);
        collateralManager.shippingServiceDeposit{value: depositAmount}();

        uint additionalAmount = amount;
        vm.prank(shipper1);
        collateralManager.shippingServiceDeposit{value: additionalAmount}();

        assertEq(
            collateralManager.shippingDeposits(shipper1),
            depositAmount + additionalAmount
        );
    }

    function testFuzzShippingServiceDepositValidAmounts(
        uint depositAmount
    ) public {
        vm.assume(depositAmount > 0);

        vm.deal(shipper1, depositAmount);
        vm.prank(shipper1);
        collateralManager.shippingServiceDeposit{value: depositAmount}();

        assertEq(collateralManager.shippingDeposits(shipper1), depositAmount);
    }
}
