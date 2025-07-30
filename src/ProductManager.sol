// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "./CollateralManager.sol";
import "forge-std/console.sol";

contract ProductManager {
    CollateralManager public collateralManager;
    address public orderManager;

    mapping(string => uint) public quantities;
    mapping(string => address) public sellers;
    mapping(string => uint) public prices;

    constructor(address _collateralManager) {
        require(
            _collateralManager != address(0),
            "Invalid CollateralManager address"
        );
        collateralManager = CollateralManager(_collateralManager);
    }

    modifier onlyCollateralManager() {
        require(
            msg.sender == address(collateralManager),
            "Only CollateralManager can call this"
        );
        _;
    }

    modifier onlySeller(string calldata product) {
        require(
            sellers[product] == msg.sender,
            "Only the seller can call this"
        );
        _;
    }

    modifier onlyOrderManager() {
        require(
            msg.sender == address(orderManager),
            "Only OrderManager can call this"
        );
        _;
    }

    function setOrderManager(
        address _orderManager
    ) external onlyCollateralManager {
        require(_orderManager != address(0), "Invalid OrderManager address");
        orderManager = _orderManager;
    }

    function addProduct(
        string calldata product,
        uint quantity,
        uint price
    ) public {
        require(sellers[product] == address(0), "Product already exists");
        require(
            collateralManager.isEnoughProductCollateral(
                product,
                price,
                quantity
            ),
            "Insufficient product collateral"
        );
        quantities[product] = quantity;
        sellers[product] = msg.sender;
        prices[product] = price;
    }

    function updateQuantities(
        string calldata product,
        uint quantity
    ) public onlySeller(product) {
        require(
            collateralManager.isEnoughProductCollateral(
                product,
                prices[product],
                quantity
            ),
            "Insufficient product collateral"
        );
        quantities[product] = quantity;
    }

    function updatePrice(
        string calldata product,
        uint price
    ) public onlySeller(product) {
        require(
            collateralManager.isEnoughProductCollateral(
                product,
                price,
                quantities[product]
            ),
            "Insufficient product collateral"
        );
        prices[product] = price;
    }

    function removeProduct(string calldata product) public onlySeller(product) {
        delete sellers[product];
        delete quantities[product];
        delete prices[product];
        collateralManager.refundProductCollateral(msg.sender, product);
    }

    function withdrawExcessProductCollateral(string calldata product) public {
        require(
            sellers[product] == msg.sender,
            "Only the seller can call this"
        );
        collateralManager.withdrawExcessProductCollateral(
            product,
            prices[product],
            quantities[product],
            msg.sender
        );
    }

    function order(
        string calldata product,
        uint quantity
    ) public onlyOrderManager {
        require(quantities[product] >= quantity, "Not enough product quantity");
        quantities[product] -= quantity;
    }
}
