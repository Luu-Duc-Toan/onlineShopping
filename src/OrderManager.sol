// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "./ProductManager.sol";
import "./CollateralManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OrderManager is Ownable {
    struct Order {
        string product;
        uint quantity;
        uint price;
        address seller;
        address customer;
        uint maxTime;
        address shippingService;
        uint shippingFee;
    }
    CollateralManager public collateralManager;
    ProductManager public productManager;

    uint public maxOrderCount;
    uint[] public releaseSlots;
    mapping(uint => Order) public orders;

    constructor(
        address _owner,
        address _collateralManager,
        address _productManager
    ) Ownable(_owner) {
        require(
            _collateralManager != address(0),
            "Invalid CollateralManager address"
        );
        collateralManager = CollateralManager(_collateralManager);
        require(
            _productManager != address(0),
            "Invalid ProductManager address"
        );
        productManager = ProductManager(_productManager);
    }

    modifier validOrderIndex(uint orderIndex) {
        require(orderIndex < maxOrderCount, "Invalid order index");
        require(
            orders[orderIndex].customer != address(0),
            "Invalid order index"
        );
        _;
    }

    function getNextOrderIndex() public view returns (uint orderIndex) {
        if (releaseSlots.length > 0) {
            orderIndex = releaseSlots[0];
        } else {
            orderIndex = maxOrderCount;
        }
    }

    function order(
        string calldata product,
        uint quantity
    ) external payable returns (uint orderIndex) {
        require(quantity > 0, "Quantity must be greater than 0");
        productManager.order(product, quantity);

        uint price = productManager.prices(product);
        if (releaseSlots.length > 0) {
            orderIndex = releaseSlots[0];
            releaseSlots[0] = releaseSlots[releaseSlots.length - 1];
            releaseSlots.pop();
        } else {
            orderIndex = maxOrderCount;
            maxOrderCount++;
        }

        orders[orderIndex] = Order(
            product,
            quantity,
            price,
            productManager.sellers(product),
            msg.sender,
            0,
            address(0),
            0
        );

        collateralManager.order{value: msg.value}(
            orderIndex,
            product,
            price,
            quantity
        );
    }

    function setOrderMaxTime(
        uint orderIndex,
        uint maxTime
    ) external validOrderIndex(orderIndex) onlyOwner {
        orders[orderIndex].maxTime = maxTime;
    }

    function depositShippingFee(
        uint orderIndex
    ) external payable validOrderIndex(orderIndex) {
        orders[orderIndex].shippingFee = msg.value;
        collateralManager.depositShippingFee{value: msg.value}(orderIndex);
    }

    function takeOrder(uint orderIndex) external validOrderIndex(orderIndex) {
        require(
            orders[orderIndex].shippingService == address(0),
            "Order already has a shipping service"
        );
        orders[orderIndex].shippingService = msg.sender;
        collateralManager.takeOrder(
            orderIndex,
            orders[orderIndex].price,
            orders[orderIndex].quantity,
            msg.sender
        );
    }

    function confirmOrder(
        uint orderIndex
    ) external validOrderIndex(orderIndex) {
        require(
            msg.sender == orders[orderIndex].customer,
            "Only customer can confirm"
        );
        require(
            orders[orderIndex].shippingService != address(0),
            "Order not taken by shipping service"
        );
        collateralManager.confirm(
            orderIndex,
            orders[orderIndex].price,
            orders[orderIndex].quantity,
            orders[orderIndex].seller,
            orders[orderIndex].shippingService
        );
        delete orders[orderIndex];
        releaseSlots.push(orderIndex);
    }

    function customerDispute(
        uint orderIndex
    ) external validOrderIndex(orderIndex) {
        require(
            msg.sender == orders[orderIndex].customer,
            "Only customer can dispute"
        );
        require(
            block.timestamp > orders[orderIndex].maxTime,
            "Dispute period not yet started"
        );
        if (orders[orderIndex].shippingService != address(0)) {
            collateralManager.dispute(orderIndex);
        } else {
            collateralManager.customerRefund(
                orderIndex,
                orders[orderIndex].customer
            );
            delete orders[orderIndex];
            releaseSlots.push(orderIndex);
        }
    }

    function shippingServiceDispute(
        uint orderIndex
    ) external validOrderIndex(orderIndex) {
        require(
            msg.sender == orders[orderIndex].shippingService,
            "Only shipping service can dispute"
        );
        collateralManager.dispute(orderIndex);
    }

    function resolveDispute(
        uint orderIndex,
        bool isCustomerWin
    ) external validOrderIndex(orderIndex) onlyOwner {
        collateralManager.resolveDispute(
            orderIndex,
            orders[orderIndex].price,
            orders[orderIndex].quantity,
            orders[orderIndex].customer,
            orders[orderIndex].seller,
            orders[orderIndex].shippingService,
            isCustomerWin
        );
        delete orders[orderIndex];
        releaseSlots.push(orderIndex);
    }
}
