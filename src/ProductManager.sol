// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract ProductManager {
    uint public collateralPercent = 10;
    mapping(string => uint) public collaterals;
    mapping(string => uint) public quantities;
    mapping(string => address) public sellers;
    mapping(string => uint) public preparingTimes;
    mapping(string => uint) public prices;

    modifier onlySeller(string calldata product) {
        require(
            sellers[product] == msg.sender,
            "Only the seller can call this"
        );
        _;
    }
    modifier isEnoughCollateral(
        uint collateral,
        uint price,
        uint quantity
    ) {
        uint requiredCollateral = (price * collateralPercent * quantity) / 100;
        require(collateral >= requiredCollateral, "Insufficient collateral");
        _;
    }

    function addProduct(
        string calldata product,
        uint quantity,
        uint preparingTime,
        uint price
    ) public payable isEnoughCollateral(msg.value, price, quantity) {
        require(sellers[product] == address(0), "Product already exists");
        quantities[product] = quantity;
        sellers[product] = msg.sender;
        preparingTimes[product] = preparingTime;
        prices[product] = price;
        collaterals[product] = msg.value;
    }

    function updateQuantities(
        string calldata product,
        uint quantity
    )
        public
        payable
        onlySeller(product)
        isEnoughCollateral(
            msg.value + collaterals[product],
            prices[product],
            quantity
        )
    {
        collaterals[product] += msg.value;
        quantities[product] = quantity;
    }

    function updatePreparingTime(
        string calldata product,
        uint preparingTime
    ) public onlySeller(product) {
        preparingTimes[product] = preparingTime;
    }

    function updatePrice(
        string calldata product,
        uint price
    )
        public
        payable
        onlySeller(product)
        isEnoughCollateral(
            msg.value + collaterals[product],
            price,
            quantities[product]
        )
    {
        collaterals[product] += msg.value;
        prices[product] = price;
    }

    function removeProduct(string calldata product) public onlySeller(product) {
        uint collateral = collaterals[product];

        //order
        delete sellers[product];
        delete quantities[product];
        delete preparingTimes[product];
        delete prices[product];
        delete collaterals[product];

        payable(msg.sender).transfer(collateral);
    }

    function withdrawExcessCollateral(
        string calldata product
    ) public onlySeller(product) {
        uint requiredCollateral = (prices[product] *
            collateralPercent *
            quantities[product]) / 100;
        require(
            collaterals[product] > requiredCollateral,
            "No excess collateral"
        );

        uint excessCollateral = collaterals[product] - requiredCollateral;
        collaterals[product] = requiredCollateral;
        payable(msg.sender).transfer(excessCollateral);
    }
}
