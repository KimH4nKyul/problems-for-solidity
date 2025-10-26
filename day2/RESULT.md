# Day 2 결과 제출서

## 1. 과제 수행 체크리스트
- [x] `DayTwoVault` 컨트랙트 구현 (요구된 상태 변수, 이벤트, 커스텀 에러 포함)
- [x] `deposit`, `withdraw`, `setGreeting`, `balanceOf`, `getGreeting` 요구사항 충족
- [x] `DayTwoVault` 단위 테스트 5개 이상 작성 및 모든 시나리오 검증
- [x] 커스텀 에러를 `abi.encodeWithSelector` 형태로 테스트에서 검증
- [x] `forge build`, `forge test -vvvv`, `forge test --gas-report` 실행
- [x] `forge test --gas-report`에서 `deposit`, `withdraw`, `setGreeting` 평균 가스 사용량 요약

```text
deposit: 68128 gas
withdraw: 30494 gas
setGreeting: 27349 gas (string calldata _greeting) -> 27602 gas (string memory _greeting) 
```

## 2. 구현 요약
- 금고 설계 의도와 핵심 상태 변수 설명:
  - 해당 금고는 컨트랙트 소유주, 사용자 주소별 예치금 매핑, 전체 예치액을 추적할 수 있음
  - 소유주만 실행할 수 있는 함수인 인삿말 변경
  - 사용자들이 너무 작은 금액을 입금해 스팸 트랜잭션이나 가스 비용 대비 효율 감소를 초래하지 못하게 최소 입금 금액 설정 
  - immutable 상태 변수를 이용해 최초 런타임 시점에 이더리움 글로벌 변수를 이용한 상수 설정
  - modifier를 이용해 주요 revert에 대한 보일러 플레이트 코드 생성 방지 
  - 주요 함수별로 이벤트를 발행해 오프체인에서 로그 추적 가능하도록 개발 
- 커스텀 에러와 이벤트 설계 이유:
  - 주요 함수별로 이벤트를 발행해 오프체인에서 로그 추적 가능하도록 개발
  - 커스텀 에러를 통해 require에 문자열을 담는 것 대비 가스비 절감 효과 
- 입/출금 로직에서 지킨 불변식과 상태 업데이트 순서:
  - 입금) 최소 입금 금액보다 작은 전송 금액은 입금 불가 -> [통과시] 해당 주소의 잔액 금고 및 전체 예치액 업데이트 -> 입금 이벤트 발행  
  - 출금) 지정한 수신인이 제로 어드레스인 경우, 전송인의 잔금이 0보다 작거나 같음 또는 전송인의 잔금이 보내려는 금액보다 작은 경우 지정한 수신인에게 지정 금액을 보낼 수 없음 -> [통과시] 잔액와 전체 잔금 감소 -> 수신인에게 송금 -> 출금 이벤트 발행 

