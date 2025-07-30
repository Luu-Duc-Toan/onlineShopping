// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../base/CollateralManagerTestBase.sol";

contract WithdrawTest is CollateralManagerTestBase {
    function setUp() public override {
        super.setUp();
    }

    function testWithdrawInsufficientBalanceReverts() public {
        vm.expectRevert("Insufficient balance");
        vm.prank(customer1);
        collateralManager.withdraw(amount);
    }

    function testWithdrawSuccess() public {
        uint withdrawAmount = amount;

        vm.deal(address(collateralManager), withdrawAmount);
        vm.store(
            address(collateralManager),
            keccak256(abi.encode(customer1, uint256(7))), // balances mapping is at slot 7
            bytes32(withdrawAmount)
        );

        uint customerBalanceBefore = customer1.balance;
        uint contractBalanceBefore = address(collateralManager).balance;

        vm.prank(customer1);
        collateralManager.withdraw(withdrawAmount);

        assertEq(customer1.balance, customerBalanceBefore + withdrawAmount);
        assertEq(
            address(collateralManager).balance,
            contractBalanceBefore - withdrawAmount
        );
        assertEq(collateralManager.balances(customer1), 0);
    }

    function testWithdrawPartialAmount() public {
        uint totalBalance = amount * 2;
        uint withdrawAmount = totalBalance - amount;

        vm.deal(address(collateralManager), totalBalance);
        vm.store(
            address(collateralManager),
            keccak256(abi.encode(customer1, uint256(7))),
            bytes32(totalBalance)
        );

        uint customerBalanceBefore = customer1.balance;

        vm.prank(customer1);
        collateralManager.withdraw(withdrawAmount);

        assertEq(customer1.balance, customerBalanceBefore + withdrawAmount);
        assertEq(
            collateralManager.balances(customer1),
            totalBalance - withdrawAmount
        );
    }

    function testWithdrawZeroAmount() public {
        uint totalBalance = amount;

        vm.deal(address(collateralManager), totalBalance);
        vm.store(
            address(collateralManager),
            keccak256(abi.encode(customer1, uint256(7))),
            bytes32(totalBalance)
        );

        uint customerBalanceBefore = customer1.balance;

        vm.prank(customer1);
        collateralManager.withdraw(0);

        assertEq(customer1.balance, customerBalanceBefore);
        assertEq(collateralManager.balances(customer1), totalBalance);
    }

    function testWithdrawFromMultipleAccounts() public {
        uint balance1 = amount;
        uint balance2 = amount * 2;

        vm.deal(address(collateralManager), balance1 + balance2);
        vm.store(
            address(collateralManager),
            keccak256(abi.encode(customer1, uint256(7))),
            bytes32(balance1)
        );
        vm.store(
            address(collateralManager),
            keccak256(abi.encode(customer2, uint256(7))),
            bytes32(balance2)
        );

        uint customer1BalanceBefore = customer1.balance;
        uint customer2BalanceBefore = customer2.balance;
        uint contractBalanceBefore = address(collateralManager).balance;

        vm.prank(customer1);
        collateralManager.withdraw(balance1);
        vm.prank(customer2);
        collateralManager.withdraw(balance2);

        assertEq(customer1.balance, customer1BalanceBefore + balance1);
        assertEq(customer2.balance, customer2BalanceBefore + balance2);
        assertEq(collateralManager.balances(customer1), 0);
        assertEq(collateralManager.balances(customer2), 0);
        assertEq(
            address(collateralManager).balance,
            contractBalanceBefore - (balance1 + balance2)
        );
    }

    function testFuzzWithdraw(
        uint256 withdrawAmount,
        uint256 userBalance
    ) public {
        userBalance = bound(userBalance, 0, 1000 ether);
        withdrawAmount = bound(withdrawAmount, 0, userBalance);

        if (userBalance > 0) {
            vm.deal(address(collateralManager), userBalance);
            vm.store(
                address(collateralManager),
                keccak256(abi.encode(customer1, uint256(7))),
                bytes32(userBalance)
            );
        }

        uint customerBalanceBefore = customer1.balance;

        if (withdrawAmount <= userBalance) {
            vm.prank(customer1);
            collateralManager.withdraw(withdrawAmount);
            assertEq(customer1.balance, customerBalanceBefore + withdrawAmount);
            assertEq(
                collateralManager.balances(customer1),
                userBalance - withdrawAmount
            );
        } else {
            vm.expectRevert("Insufficient balance");
            vm.prank(customer1);
            collateralManager.withdraw(withdrawAmount);
        }
    }
}
