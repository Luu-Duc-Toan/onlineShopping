// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/CollateralManagerTestBase.sol";

contract GetRequiredCustomerCollateralTest is CollateralManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testGetRequiredCustomerCollateralSuccess() public view {
        uint expectedCollateral = price * quantity;
        uint actualCollateral = collateralManager.getRequiredCustomerCollateral(
            price,
            quantity
        );

        assertEq(actualCollateral, expectedCollateral);
    }

    function testGetRequiredCustomerCollateralZeroPrice() public {
        vm.expectRevert("Invalid price");
        collateralManager.getRequiredCustomerCollateral(0, quantity);
    }

    function testGetRequiredCustomerCollateralZeroQuantity() public {
        vm.expectRevert("Invalid quantity");
        collateralManager.getRequiredCustomerCollateral(price, 0);
    }

    function testGetRequiredCustomerCollateralFuzzValidInputs(
        uint256 _price,
        uint256 _quantity
    ) public view {
        vm.assume(_price > 0 && _price <= type(uint120).max);
        vm.assume(_quantity > 0 && _quantity <= type(uint120).max);

        uint expectedCollateral = _price * _quantity;
        uint actualCollateral = collateralManager.getRequiredCustomerCollateral(
            _price,
            _quantity
        );

        assertEq(actualCollateral, expectedCollateral);
    }
}