## 3. 테스트 증거
- 수행한 명령어와 핵심 로그:
```
$ forge build
[⠊] Compiling...
[⠆] Compiling 2 files with Solc 0.8.30
[⠰] Solc 0.8.30 finished in 292.39ms
Compiler run successful!
note[screaming-snake-case-immutable]: immutables should use SCREAMING_SNAKE_CASE
 --> src/DayTwoVault.sol:5:30
  |
5 |     address public immutable owner; // deployer address
  |                              ^^^^^
  |
  = help: https://book.getfoundry.sh/reference/forge/forge-lint#screaming-snake-case-immutable

note[screaming-snake-case-immutable]: immutables should use SCREAMING_SNAKE_CASE
 --> src/DayTwoVault.sol:6:30
  |
6 |     uint256 public immutable minDeposit; // 최소 입금 단위 (wei, 1e18 = 1 ether)
  |                              ^^^^^^^^^^
  |
  = help: https://book.getfoundry.sh/reference/forge/forge-lint#screaming-snake-case-immutable

$ forge test -vvvv
No files changed, compilation skipped

Ran 14 tests for test/DayTwoVault.t.sol:DayTwoVaultTest
[PASS] test_can_deposit_and_read_total_deposits() (gas: 84400)
Traces:
  [84400] DayTwoVaultTest::test_can_deposit_and_read_total_deposits()
    ├─ [0] VM::addr(<pk>) [staticcall]
    │   └─ ← [Return] user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D]
    ├─ [0] VM::label(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D], "user")
    │   └─ ← [Return]
    ├─ [0] VM::deal(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D], 10000000000000000000 [1e19])
    │   └─ ← [Return]
    ├─ [0] VM::startPrank(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D])
    │   └─ ← [Return]
    ├─ [0] VM::expectEmit(true, true, false, true)
    │   └─ ← [Return]
    ├─ emit Deposited(account: user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D], amount: 5000000000000000000 [5e18], newBalance: 5000000000000000000 [5e18])
    ├─ [47064] DayTwoVault::deposit{value: 5000000000000000000}()
    │   ├─ emit Deposited(account: user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D], amount: 5000000000000000000 [5e18], newBalance: 5000000000000000000 [5e18])
    │   └─ ← [Stop]
    ├─ [0] VM::expectEmit(true, true, false, true)
    │   └─ ← [Return]
    ├─ emit Deposited(account: user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D], amount: 2000000000000000000 [2e18], newBalance: 7000000000000000000 [7e18])
    ├─ [3264] DayTwoVault::deposit{value: 2000000000000000000}()
    │   ├─ emit Deposited(account: user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D], amount: 2000000000000000000 [2e18], newBalance: 7000000000000000000 [7e18])
    │   └─ ← [Stop]
    ├─ [0] VM::assertEq(3000000000000000000 [3e18], 3000000000000000000 [3e18]) [staticcall]
    │   └─ ← [Return]
    ├─ [491] DayTwoVault::totalDeposits() [staticcall]
    │   └─ ← [Return] 7000000000000000000 [7e18]
    ├─ [0] VM::assertEq(7000000000000000000 [7e18], 7000000000000000000 [7e18]) [staticcall]
    │   └─ ← [Return]
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return]
    └─ ← [Stop]

[PASS] test_can_get_balance_of() (gas: 70217)
Traces:
  [70217] DayTwoVaultTest::test_can_get_balance_of()
    ├─ [0] VM::addr(<pk>) [staticcall]
    │   └─ ← [Return] user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D]
    ├─ [0] VM::label(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D], "user")
    │   └─ ← [Return]
    ├─ [0] VM::deal(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D], 1000000000000000000 [1e18])
    │   └─ ← [Return]
    ├─ [0] VM::startPrank(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D])
    │   └─ ← [Return]
    ├─ [2874] DayTwoVault::balanceOf(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D]) [staticcall]
    │   └─ ← [Return] 0
    ├─ [0] VM::assertEq(0, 0) [staticcall]
    │   └─ ← [Return]
    ├─ [45064] DayTwoVault::deposit{value: 1000000000000000000}()
    │   ├─ emit Deposited(account: user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D], amount: 1000000000000000000 [1e18], newBalance: 1000000000000000000 [1e18])
    │   └─ ← [Stop]
    ├─ [874] DayTwoVault::balanceOf(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D]) [staticcall]
    │   └─ ← [Return] 1000000000000000000 [1e18]
    ├─ [0] VM::assertEq(1000000000000000000 [1e18], 1000000000000000000 [1e18]) [staticcall]
    │   └─ ← [Return]
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return]
    └─ ← [Stop]

[PASS] test_can_withdraw() (gas: 82957)
Traces:
  [82957] DayTwoVaultTest::test_can_withdraw()
    ├─ [0] VM::addr(<pk>) [staticcall]
    │   └─ ← [Return] user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF]
    ├─ [0] VM::label(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], "user1")
    │   └─ ← [Return]
    ├─ [0] VM::addr(<pk>) [staticcall]
    │   └─ ← [Return] user2: [0x537C8f3d3E18dF5517a58B3fB9D9143697996802]
    ├─ [0] VM::label(user2: [0x537C8f3d3E18dF5517a58B3fB9D9143697996802], "user2")
    │   └─ ← [Return]
    ├─ [0] VM::deal(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], 10000000000000000000 [1e19])
    │   └─ ← [Return]
    ├─ [0] VM::deal(user2: [0x537C8f3d3E18dF5517a58B3fB9D9143697996802], 1000000000000000000 [1e18])
    │   └─ ← [Return]
    ├─ [0] VM::startPrank(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF])
    │   └─ ← [Return]
    ├─ [47064] DayTwoVault::deposit{value: 5000000000000000000}()
    │   ├─ emit Deposited(account: user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], amount: 5000000000000000000 [5e18], newBalance: 5000000000000000000 [5e18])
    │   └─ ← [Stop]
    ├─ [11268] DayTwoVault::withdraw(1000000000000000000 [1e18], user2: [0x537C8f3d3E18dF5517a58B3fB9D9143697996802])
    │   ├─ [0] user2::fallback{value: 1000000000000000000}()
    │   │   └─ ← [Stop]
    │   ├─ emit Withdrawn(account: user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], amount: 1000000000000000000 [1e18], remainingBalance: 4000000000000000000 [4e18])
    │   └─ ← [Stop]
    ├─ [874] DayTwoVault::balanceOf(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF]) [staticcall]
    │   └─ ← [Return] 4000000000000000000 [4e18]
    ├─ [0] VM::assertEq(4000000000000000000 [4e18], 4000000000000000000 [4e18]) [staticcall]
    │   └─ ← [Return]
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return]
    └─ ← [Stop]

[PASS] test_deposit_with_value_smaller_than_min_deposit_then_revert_deposit_too_small() (gas: 20108)
Traces:
  [20108] DayTwoVaultTest::test_deposit_with_value_smaller_than_min_deposit_then_revert_deposit_too_small()
    ├─ [0] VM::addr(<pk>) [staticcall]
    │   └─ ← [Return] user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D]
    ├─ [0] VM::label(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D], "user")
    │   └─ ← [Return]
    ├─ [0] VM::deal(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D], 10000000000000000000 [1e19])
    │   └─ ← [Return]
    ├─ [0] VM::startPrank(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D])
    │   └─ ← [Return]
    ├─ [0] VM::expectRevert(custom error 0xf28dceb3: 000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000444a77f2fa000000000000000000000000000000000000000000000000016345785d8a00000000000000000000000000000000000000000000000000000de0b6b3a764000000000000000000000000000000000000000000000000000000000000)
    │   └─ ← [Return]
    ├─ [529] DayTwoVault::deposit{value: 100000000000000000}()
    │   └─ ← [Revert] DepositTooSmall(100000000000000000 [1e17], 1000000000000000000 [1e18])
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return]
    └─ ← [Stop]

[PASS] test_deposit_with_zero_value_then_revert_invalid_amount() (gas: 13131)
Traces:
  [13131] DayTwoVaultTest::test_deposit_with_zero_value_then_revert_invalid_amount()
    ├─ [0] VM::addr(<pk>) [staticcall]
    │   └─ ← [Return] user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D]
    ├─ [0] VM::label(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D], "user")
    │   └─ ← [Return]
    ├─ [0] VM::deal(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D], 10000000000000000000 [1e19])
    │   └─ ← [Return]
    ├─ [0] VM::startPrank(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D])
    │   └─ ← [Return]
    ├─ [0] VM::expectRevert(custom error 0xf28dceb3: 000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000243728b83d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000)
    │   └─ ← [Return]
    ├─ [517] DayTwoVault::deposit()
    │   └─ ← [Revert] InvalidAmount(0)
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return]
    └─ ← [Stop]

[PASS] test_owner_can_set_greeting() (gas: 21761)
Traces:
  [21761] DayTwoVaultTest::test_owner_can_set_greeting()
    ├─ [0] VM::startPrank(owner: [0x7c8999dC9a822c1f0Df42023113EDB4FDd543266])
    │   └─ ← [Return]
    ├─ [10525] DayTwoVault::setGreeting("Second")
    │   ├─ emit GreetingChanged(changer: owner: [0x7c8999dC9a822c1f0Df42023113EDB4FDd543266], prevGreeting: "First", newGreeting: "Second")
    │   └─ ← [Stop]
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return]
    └─ ← [Stop]

[PASS] test_owner_set_greeting_then_emit_greeting_changed() (gas: 25547)
Traces:
  [25547] DayTwoVaultTest::test_owner_set_greeting_then_emit_greeting_changed()
    ├─ [0] VM::startPrank(owner: [0x7c8999dC9a822c1f0Df42023113EDB4FDd543266])
    │   └─ ← [Return]
    ├─ [0] VM::expectEmit(true, true, false, true)
    │   └─ ← [Return]
    ├─ emit GreetingChanged(changer: owner: [0x7c8999dC9a822c1f0Df42023113EDB4FDd543266], prevGreeting: "First", newGreeting: "Second")
    ├─ [10525] DayTwoVault::setGreeting("Second")
    │   ├─ emit GreetingChanged(changer: owner: [0x7c8999dC9a822c1f0Df42023113EDB4FDd543266], prevGreeting: "First", newGreeting: "Second")
    │   └─ ← [Stop]
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return]
    └─ ← [Stop]

[PASS] test_owner_set_greeting_with_zero_value_then_revert_invalid_amount() (gas: 13205)
Traces:
  [13205] DayTwoVaultTest::test_owner_set_greeting_with_zero_value_then_revert_invalid_amount()
    ├─ [0] VM::startPrank(owner: [0x7c8999dC9a822c1f0Df42023113EDB4FDd543266])
    │   └─ ← [Return]
    ├─ [0] VM::expectRevert(custom error 0xf28dceb3: 000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000243728b83d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000)
    │   └─ ← [Return]
    ├─ [886] DayTwoVault::setGreeting("")
    │   └─ ← [Revert] InvalidAmount(0)
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return]
    └─ ← [Stop]

[PASS] test_user_can_deposit() (gas: 67717)
Traces:
  [67717] DayTwoVaultTest::test_user_can_deposit()
    ├─ [0] VM::addr(<pk>) [staticcall]
    │   └─ ← [Return] user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D]
    ├─ [0] VM::label(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D], "user")
    │   └─ ← [Return]
    ├─ [0] VM::deal(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D], 10000000000000000000 [1e19])
    │   └─ ← [Return]
    ├─ [0] VM::startPrank(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D])
    │   └─ ← [Return]
    ├─ [47064] DayTwoVault::deposit{value: 1000000000000000000}()
    │   ├─ emit Deposited(account: user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D], amount: 1000000000000000000 [1e18], newBalance: 1000000000000000000 [1e18])
    │   └─ ← [Stop]
    ├─ [874] DayTwoVault::balanceOf(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D]) [staticcall]
    │   └─ ← [Return] 1000000000000000000 [1e18]
    ├─ [0] VM::assertEq(1000000000000000000 [1e18], 1000000000000000000 [1e18]) [staticcall]
    │   └─ ← [Return]
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return]
    └─ ← [Stop]

[PASS] test_user_set_greeting_then_revert_not_owner() (gas: 12378)
Traces:
  [12378] DayTwoVaultTest::test_user_set_greeting_then_revert_not_owner()
    ├─ [0] VM::addr(<pk>) [staticcall]
    │   └─ ← [Return] user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D]
    ├─ [0] VM::label(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D], "user")
    │   └─ ← [Return]
    ├─ [0] VM::startPrank(user: [0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D])
    │   └─ ← [Return]
    ├─ [0] VM::expectRevert(custom error 0xf28dceb3: 0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000430cd747100000000000000000000000000000000000000000000000000000000)
    │   └─ ← [Return]
    ├─ [570] DayTwoVault::setGreeting("User's Greeting")
    │   └─ ← [Revert] NotOwner()
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return]
    └─ ← [Stop]

[PASS] test_withdraw_then_emit_withdrawn() (gas: 110088)
Traces:
  [110088] DayTwoVaultTest::test_withdraw_then_emit_withdrawn()
    ├─ [0] VM::addr(<pk>) [staticcall]
    │   └─ ← [Return] user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF]
    ├─ [0] VM::label(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], "user1")
    │   └─ ← [Return]
    ├─ [0] VM::addr(<pk>) [staticcall]
    │   └─ ← [Return] user2: [0x537C8f3d3E18dF5517a58B3fB9D9143697996802]
    ├─ [0] VM::label(user2: [0x537C8f3d3E18dF5517a58B3fB9D9143697996802], "user2")
    │   └─ ← [Return]
    ├─ [0] VM::deal(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], 10000000000000000000 [1e19])
    │   └─ ← [Return]
    ├─ [0] VM::startPrank(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF])
    │   └─ ← [Return]
    ├─ [47064] DayTwoVault::deposit{value: 5000000000000000000}()
    │   ├─ emit Deposited(account: user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], amount: 5000000000000000000 [5e18], newBalance: 5000000000000000000 [5e18])
    │   └─ ← [Stop]
    ├─ [0] VM::expectEmit(true, true, false, true)
    │   └─ ← [Return]
    ├─ emit Withdrawn(account: user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], amount: 1000000000000000000 [1e18], remainingBalance: 4000000000000000000 [4e18])
    ├─ [38768] DayTwoVault::withdraw(1000000000000000000 [1e18], user2: [0x537C8f3d3E18dF5517a58B3fB9D9143697996802])
    │   ├─ [0] user2::fallback{value: 1000000000000000000}()
    │   │   └─ ← [Stop]
    │   ├─ emit Withdrawn(account: user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], amount: 1000000000000000000 [1e18], remainingBalance: 4000000000000000000 [4e18])
    │   └─ ← [Stop]
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return]
    └─ ← [Stop]

[PASS] test_withdraw_with_negative_amount_than_revert_insufficient_balance() (gas: 63148)
Traces:
  [84201] DayTwoVaultTest::test_withdraw_with_negative_amount_than_revert_insufficient_balance()
    ├─ [0] VM::addr(<pk>) [staticcall]
    │   └─ ← [Return] user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF]
    ├─ [0] VM::label(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], "user1")
    │   └─ ← [Return]
    ├─ [0] VM::addr(<pk>) [staticcall]
    │   └─ ← [Return] user2: [0x537C8f3d3E18dF5517a58B3fB9D9143697996802]
    ├─ [0] VM::label(user2: [0x537C8f3d3E18dF5517a58B3fB9D9143697996802], "user2")
    │   └─ ← [Return]
    ├─ [0] VM::deal(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], 10000000000000000000 [1e19])
    │   └─ ← [Return]
    ├─ [0] VM::deal(user2: [0x537C8f3d3E18dF5517a58B3fB9D9143697996802], 1000000000000000000 [1e18])
    │   └─ ← [Return]
    ├─ [0] VM::startPrank(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF])
    │   └─ ← [Return]
    ├─ [47064] DayTwoVault::deposit{value: 1000000000000000000}()
    │   ├─ emit Deposited(account: user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], amount: 1000000000000000000 [1e18], newBalance: 1000000000000000000 [1e18])
    │   └─ ← [Stop]
    ├─ [11268] DayTwoVault::withdraw(1000000000000000000 [1e18], user2: [0x537C8f3d3E18dF5517a58B3fB9D9143697996802])
    │   ├─ [0] user2::fallback{value: 1000000000000000000}()
    │   │   └─ ← [Stop]
    │   ├─ emit Withdrawn(account: user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], amount: 1000000000000000000 [1e18], remainingBalance: 0)
    │   └─ ← [Stop]
    ├─ [0] VM::expectRevert(custom error 0xf28dceb3: 00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000044cf4791810000000000000000000000000000000000000000000000000de0b6b3a7640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000)
    │   └─ ← [Return]
    ├─ [1378] DayTwoVault::withdraw(1000000000000000000 [1e18], user2: [0x537C8f3d3E18dF5517a58B3fB9D9143697996802])
    │   └─ ← [Revert] InsufficientBalance(1000000000000000000 [1e18], 0)
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return]
    └─ ← [Stop]

[PASS] test_withdraw_with_zero_address_than_revert_invalid_amount() (gas: 68777)
Traces:
  [68777] DayTwoVaultTest::test_withdraw_with_zero_address_than_revert_invalid_amount()
    ├─ [0] VM::addr(<pk>) [staticcall]
    │   └─ ← [Return] user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF]
    ├─ [0] VM::label(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], "user1")
    │   └─ ← [Return]
    ├─ [0] VM::deal(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], 1000000000000000000 [1e18])
    │   └─ ← [Return]
    ├─ [0] VM::startPrank(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF])
    │   └─ ← [Return]
    ├─ [47064] DayTwoVault::deposit{value: 1000000000000000000}()
    │   ├─ emit Deposited(account: user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], amount: 1000000000000000000 [1e18], newBalance: 1000000000000000000 [1e18])
    │   └─ ← [Stop]
    ├─ [0] VM::expectRevert(custom error 0xf28dceb3: 000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000243728b83d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000)
    │   └─ ← [Return]
    ├─ [1446] DayTwoVault::withdraw(1000000000000000000 [1e18], 0x0000000000000000000000000000000000000000)
    │   └─ ← [Revert] InvalidAmount(0)
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return]
    └─ ← [Stop]

[PASS] test_withdraw_with_zero_amount_then_revert_invalid_amount() (gas: 17036)
Traces:
  [17036] DayTwoVaultTest::test_withdraw_with_zero_amount_then_revert_invalid_amount()
    ├─ [0] VM::addr(<pk>) [staticcall]
    │   └─ ← [Return] user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF]
    ├─ [0] VM::label(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], "user1")
    │   └─ ← [Return]
    ├─ [0] VM::addr(<pk>) [staticcall]
    │   └─ ← [Return] user2: [0x537C8f3d3E18dF5517a58B3fB9D9143697996802]
    ├─ [0] VM::label(user2: [0x537C8f3d3E18dF5517a58B3fB9D9143697996802], "user2")
    │   └─ ← [Return]
    ├─ [0] VM::deal(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], 10000000000000000000 [1e19])
    │   └─ ← [Return]
    ├─ [0] VM::deal(user2: [0x537C8f3d3E18dF5517a58B3fB9D9143697996802], 1000000000000000000 [1e18])
    │   └─ ← [Return]
    ├─ [0] VM::startPrank(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF])
    │   └─ ← [Return]
    ├─ [0] VM::expectRevert(custom error 0xf28dceb3: 000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000243728b83d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000)
    │   └─ ← [Return]
    ├─ [971] DayTwoVault::withdraw(0, user2: [0x537C8f3d3E18dF5517a58B3fB9D9143697996802])
    │   └─ ← [Revert] InvalidAmount(0)
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return]
    └─ ← [Stop]

Suite result: ok. 14 passed; 0 failed; 0 skipped; finished in 701.79µs (1.97ms CPU time)

Ran 1 test suite in 83.06ms (701.79µs CPU time): 14 tests passed, 0 failed, 0 skipped (14 total tests)

$ forge test --gas-report
╭------------------------------------------+-----------------+-------+--------+-------+---------╮
| src/DayTwoVault.sol:DayTwoVault Contract |                 |       |        |       |         |
+===============================================================================================+
| Deployment Cost                          | Deployment Size |       |        |       |         |
|------------------------------------------+-----------------+-------+--------+-------+---------|
| 1100824                                  | 6308            |       |        |       |         |
|------------------------------------------+-----------------+-------+--------+-------+---------|
|                                          |                 |       |        |       |         |
|------------------------------------------+-----------------+-------+--------+-------+---------|
| Function Name                            | Min             | Avg   | Median | Max   | # Calls |
|------------------------------------------+-----------------+-------+--------+-------+---------|
| balanceOf                                | 2874            | 2874  | 2874   | 2874  | 4       |
|------------------------------------------+-----------------+-------+--------+-------+---------|
| deposit                                  | 21581           | 55399 | 68128  | 68128 | 10      |
|------------------------------------------+-----------------+-------+--------+-------+---------|
| setGreeting                              | 22218           | 27246 | 27349  | 32069 | 4       |
|------------------------------------------+-----------------+-------+--------+-------+---------|
| totalDeposits                            | 2491            | 2491  | 2491   | 2491  | 1       |
|------------------------------------------+-----------------+-------+--------+-------+---------|
| withdraw                                 | 22519           | 37218 | 30494  | 69988 | 6       |
╰------------------------------------------+-----------------+-------+--------+-------+---------╯
```
- 주요 테스트 케이스 설명 및 느낀 점: 가스 리포트를 보고 가스비 절감된 로직으로 개선해야 하나 연습이 부족해 미진함  

## 4. 셀프 리뷰
- 요구사항 대비 부족하거나 추가 개선이 필요한 부분:
  - 가스 리포트 분석 및 최적화 로직 작성 
- 확장 아이디어 또는 다음 단계:
  - 더 견고한 보안과 가스비 최적화에 대한 트레이드 오프를 고려하는 방법을 알고 싶음 

## 5. 회고
- 오늘 새롭게 이해한 컨셉:
  - 커스텀 에러와 immutable 상수 
- 다음 학습에서 집중하고 싶은 주제:
  - 더 견고한 보안과 가스비 최적화에 대한 트레이드 오프를 고려하는 방법을 알고 싶음
