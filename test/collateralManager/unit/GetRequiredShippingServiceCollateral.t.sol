// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/CollateralManagerTestBase.sol";

contract GetRequiredShippingServiceCollateralTest is CollateralManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testGetRequiredShippingServiceCollateralSuccess() public view {
        uint expectedCollateral = price * quantity;
        uint actualCollateral = collateralManager
            .getRequiredShippingServiceCollateral(price, quantity);

        assertEq(actualCollateral, expectedCollateral);
    }

    function testGetRequiredShippingServiceCollateralZeroPrice() public {
        vm.expectRevert("Invalid price");
        collateralManager.getRequiredShippingServiceCollateral(0, quantity);
    }

    function testGetRequiredShippingServiceCollateralZeroQuantity() public {
        vm.expectRevert("Invalid quantity");
        collateralManager.getRequiredShippingServiceCollateral(price, 0);
    }

    function testGetRequiredShippingCollateralFuzzValidInputs(
        uint256 _price,
        uint256 _quantity
    ) public view {
        vm.assume(_price > 0 && _price <= type(uint120).max);
        vm.assume(_quantity > 0 && _quantity <= type(uint120).max);

        uint expectedCollateral = _price * _quantity;
        uint actualCollateral = collateralManager
            .getRequiredShippingServiceCollateral(_price, _quantity);

        assertEq(actualCollateral, expectedCollateral);
    }
}
