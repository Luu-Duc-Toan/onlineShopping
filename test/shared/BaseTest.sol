// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

abstract contract BaseTest is Test {
    uint public price = 1000;
    uint public quantity = 10;
    uint public collateralPercent = 10;
    uint public amount = 100;

    address public admin;
    address public seller1;
    address public seller2;
    address public customer1;
    address public customer2;
    address public shipper1;
    address public shipper2;

    string public product = "testProduct";
    string public product2 = "testProduct2";

    function setUp() public virtual {
        admin = makeAddr("admin");
        seller1 = makeAddr("seller1");
        seller2 = makeAddr("seller2");
        customer1 = makeAddr("customer1");
        customer2 = makeAddr("customer2");
        shipper1 = makeAddr("shipper1");
        shipper2 = makeAddr("shipper2");

        vm.deal(admin, 100 ether);
        vm.deal(seller1, 100 ether);
        vm.deal(seller2, 100 ether);
        vm.deal(customer1, 100 ether);
        vm.deal(customer2, 100 ether);
        vm.deal(shipper1, 100 ether);
        vm.deal(shipper2, 100 ether);
    }
}
