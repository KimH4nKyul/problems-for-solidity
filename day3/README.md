# Day 3 — 시간 지연 출금과 역할 기반 금고 확장하기

난이도: MEDIUM

[전날 과제 요약]  
- `DayTwoVault`에서 커스텀 에러와 시간에 민감하지 않은 출금 로직을 구현하고 이벤트 기반 상태 추적을 검증했다.  
- `vm.expectEmit`, `vm.expectRevert`, `abi.encodeWithSelector`로 정상/비정상 흐름의 단위 테스트를 완성했다.  
- `forge test --gas-report`로 핵심 함수의 가스 소모를 비교했다.  

[전날 과제로 얻은 역량]  
- 입·출금 불변식을 정의하고 커스텀 에러로 입력 검증을 구조화할 수 있다.  
- 송금 성공/실패를 분리 처리해 잔액이 잘못 줄어드는 사태를 방지할 수 있다.  
- 이벤트 파라미터까지 검증하는 테스트 습관을 통해 회귀를 조기에 포착할 수 있다.  

[오늘 과제 목표]  
1. 역할 기반 접근 제어(allowlist)와 시간 지연(time-lock) 출금 흐름을 설계한다.  
2. 출금 요청과 실행을 분리해 재진입 공격과 사용자 실수를 동시에 방지하는 패턴을 익힌다.  
3. 시간 흐름(`vm.warp`)과 상태머신 기반 테스트를 작성해 다단계 로직을 검증한다.  

[오늘 과제 설명]  
- **프로젝트 구조**: `src/DayThreeVault.sol`과 `test/DayThreeVault.t.sol`을 새로 생성한다.   
- **컨트랙트 구현 요구사항 (`DayThreeVault`)**  
  - 상태 변수  
    - `address public immutable owner;` 컨트랙트 소유자.  
    - `uint256 public immutable minDeposit;` allowlist 사용자가 예치할 최소 금액(wei).  
    - `uint64 public immutable minDelay;` 출금 요청 후 기다려야 하는 최소 시간(초).  
    - `mapping(address => bool) public allowlist;` 예치 및 출금 요청 가능 여부.  
    - `mapping(address => uint256) private balances;` 사용자별 예치 잔액.  
    - `uint256 public totalDeposits;` 전체 예치액.  
    - `struct WithdrawalRequest { uint256 amount; uint64 readyAt; address recipient; }`  
    - `mapping(address => WithdrawalRequest) private pendingWithdrawals;` 각 사용자의 보류 중 출금 요청.  
  - 이벤트  
    - `event AllowlistUpdated(address indexed account, bool allowed);`  
    - `event Deposited(address indexed account, uint256 amount, uint256 newBalance);`  
    - `event WithdrawalRequested(address indexed account, uint256 amount, address recipient, uint64 readyAt);`  
    - `event WithdrawalExecuted(address indexed account, uint256 amount, address recipient);`  
    - `event WithdrawalCancelled(address indexed account, uint256 amount);`  
  - 커스텀 에러  
    - `error NotOwner();`  
    - `error NotAllowlisted(address account);`  
    - `error InvalidAmount(uint256 amount);`  
    - `error DepositTooSmall(uint256 sent, uint256 minimum);`  
    - `error InsufficientBalance(uint256 requested, uint256 available);`  
    - `error PendingWithdrawalExists();`  
    - `error NoPendingWithdrawal();`  
    - `error WithdrawalNotReady(uint64 readyAt, uint64 currentTime);`  
    - `error InvalidRecipient(address recipient);`  
    - `error TransferFailed(address recipient, uint256 amount);`  
  - 함수  
    - `constructor(uint256 _minDeposit, uint64 _minDelay, address[] memory initialAllowlist)`  
      - `_minDeposit == 0` 또는 `_minDelay == 0`이면 `InvalidAmount(0)`으로 revert.  
      - `owner`, `minDeposit`, `minDelay`를 설정하고 `totalDeposits`는 0으로 시작한다.  
      - `initialAllowlist`에 포함된 주소를 모두 허용하며 `AllowlistUpdated` 이벤트를 발행한다.  
    - `function setAllowlist(address account, bool allowed) external`  
      - 오직 `owner`만 호출 가능하며, 상태 변경 시마다 `AllowlistUpdated(account, allowed)` 이벤트를 기록한다.  
    - `function deposit() external payable`  
      - `allowlist[msg.sender]`가 아니면 `NotAllowlisted(msg.sender)`.  
      - `msg.value == 0`이면 `InvalidAmount(0)`, `msg.value < minDeposit`이면 `DepositTooSmall`.  
      - 잔액과 `totalDeposits`를 갱신하고 `Deposited` 이벤트를 발생시킨다.  
    - `function requestWithdrawal(uint256 amount, address payable recipient) external`  
      - 호출자가 allowlist인지 확인하고 `recipient != address(0)`인지 검사한다.  
      - `amount == 0`이면 `InvalidAmount(0)`이고, 잔액이 부족하면 `InsufficientBalance(amount, balances[msg.sender])`.  
      - 기존 보류 요청이 있다면 `PendingWithdrawalExists()`.  
      - `readyAt = uint64(block.timestamp + minDelay)`로 설정해 `pendingWithdrawals[msg.sender]`에 저장 후 `WithdrawalRequested` 이벤트를 발행한다.  
    - `function cancelWithdrawal()`  
      - 대기 중인 출금이 없으면 `NoPendingWithdrawal()`.  
      - 보류 중 금액을 이벤트로 기록하고 `pendingWithdrawals[msg.sender]`를 삭제한다.  
    - `function executeWithdrawal()`  
      - 보류 중 요청이 없으면 `NoPendingWithdrawal()`.  
      - `block.timestamp < readyAt`이면 `WithdrawalNotReady(readyAt, uint64(block.timestamp))`.  
      - 출금 금액보다 잔액이 적으면 `InsufficientBalance`.  
      - 요청 정보를 먼저 삭제하고 잔액 및 `totalDeposits`를 감소시킨 뒤, 기록된 `recipient`에게 `call`로 송금한다. 실패하면 `TransferFailed`.  
      - 성공 시 `WithdrawalExecuted` 이벤트를 발행한다. (allowlist에서 제외되었더라도 사용자는 자신의 자금을 회수할 수 있어야 한다.)  
    - `function balanceOf(address account) external view returns (uint256)`  
    - `function getPendingWithdrawal(address account) external view returns (WithdrawalRequest memory)`  
  - 보안/가스 고려 사항  
    - 외부 호출 전에 상태를 먼저 업데이트해 재진입 공격을 차단한다.  
    - `uint64`로 지연 시간을 저장할 때 오버플로가 없도록 타입 변환을 명시적으로 수행한다.  
    - allowlist가 변경되어도 기존 요청을 안전하게 처리할 수 있도록 설계한다.  
