// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "./ProductManager.sol";
import "./OrderManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

contract CollateralManager is Ownable {
    address public productManager;
    address public orderManager;

    uint productCollateralPercent;
    mapping(string => uint) public productCollaterals;
    mapping(address => uint) public shippingDeposits;
    mapping(uint => uint) public orderCollaterals; //customerCollateral (1p) + shippingCollateral (1p) + sellerCollateral (0,.p) + shippingFee
    mapping(address => uint) public balances;
    mapping(uint => bool) public isOrderDisputed;

    constructor(uint _productCollateralPercent) Ownable(msg.sender) {
        require(_productCollateralPercent > 0, "Invalid collateral percent");
        productCollateralPercent = _productCollateralPercent;
        productManager = address(new ProductManager(address(this)));
        orderManager = address(
            new OrderManager(msg.sender, address(this), productManager)
        );
        ProductManager(productManager).setOrderManager(orderManager);
    }

    modifier onlyProductManager() {
        require(
            msg.sender == address(productManager),
            "Only ProductManager can call this"
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

    modifier validPrice(uint price) {
        require(price > 0 && price <= type(uint120).max, "Invalid price");
        _;
    }

    modifier validQuantity(uint quantity) {
        require(
            quantity > 0 && quantity <= type(uint120).max,
            "Invalid quantity"
        );
        _;
    }

    function addProductCollateral(string calldata product) external payable {
        require(msg.value > 0, "Collateral must be greater than 0");
        productCollaterals[product] += msg.value;
    }

    function shippingServiceDeposit() external payable {
        require(msg.value > 0, "Deposit must be greater than 0");
        shippingDeposits[msg.sender] += msg.value;
    }

    function isEnoughProductCollateral(
        string calldata product,
        uint price,
        uint quantity
    ) public view validPrice(price) validQuantity(quantity) returns (bool) {
        uint requiredCollateral = (price *
            productCollateralPercent *
            quantity) / 100;
        return productCollaterals[product] >= requiredCollateral;
    }

    function getRequiredSellerCollateral(
        uint price,
        uint quantity
    ) public view validPrice(price) validQuantity(quantity) returns (uint) {
        return (price * productCollateralPercent * quantity + 99) / 100;
    }

    function getRequiredCustomerCollateral(
        uint price,
        uint quantity
    ) public pure validPrice(price) validQuantity(quantity) returns (uint) {
        return price * quantity;
    }

    function getRequiredShippingServiceCollateral(
        uint price,
        uint quantity
    ) public pure validPrice(price) validQuantity(quantity) returns (uint) {
        return price * quantity;
    }

    function refundProductCollateral(
        address seller,
        string calldata product
    ) public onlyProductManager {
        uint collateral = productCollaterals[product];
        productCollaterals[product] = 0;
        payable(seller).transfer(collateral);
    }

    function withdrawExcessProductCollateral(
        string calldata product,
        uint price,
        uint quantity,
        address seller
    ) public onlyProductManager {
        uint requiredCollateral = getRequiredSellerCollateral(price, quantity);
        uint excessCollateral = productCollaterals[product] -
            requiredCollateral;
        productCollaterals[product] = requiredCollateral;
        balances[seller] += excessCollateral;
    }

    function order(
        uint orderIndex,
        string calldata product,
        uint price,
        uint quantity
    ) public payable onlyOrderManager {
        uint requiredCollateral = getRequiredCustomerCollateral(
            price,
            quantity
        );

        require(msg.value == requiredCollateral, "Invalid customer collateral");

        uint requiredSellerCollateral = getRequiredSellerCollateral(
            price,
            quantity
        );
        productCollaterals[product] -= requiredSellerCollateral;
        orderCollaterals[orderIndex] += requiredSellerCollateral + msg.value;
    }

    function depositShippingFee(
        uint orderIndex
    ) public payable onlyOrderManager {
        orderCollaterals[orderIndex] += msg.value;
    }

    function takeOrder(
        uint orderIndex,
        uint price,
        uint quantity,
        address shippingService
    ) public onlyOrderManager {
        uint requiredCollateral = getRequiredShippingServiceCollateral(
            price,
            quantity
        );
        console.log("Requried: ", requiredCollateral);
        console.log("Deposit: ", shippingDeposits[shippingService]);
        require(
            shippingDeposits[shippingService] >= requiredCollateral,
            "Insufficient shipping deposit"
        );
        shippingDeposits[shippingService] -= requiredCollateral;
        orderCollaterals[orderIndex] += requiredCollateral;
    }

    function confirm(
        uint orderIndex,
        uint price,
        uint quantity,
        address seller,
        address shippingService
    ) public onlyOrderManager {
        require(!isOrderDisputed[orderIndex], "Order is disputed");
        uint collateral = orderCollaterals[orderIndex];
        uint requiredSellerCollateral = getRequiredSellerCollateral(
            price,
            quantity
        );
        uint sellerEarning = requiredSellerCollateral + price * quantity;

        balances[seller] += sellerEarning;
        balances[shippingService] += collateral - sellerEarning;
        orderCollaterals[orderIndex] = 0;
    }

    function customerRefund(
        uint orderIndex,
        address customer
    ) public onlyOrderManager {
        balances[customer] += orderCollaterals[orderIndex];
        orderCollaterals[orderIndex] = 0;
    }

    function dispute(uint orderIndex) public onlyOrderManager {
        require(!isOrderDisputed[orderIndex], "Order already disputed");
        isOrderDisputed[orderIndex] = true;
    }

    function resolveDispute(
        uint orderIndex,
        uint price,
        uint quantity,
        address customer,
        address seller,
        address shippingService,
        bool isCustomerWin
    ) public onlyOrderManager {
        require(isOrderDisputed[orderIndex], "Order is not disputed");
        isOrderDisputed[orderIndex] = false;
        uint sellerEarnings = price *
            quantity +
            getRequiredSellerCollateral(price, quantity);
        if (isCustomerWin) {
            balances[customer] += orderCollaterals[orderIndex] - sellerEarnings;
        } else {
            balances[shippingService] +=
                orderCollaterals[orderIndex] -
                sellerEarnings;
        }
        balances[seller] += sellerEarnings;
        orderCollaterals[orderIndex] = 0;
    }

    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function shippingServiceWithdraw(uint amount) public {
        require(
            shippingDeposits[msg.sender] >= amount,
            "Insufficient shipping deposit"
        );
        unchecked {
            shippingDeposits[msg.sender] -= amount;
        }
        payable(msg.sender).transfer(amount);
    }
}
