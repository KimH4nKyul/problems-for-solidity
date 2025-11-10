# Day 3 결과 제출서

## 1. 과제 수행 체크리스트
- [x] `DayThreeVault` 컨트랙트 구현 (상태 변수, 이벤트, 커스텀 에러, 함수 요구사항 충족)
- [x] allowlist 및 타임락 로직 단위 테스트 6개 이상 작성
- [x] `vm.expectRevert`와 `vm.expectEmit`으로 필수 시나리오 검증
- [x] `forge build`, `forge test -vvvv`, `forge test --gas-report` 실행
- [x] 가스 리포트에서 `deposit`, `requestWithdrawal`, `executeWithdrawal`, `cancelWithdrawal` 평균 가스를 정리

## 2. 구현 요약
- 접근 제어와 타임 락을 이용해 안전한 출금 로직 설계
- 출금 요청과 실행을 분리해 재진입 공격 및 실수 방지 패턴 적용 

## 3. 테스트 로그 요약
```
> FOUNDRY_DISABLE_VERSION_CHECK=1 forge test --offline                                                                                    ok 
[⠊] Compiling...
No files changed, compilation skipped

Ran 8 tests for test/DayThreeVault.t.sol:DayThreeVaultTest
[PASS] test_cancel_withdrawal() (gas: 97427)
[PASS] test_duplicate_withdrawal_request_then_revert_pending_withdrawal_exists() (gas: 124367)
[PASS] test_execute_withdrawal_before_delay_then_revert_withdrawal_not_ready() (gas: 135780)
[PASS] test_execute_withdrawal_greater_than_balance_then_revert_insufficient_balance() (gas: 127529)
[PASS] test_happy_path() (gas: 144553)
[PASS] test_owner_set_allowlist_then_user_cannot_deposit() (gas: 23735)
[PASS] test_request_withdrawal_greater_than_balance_then_revert_insufficient_balance() (gas: 73601)
[PASS] test_user_try_set_allowlist_then_revert_not_owner() (gas: 14824)
Suite result: ok. 8 passed; 0 failed; 0 skipped; finished in 873.46µs (2.05ms CPU time)

Ran 1 test suite in 1.82ms (873.46µs CPU time): 8 tests passed, 0 failed, 0 skipped (8 total tests)
```

## 4. 가스 리포트 요약
```
╭----------------------------------------------+-----------------+-------+--------+-------+---------╮
| src/DayThreeVault.sol:DayThreeVault Contract |                 |       |        |       |         |
+===================================================================================================+
| Deployment Cost                              | Deployment Size |       |        |       |         |
|----------------------------------------------+-----------------+-------+--------+-------+---------|
| 1412560                                      | 7571            |       |        |       |         |
|----------------------------------------------+-----------------+-------+--------+-------+---------|
|                                              |                 |       |        |       |         |
|----------------------------------------------+-----------------+-------+--------+-------+---------|
| Function Name                                | Min             | Avg   | Median | Max   | # Calls |
|----------------------------------------------+-----------------+-------+--------+-------+---------|
| balanceOf                                    | 2896            | 2896  | 2896   | 2896  | 2       |
|----------------------------------------------+-----------------+-------+--------+-------+---------|
| cancelWithdrawal                             | 26868           | 26868 | 26868  | 26868 | 1       |
|----------------------------------------------+-----------------+-------+--------+-------+---------|
| deposit                                      | 23759           | 57648 | 70435  | 70435 | 9       |
|----------------------------------------------+-----------------+-------+--------+-------+---------|
| executeWithdrawal                            | 26335           | 41643 | 28554  | 70042 | 3       |
|----------------------------------------------+-----------------+-------+--------+-------+---------|
| minDelay                                     | 397             | 397   | 397    | 397   | 1       |
|----------------------------------------------+-----------------+-------+--------+-------+---------|
| requestWithdrawal                            | 27111           | 62226 | 75859  | 75859 | 7       |
|----------------------------------------------+-----------------+-------+--------+-------+---------|
| setAllowlist                                 | 22400           | 23309 | 23309  | 24219 | 2       |
|----------------------------------------------+-----------------+-------+--------+-------+---------|
| totalDeposits                                | 2513            | 2513  | 2513   | 2513  | 2       |
╰----------------------------------------------+-----------------+-------+--------+-------+---------╯
```