- **테스트 작성 (`test/DayThreeVault.t.sol`)**  
  - 최소 6개의 테스트 함수를 작성한다. 아래 시나리오를 반드시 포함한다.  
    - Happy path: allowlist 사용자가 두 번 입금 후 출금 요청 → `vm.warp`로 지연 시간을 건너뛰고 `executeWithdrawal`이 잔액/이벤트를 정확히 갱신하는지 확인.  
    - 출금 요청 중복: 대기 중 요청이 있는 상태에서 다시 요청하면 `PendingWithdrawalExists`로 revert.  
    - 지연 시간 미도달: `executeWithdrawal`을 지연 시간 이전에 호출하면 `WithdrawalNotReady` revert.  
    - allowlist 제어: 비오너가 `setAllowlist` 호출 시 `NotOwner()`로 revert하고, allowlist가 해제된 사용자는 입금이 불가함을 검증.  
    - 취소 플로우: 요청 후 `cancelWithdrawal`이 대기 중 금액을 삭제하고 `WithdrawalCancelled` 이벤트를 남기는지 확인.  
    - 잔액 부족: 잔액보다 큰 금액을 요청하거나 실행 시 `InsufficientBalance`가 발생하는지 확인.  
  - 각 테스트는 `vm.expectRevert(abi.encodeWithSelector(...))`로 커스텀 에러 인자를 검증하고, 이벤트 검증에는 `vm.expectEmit`을 사용한다.  
  - 시간 이동은 `vm.warp`로 수행하고, `block.timestamp`를 직접 조작하는 대신 테스트로만 제어한다.  
- **빌드와 리포트**  
  - `forge build`, `forge test -vvvv`, `forge test --gas-report`를 모두 실행한다.  
  - 가스 리포트에서 `deposit`, `requestWithdrawal`, `executeWithdrawal`, `cancelWithdrawal` 네 함수의 평균 가스 사용량을 `day3/RESULT.md`에 정리한다.  
- **제출 지침**  
  - `day3/RESULT.md`에 체크리스트, 테스트/가스 리포트 요약, 구현 회고, 셀프 리뷰를 작성한다.  
  - 피드백은 `day3/FEEDBACK.md`에 기록할 예정이므로 템플릿을 수정하지 않는다.  

[이해를 돕기 위한 예시]  
```solidity
pragma solidity ^0.8.20;

contract TimelockSketch {
    struct WithdrawalRequest { uint256 amount; uint64 readyAt; address recipient; }
    mapping(address => WithdrawalRequest) public requests;

    function _schedule(uint256 amount, address recipient, uint64 delay) internal {
        if (amount == 0) revert("amount=0");
        if (recipient == address(0)) revert("zero recipient");
        requests[msg.sender] = WithdrawalRequest({
            amount: amount,
            readyAt: uint64(block.timestamp + delay),
            recipient: recipient
        });
    }
}
```

```solidity
// Foundry 테스트에서 시간 이동 예시
function test_timelock_flow() public {
    vm.startPrank(user);
    vault.deposit{value: 3 ether}();
    vault.requestWithdrawal(2 ether, payable(user));

    vm.expectRevert();
    vault.executeWithdrawal(); // 아직 readyAt 이전

    vm.warp(block.timestamp + vault.minDelay());
    vm.expectEmit(true, true, false, true);
    emit WithdrawalExecuted(user, 2 ether, user);
    vault.executeWithdrawal();

    vm.stopPrank();
}
```
시간 지연 패턴은 `request → 대기 → execute`의 상태 전이를 수반하므로, 테스트에서도 동일한 순서를 밟으면서 이벤트와 잔액을 검증해야 한다.
