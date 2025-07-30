// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../../shared/BaseTest.sol";
import "../../../src/CollateralManager.sol";
import "../../../src/ProductManager.sol";
import "../../../src/OrderManager.sol";

contract CollateralManagerTestBase is BaseTest {
    CollateralManager public collateralManager;
    ProductManager public productManager;
    OrderManager public orderManager;

    function setUp() public virtual override {
        super.setUp();

        vm.prank(admin);
        collateralManager = new CollateralManager(collateralPercent);
        productManager = ProductManager(collateralManager.productManager());
        orderManager = OrderManager(collateralManager.orderManager());
    }

    function setupProductCollateral(
        string memory _product,
        uint _price,
        uint _quantity,
        address seller
    ) internal returns (uint requiredCollateral) {
        requiredCollateral = collateralManager.getRequiredSellerCollateral(
            _price,
            _quantity
        );

        vm.prank(seller);
        collateralManager.addProductCollateral{value: requiredCollateral}(
            _product
        );
    }

    function createCompleteProduct(
        string memory _product,
        uint _price,
        uint _quantity,
        address seller
    ) internal {
        setupProductCollateral(_product, _price, _quantity, seller);

        vm.prank(seller);
        productManager.addProduct(_product, _quantity, _price);
    }

    function addQuantityToProduct(
        string memory _product,
        uint _quantity
    ) internal {
        uint _price = productManager.prices(_product);
        address _seller = productManager.sellers(_product);
        setupProductCollateral(_product, _price, _quantity, _seller);

        vm.prank(_seller);
        productManager.updateQuantities(
            _product,
            productManager.quantities(_product) + _quantity
        );
    }

    function setupShippingService(address shipper, uint deposit) internal {
        vm.deal(shipper, deposit + 1 ether);
        vm.prank(shipper);
        collateralManager.shippingServiceDeposit{value: deposit}();
    }
}
