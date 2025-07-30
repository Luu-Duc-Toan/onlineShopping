// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../../shared/BaseTest.sol";
import "../../../src/CollateralManager.sol";
import "../../../src/ProductManager.sol";
import "../../../src/OrderManager.sol";

contract OrderManagerTestBase is BaseTest {
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

    function createTwoReleaseSlots() internal {
        //shouldn't be call two times
        uint256 maxOrderCountStorageSlot = 3;
        uint256 releaseSlotStorageSlot = 4;
        uint maxOrderCount = orderManager.maxOrderCount();

        vm.store(
            address(orderManager),
            bytes32(uint256(maxOrderCountStorageSlot)),
            bytes32(uint256(maxOrderCount + 2))
        );

        vm.store(
            address(orderManager),
            bytes32(releaseSlotStorageSlot),
            bytes32(uint256(2))
        );
        bytes32 arrayDataStart = keccak256(abi.encode(releaseSlotStorageSlot));
        vm.store(
            address(orderManager),
            bytes32(uint256(arrayDataStart) + 0),
            bytes32(uint256(maxOrderCount))
        );
        vm.store(
            address(orderManager),
            bytes32(uint256(arrayDataStart) + 1),
            bytes32(uint256(maxOrderCount + 1))
        );
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
        vm.deal(customer, customerCollateral + 1 ether);
        vm.prank(customer);
        orderIndex = orderManager.order{value: customerCollateral}(
            _product,
            _quantity
        );
    }

    function createCompleteOrder(
        string memory _product,
        uint _price,
        uint _quantity,
        address seller,
        address customer
    ) internal returns (uint orderIndex) {
        createCompleteProduct(_product, _price, _quantity, seller);
        uint customerCollateral = _price * _quantity;
        orderIndex = createOrder(
            _product,
            _quantity,
            customer,
            customerCollateral
        );
    }

    function confirmOrder(uint orderIndex, address shipper) internal {
        // Setup shipping service
        uint shippingDeposit = getOrderValue(orderIndex);
        setupShippingService(shipper, shippingDeposit);

        // Take order
        vm.prank(shipper);
        orderManager.takeOrder(orderIndex);

        // Confirm order
        address customer = getOrderCustomer(orderIndex);
        vm.prank(customer);
        orderManager.confirmOrder(orderIndex);
    }

    function getOrderValue(uint orderIndex) internal view returns (uint) {
        (, uint quantity, uint price, , , , , ) = orderManager.orders(
            orderIndex
        );
        return price * quantity;
    }

    function getOrderCustomer(uint orderIndex) internal view returns (address) {
        (, , , , address customer, , , ) = orderManager.orders(orderIndex);
        return customer;
    }

    function getOrderInfo(
        uint orderIndex
    )
        internal
        view
        returns (
            string memory product,
            uint quantity,
            uint price,
            address seller,
            address customer,
            uint maxTime,
            address shippingService,
            uint shippingFee
        )
    {
        (
            product,
            quantity,
            price,
            seller,
            customer,
            maxTime,
            shippingService,
            shippingFee
        ) = orderManager.orders(orderIndex);
    }

    function assertOrderExists(
        uint orderIndex,
        string memory expectedProduct,
        uint expectedQuantity,
        uint expectedPrice,
        address expectedSeller,
        address expectedCustomer
    ) internal view {
        (
            string memory product,
            uint quantity,
            uint price,
            address seller,
            address customer,
            ,
            ,

        ) = orderManager.orders(orderIndex);

        assertEq(product, expectedProduct);
        assertEq(quantity, expectedQuantity);
        assertEq(price, expectedPrice);
        assertEq(seller, expectedSeller);
        assertEq(customer, expectedCustomer);
    }

    function assertOrderNotExists(uint orderIndex) internal view {
        (
            string memory product,
            uint quantity,
            uint price,
            address seller,
            address customer,
            ,
            ,

        ) = orderManager.orders(orderIndex);

        assertEq(bytes(product).length, 0);
        assertEq(quantity, 0);
        assertEq(price, 0);
        assertEq(seller, address(0));
        assertEq(customer, address(0));
    }

    function getMaxOrderCount() internal view returns (uint) {
        return orderManager.maxOrderCount();
    }

    function getReleaseSlotCount() internal view returns (uint) {
        // Try to access releaseSlots array length by checking each index
        uint count = 0;
        try orderManager.releaseSlots(count) returns (uint) {
            count++;
            while (true) {
                try orderManager.releaseSlots(count) returns (uint) {
                    count++;
                } catch {
                    break;
                }
            }
        } catch {
            // Array is empty
            return 0;
        }
        return count;
    }

    function getReleaseSlotsLength() internal view returns (uint) {
        return orderManager.releaseSlots(0); // This will revert if empty, so we need a different approach
    }

    // Helper function to simulate slot releases by confirming orders
    function simulateOrderCompletion(uint orderIndex) internal {
        // Get order details
        (, uint quantity, uint price, , , , , ) = orderManager.orders(
            orderIndex
        );

        // Setup and assign shipping service
        address shipper = makeAddr("shipper");
        uint shippingDeposit = price * quantity;
        setupShippingService(shipper, shippingDeposit);

        vm.prank(shipper);
        orderManager.takeOrder(orderIndex);

        // Confirm order to release the slot
        address customer = getOrderCustomer(orderIndex);
        vm.prank(customer);
        orderManager.confirmOrder(orderIndex);
    }
}
