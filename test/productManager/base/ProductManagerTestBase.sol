// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../../shared/BaseTest.sol";
import "../../../src/CollateralManager.sol";
import "../../../src/ProductManager.sol";
import "../../../src/OrderManager.sol";

contract ProductManagerTestBase is BaseTest {
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

        vm.deal(seller, requiredCollateral + 1 ether);
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
        uint _additionalQuantity
    ) internal {
        uint price = productManager.prices(_product);
        uint currentQuantity = productManager.quantities(_product);
        address seller = productManager.sellers(_product);
        setupProductCollateral(_product, price, _additionalQuantity, seller);

        vm.prank(seller);
        productManager.updateQuantities(
            _product,
            currentQuantity + _additionalQuantity
        );
    }

    function updateProductPrice(
        string memory _product,
        uint _newPrice
    ) internal {
        address seller = productManager.sellers(_product);
        uint quantity = productManager.quantities(_product);

        uint currentCollateral = collateralManager.productCollaterals(_product);
        uint requiredCollateral = collateralManager.getRequiredSellerCollateral(
            _newPrice,
            quantity
        );

        if (requiredCollateral > currentCollateral) {
            setupProductCollateral(_product, _newPrice, quantity, seller);
        }

        vm.prank(seller);
        productManager.updatePrice(_product, _newPrice);
    }

    function setupShippingService(address shipper, uint deposit) internal {
        vm.deal(shipper, deposit + 1 ether);
        vm.prank(shipper);
        collateralManager.shippingServiceDeposit{value: deposit}();
    }

    function createOrder(
        string memory _product,
        uint _quantity,
        address customer,
        uint customerCollateral
    ) internal returns (uint orderIndex) {
        // Setup customer collateral
        vm.deal(customer, customerCollateral + 1 ether);

        // Get next order index
        orderIndex = 0; // Simplified for testing

        vm.prank(address(orderManager));
        collateralManager.order{value: customerCollateral}(
            orderIndex,
            _product,
            productManager.prices(_product),
            _quantity
        );

        vm.prank(address(orderManager));
        productManager.order(_product, _quantity);
    }

    function getProductInfo(
        string memory _product
    ) internal view returns (uint quantity, address seller, uint price) {
        quantity = productManager.quantities(_product);
        seller = productManager.sellers(_product);
        price = productManager.prices(_product);
    }

    function assertProductExists(
        string memory _product,
        uint expectedPrice,
        uint expectedQuantity,
        address expectedSeller
    ) internal view {
        assertEq(productManager.quantities(_product), expectedQuantity);
        assertEq(productManager.sellers(_product), expectedSeller);
        assertEq(productManager.prices(_product), expectedPrice);
    }

    function assertProductNotExists(string memory _product) internal view {
        assertEq(productManager.quantities(_product), 0);
        assertEq(productManager.sellers(_product), address(0));
        assertEq(productManager.prices(_product), 0);
    }

    function addCollateralToProduct(
        string memory _product,
        uint _additionalCollateral
    ) internal {
        address seller = productManager.sellers(_product);
        vm.deal(seller, _additionalCollateral + 1 ether);
        vm.prank(seller);
        collateralManager.addProductCollateral{value: _additionalCollateral}(
            _product
        );
    }

    function updateQuantityToProduct(
        string memory _product,
        uint _newQuantity
    ) internal {
        address seller = productManager.sellers(_product);
        uint price = productManager.prices(_product);

        uint currentCollateral = collateralManager.productCollaterals(_product);
        uint requiredCollateral = collateralManager.getRequiredSellerCollateral(
            price,
            _newQuantity
        );

        if (requiredCollateral > currentCollateral) {
            uint additionalCollateral = requiredCollateral - currentCollateral;
            vm.deal(seller, additionalCollateral + 1 ether);
            vm.prank(seller);
            collateralManager.addProductCollateral{value: additionalCollateral}(
                _product
            );
        }

        vm.prank(seller);
        productManager.updateQuantities(_product, _newQuantity);
    }
}
