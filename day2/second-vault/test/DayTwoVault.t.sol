// SPDX-LICENSED-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {DayTwoVault} from "../src/DayTwoVault.sol";

contract DayTwoVaultTest is Test {
    DayTwoVault public sut;
    address public owner = makeAddr("owner");

    function setUp() public {
        vm.startPrank(owner);

        string memory greeting = "First";
        uint256 minDeposit = 1e18; // 1 ether
        sut = new DayTwoVault(greeting, minDeposit);

        vm.stopPrank();
    }

    function test_can_deposit_and_read_total_deposits() public {
        address user = makeAddr("user");
        vm.deal(user, 10 ether);

        vm.startPrank(user);


        vm.expectEmit(true, true, false, true);
        emit DayTwoVault.Deposited(user, 5 ether, 5 ether);
        sut.deposit{ value: 5 ether }();

        vm.expectEmit(true, true, false, true);
        emit DayTwoVault.Deposited(user, 2 ether, 7 ether);
        sut.deposit{ value: 2 ether }();

        vm.assertEq(user.balance, 3 ether);

        uint256 totalDeposits = sut.totalDeposits();
        vm.assertEq(totalDeposits, 7 ether);

        vm.stopPrank();
    }

    function test_can_get_balance_of() public {
        address user = makeAddr("user");
        vm.deal(user, 1 ether);

        vm.startPrank(user);
        uint256 result = sut.balanceOf(user);
        vm.assertEq(result, 0 ether);

        sut.deposit{ value: 1 ether }();
        uint256 result2 = sut.balanceOf(user);
        vm.assertEq(result2, 1 ether);

        vm.stopPrank();
    }

    function test_withdraw_with_zero_address_than_revert_invalid_amount() public {
        address user1 = makeAddr("user1");
        address payable user2 = payable(address(0));

        vm.deal(user1, 1 ether);

        vm.startPrank(user1);
        sut.deposit{ value: 1 ether }();

        vm.expectRevert(
            abi.encodeWithSelector(DayTwoVault.InvalidAmount.selector, 0)
        );
        sut.withdraw(1 ether, user2);

        vm.stopPrank();
    }

    function test_withdraw_with_negative_amount_than_revert_insufficient_balance() public {
        address user1 = makeAddr("user1");
        address payable user2 = payable(makeAddr("user2"));

        vm.deal(user1, 10 ether);
        vm.deal(user2, 1 ether);

        vm.startPrank(user1);

        sut.deposit{value: 1 ether }();
        sut.withdraw(1 ether, user2);

        vm.expectRevert(
            abi.encodeWithSelector(
                DayTwoVault.InsufficientBalance.selector, 1 ether, 0 ether
            )
        );
        sut.withdraw(1 ether, user2);

        vm.stopPrank();
    }

    function test_withdraw_with_zero_amount_then_revert_invalid_amount() public {
        address user1 = makeAddr("user1");
        address payable user2 = payable(makeAddr("user2"));

        vm.deal(user1, 10 ether);
        vm.deal(user2, 1 ether);

        vm.startPrank(user1);

        vm.expectRevert(
            abi.encodeWithSelector(DayTwoVault.InvalidAmount.selector, 0)
        );
        sut.withdraw(0 ether, user2);

        vm.stopPrank();
    }

    function test_withdraw_then_emit_withdrawn() public {
        address user1 = makeAddr("user1");
        address payable user2 = payable(makeAddr("user2"));

        vm.deal(user1, 10 ether);

        vm.startPrank(user1);

        sut.deposit{ value : 5 ether }();

        vm.expectEmit(true, true, false, true);
        emit DayTwoVault.Withdrawn(user1, 1 ether, 4 ether);
        sut.withdraw(1 ether, user2);

        vm.stopPrank();
    }

    function test_can_withdraw() public {
        address user1 = makeAddr("user1");
        address payable user2 = payable(makeAddr("user2"));

        vm.deal(user1, 10 ether);
        vm.deal(user2, 1 ether);

        vm.startPrank(user1);

        sut.deposit{ value : 5 ether }();
        sut.withdraw(1 ether, user2);

        uint256 user1Balance = sut.balanceOf(user1);
        vm.assertEq(user1Balance, 4 ether);

        vm.stopPrank();
    }

    function test_deposit_with_value_smaller_than_min_deposit_then_revert_deposit_too_small() public {
        address user = makeAddr("user");
        vm.deal(user, 10 ether);

        vm.startPrank(user);

        vm.expectRevert(abi.encodeWithSelector(DayTwoVault.DepositTooSmall.selector, 0.1 ether, 1_000_000_000_000_000_000));
        sut.deposit{ value: 0.1 ether }();

        vm.stopPrank();
    }

    function test_deposit_with_zero_value_then_revert_invalid_amount() public {
        address user = makeAddr("user");
        vm.deal(user, 10 ether);

        vm.startPrank(user);

        vm.expectRevert(
            abi.encodeWithSelector(DayTwoVault.InvalidAmount.selector, 0)
        );
        sut.deposit{ value: 0 }();

        vm.stopPrank();
    }

    function test_user_can_deposit() public {
        address user = makeAddr("user");
        vm.deal(user, 10 ether);

        vm.startPrank(user);

        sut.deposit{ value: 1 ether }();
        uint256 balance = sut.balanceOf(user);
        vm.assertEq(balance, 1 ether);

        vm.stopPrank();
    }

    function test_owner_set_greeting_then_emit_greeting_changed() public {
        vm.startPrank(owner);

        vm.expectEmit(true, true, false, true);
        emit DayTwoVault.GreetingChanged(owner, "First", "Second");

        sut.setGreeting("Second");

        vm.stopPrank();
    }

    function test_user_set_greeting_then_revert_not_owner() public {
        address user = makeAddr("user");
        vm.startPrank(user);

        vm.expectRevert(abi.encodeWithSelector(DayTwoVault.NotOwner.selector));
        sut.setGreeting("User's Greeting");

        vm.stopPrank();
    }

    function test_owner_set_greeting_with_zero_value_then_revert_invalid_amount() public {
        vm.startPrank(owner);

        string memory greeting = "";
        vm.expectRevert(abi.encodeWithSelector(DayTwoVault.InvalidAmount.selector, 0));
        sut.setGreeting(greeting);

        vm.stopPrank();
    }

    function test_owner_can_set_greeting() public {
        vm.startPrank(owner);

        string memory greeting = "Second";
        sut.setGreeting(greeting);

        vm.stopPrank();
    }
}