// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/ProductManagerTestBase.sol";

contract OrderTest is ProductManagerTestBase {
    function setUp() public override {
        super.setUp();
        createCompleteProduct(product, price, quantity, seller1);
    }

    function testOrderSuccess() public {
        uint orderQuantity = 3;
        uint initialQuantity = productManager.quantities(product);

        vm.prank(address(orderManager));
        productManager.order(product, orderQuantity);

        assertEq(
            productManager.quantities(product),
            initialQuantity - orderQuantity
        );
        assertProductExists(
            product,
            price,
            initialQuantity - orderQuantity,
            seller1
        );
    }

    function testOrderNotOrderManagerReverts() public {
        uint orderQuantity = 2;

        vm.expectRevert("Only OrderManager can call this");
        vm.prank(customer1);
        productManager.order(product, orderQuantity);
    }

    function testOrderInsufficientQuantityReverts() public {
        uint orderQuantity = quantity + 1;

        vm.expectRevert("Not enough product quantity");
        vm.prank(address(orderManager));
        productManager.order(product, orderQuantity);
    }

    function testOrderExactQuantity() public {
        uint orderQuantity = quantity;

        vm.prank(address(orderManager));
        productManager.order(product, orderQuantity);

        assertEq(productManager.quantities(product), 0);
        assertProductExists(product, price, 0, seller1);
    }

    function testOrderNonExistentProductReverts() public {
        string memory nonExistentProduct = "nonExistent";
        uint orderQuantity = 1;

        vm.expectRevert("Not enough product quantity");
        vm.prank(address(orderManager));
        productManager.order(nonExistentProduct, orderQuantity);
    }

    function testOrderEmptyProductNameReverts() public {
        string memory emptyProduct = "";
        uint orderQuantity = 1;

        vm.expectRevert("Not enough product quantity");
        vm.prank(address(orderManager));
        productManager.order(emptyProduct, orderQuantity);
    }

    function testFuzzOrder(
        uint256 _price,
        uint256 _quantity,
        uint256 _orderQuantity
    ) public {
        vm.assume(_price > 0 && _price <= type(uint120).max);
        vm.assume(_quantity > 0 && _quantity <= type(uint120).max);
        vm.assume(_orderQuantity > 0 && _orderQuantity <= _quantity);

        string memory fuzzProduct = "fuzzProduct";
        createCompleteProduct(fuzzProduct, _price, _quantity, seller2);

        uint requiredCollateral = _price * _orderQuantity;

        vm.prank(address(orderManager));
        productManager.order(fuzzProduct, _orderQuantity);

        assertEq(
            productManager.quantities(fuzzProduct),
            _quantity - _orderQuantity
        );
        assertProductExists(
            fuzzProduct,
            _price,
            _quantity - _orderQuantity,
            seller2
        );
    }
}
