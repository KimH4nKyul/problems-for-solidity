// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {DayThreeVault} from "../src/DayThreeVault.sol";

contract DayThreeVaultTest is Test {
    address public user1 = makeAddr("test-user1");
    address public user2 = makeAddr("test-user2");

    DayThreeVault public sut;

    function setUp() public {
        // 여기서 정적 배열을 동적 배열로 암시적 변환할 수 없음
        // address[] 는 동적 배열을 인자로 받는 다는 것
        // 배열을 메모리에 선언하고 그 배열을 생성자에 전달해야 함
        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;

        sut = new DayThreeVault(1000, 1 minutes, users);
    }

    // Happy path:
    // allowlist 사용자가 두 번 입금 후 출금 요청
    // → vm.warp로 지연 시간을 건너뛰고 executeWithdrawal이 잔액/이벤트를 정확히 갱신하는지 확인
    function test_happy_path() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);

        sut.deposit{value: 1 ether}(); // 9 ether
        sut.deposit{value: 2 ether}(); // 7 ether

        vm.assertEq(1 ether + 2 ether, sut.totalDeposits());
        vm.assertEq(3 ether, sut.balanceOf(user1));

        sut.requestWithdrawal(1 ether, payable(user2));
        vm.warp(block.timestamp + 1 minutes);

        vm.expectEmit(true, true, true, true);
        emit DayThreeVault.WithdrawalExecuted(user1, 1 ether, user2);
        sut.executeWithdrawal();

        vm.assertEq(sut.balanceOf(user1), 2 ether);
        vm.assertEq(sut.totalDeposits(), 2 ether);

        vm.stopPrank();
    }

    // 출금 요청 중복:
    // 대기 중 요청이 있는 상태에서 다시 요청하면 PendingWithdrawalExists로 revert.
    function test_duplicate_withdrawal_request_then_revert_pending_withdrawal_exists() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);

        sut.deposit{value: 2 ether}();
        sut.requestWithdrawal(1 ether, payable(user2));

        vm.expectRevert(
            abi.encodeWithSelector(DayThreeVault.PendingWithdrawalExists.selector)
        );
        sut.requestWithdrawal(1 ether, payable(user2));
ㅗㅓㅗㅓ
        vm.stopPrank();
    }

    // 지연 시간 미도달:
    // executeWithdrawal을 지연 시간 이전에 호출하면 WithdrawalNotReady revert.
    function test_execute_withdrawal_before_delay_then_revert_withdrawal_not_ready() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);

        sut.deposit{value: 1 ether}(); // 9 ether
        sut.deposit{value: 2 ether}(); // 7 ether

        uint256 REQUEST_TIMEX = 10000;
        vm.warp(REQUEST_TIMEX);
        sut.requestWithdrawal(1 ether, payable(user2));

        uint256 EXPECTED_TIMEX = 10000 + 60;
        uint256 CURRENT_TIMEX = EXPECTED_TIMEX - 1;

        vm.warp(CURRENT_TIMEX);
        vm.expectRevert(
            abi.encodeWithSelector(DayThreeVault.WithdrawalNotReady.selector, EXPECTED_TIMEX, CURRENT_TIMEX)
        );
        sut.executeWithdrawal();

        vm.stopPrank();
    }

    // allowlist 제어:
    // 비오너가 setAllowlist 호출 시 NotOwner()로 revert하고,
    function test_user_try_set_allowlist_then_revert_not_owner() public {
        vm.startPrank(user1);

        vm.expectRevert(
            abi.encodeWithSelector(DayThreeVault.NotOwner.selector)
        );
        sut.setAllowlist(user2, false);

        vm.stopPrank();
    }

    // allowlist가 해제된 사용자는 입금이 불가함을 검증.
    function test_owner_set_allowlist_then_user_cannot_deposit() public {
        sut.setAllowlist(user2, false);

        vm.startPrank(user2);
        vm.deal(user2, 10 ether);

        vm.expectRevert(abi.encodeWithSelector(DayThreeVault.NotAllowlisted.selector, user2));
        sut.deposit{value: 1 ether}();

        vm.stopPrank();
    }

    // 취소 플로우:
    // 요청 후 cancelWithdrawal이 대기 중 금액을 삭제하고
    // WithdrawalCancelled 이벤트를 남기는지 확인.
    function test_cancel_withdrawal() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);

        sut.deposit{value: 3 ether}();
        sut.requestWithdrawal(2 ether, payable(user2));

        vm.expectEmit(true, true, true, true);
        emit DayThreeVault.WithdrawalCancelled(user1, 2 ether);
        sut.cancelWithdrawal();

        vm.stopPrank();
    }

    // 잔액 부족:
    // 잔액보다 큰 금액을 요청하거나 실행 시
    // InsufficientBalance가 발생하는지 확인.
    function test_request_withdrawal_greater_than_balance_then_revert_insufficient_balance() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);

        sut.deposit{value: 1 ether}();

        vm.expectRevert(abi.encodeWithSelector(DayThreeVault.InsufficientBalance.selector, 2 ether, 1 ether));
        sut.requestWithdrawal(2 ether, payable(user2));

        vm.stopPrank();
    }

    function test_execute_withdrawal_greater_than_balance_then_revert_insufficient_balance() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);

        sut.deposit{value: 3 ether}();
        sut.requestWithdrawal(2 ether, payable(user2));

        vm.warp(block.timestamp + sut.minDelay());

        // balances mapping 은 slot 1에 위치한다: keccak256(abi.encode(user, uint256(1))).
        // immutable은 배포 시 바이트코드에 저장되고 스토리지 슬롯을 차지하지 않는다.
        // 실제 스토리지 배치는 선언 순서에서 mutable 상태 변수만 차례대로 슬롯을 먹는다.
        bytes32 balanceSlot = keccak256(abi.encode(user1, uint256(1)));
        vm.store(address(sut), balanceSlot, bytes32(uint256(1 ether)));

        vm.expectRevert(abi.encodeWithSelector(DayThreeVault.InsufficientBalance.selector, 2 ether, 1 ether));
        sut.executeWithdrawal(); // 3 ether가 있어야 하는데 1 ether 뿐임

        vm.stopPrank();
    }
}
