# Day 2 — 커스텀 에러와 출금 로직이 있는 금고 만들기

난이도: EASY

[전날 과제 요약]  
- Foundry 개발 환경을 설치하고 `DayOneVault` 컨트랙트 및 기본 테스트를 완성했다.  
- 입금 이벤트 로깅, 접근 제어, 입력 검증을 학습했다.  

[전날 과제로 얻은 역량]  
- Foundry 프로젝트 초기화, 빌드, 테스트 워크플로에 익숙해졌다.  
- 간단한 상태 변수 읽기/쓰기를 구현하고 이벤트를 활용해 온체인 로그를 남길 수 있다.  
- `vm.expectEmit`, `vm.expectRevert` 등 핵심 Foundry 치트코드를 활용해 단위 테스트 신뢰도를 높였다.  

[오늘 과제 목표]  
1. 커스텀 에러와 `immutable` 변수를 활용한 효율적인 검증 패턴을 익힌다.  
2. 입·출금 로직을 모두 포함한 금고 컨트랙트를 작성하고 상태 값을 정확히 추적한다.  
3. 정상·비정상 시나리오를 망라한 단위 테스트를 작성하고, 이벤트 파라미터 검증으로 회귀를 방지한다.  

[오늘 과제 설명]  
- **프로젝트 구조**: `day1/foundry-playground` 프로젝트를 그대로 사용한다. `src/DayTwoVault.sol`과 `test/DayTwoVault.t.sol`을 새로 만든다. 기존 Day 1 산출물은 수정하지 않는다.  
- **컨트랙트 구현 요구사항 (`DayTwoVault`)**  
  - 상태 변수  
    - `address public immutable owner;` 배포자를 저장한다.  
    - `uint256 public immutable minDeposit;` 최소 입금 단위를 설정한다.  
    - `mapping(address => uint256) private balances;` 주소별 예치 잔액을 기록한다.  
    - `uint256 public totalDeposits;` 전체 예치액을 추적한다.  
    - `string private greeting;` 기본 인사말을 저장하고 필요 시 외부에서 조회 가능한 `function getGreeting()`을 제공한다.  
  - 이벤트  
    - `event Deposited(address indexed account, uint256 amount, uint256 newBalance);`  
    - `event Withdrawn(address indexed account, uint256 amount, uint256 remainingBalance);`  
    - `event GreetingChanged(address indexed changer, string previousGreeting, string newGreeting);`  
  - 커스텀 에러  
    - `error NotOwner();`  
    - `error InvalidAmount(uint256 amount);`  
    - `error DepositTooSmall(uint256 sent, uint256 minimum);`  
    - `error InsufficientBalance(uint256 requested, uint256 available);`  
  - 함수  
    - `constructor(string memory _greeting, uint256 _minDeposit)`  
      - `_minDeposit`이 0이면 `InvalidAmount(0)`로 revert한다.  
      - `owner`, `greeting`, `minDeposit`을 설정하고 `totalDeposits`는 0으로 시작한다.  
    - `function setGreeting(string calldata _greeting) external`  
      - `msg.sender`가 `owner`가 아니면 `NotOwner()`로 revert.  
      - 빈 문자열이면 `InvalidAmount(0)`로 revert.  
      - 변경 전 인사말을 이벤트에 포함한다.  
    - `function deposit() external payable`  
      - `msg.value == 0`이면 `InvalidAmount(0)`로 revert.  
      - `msg.value < minDeposit`이면 `DepositTooSmall(msg.value, minDeposit)`.  
      - `balances[msg.sender]`와 `totalDeposits`를 `msg.value`만큼 증가시키고 `Deposited` 이벤트를 발생시킨다.  
    - `function withdraw(uint256 amount, address payable recipient) external`  
      - `amount == 0`이면 `InvalidAmount(0)`.  
      - 호출자의 잔액이 부족하면 `InsufficientBalance(amount, balances[msg.sender])`.  
      - 출금 후 `balances[msg.sender]`와 `totalDeposits`를 감소시키고, `recipient`에게 송금하며 `Withdrawn` 이벤트를 기록한다.  
      - `recipient`는 호출자 자신이 아니어도 되지만, 주소가 `address(0)`이면 `InvalidAmount(0)`로 revert한다.  
    - `function balanceOf(address account) external view returns (uint256)`로 외부에서 잔액을 조회할 수 있어야 한다.  
- **테스트 작성 (`test/DayTwoVault.t.sol`)**  
  - 최소 5개의 테스트 함수를 작성한다. 다음 시나리오를 반드시 포함한다.  
    - Happy path: 최소 입금 이상으로 두 번 입금 후 `totalDeposits`와 이벤트 파라미터를 확인한다.  
    - 출금 성공: 입금 후 부분 출금 → 잔액 감소와 이벤트 파라미터, 최종 잔액을 검증한다.  
    - 출금 실패: 잔액보다 큰 금액을 요청하면 `InsufficientBalance`가 발생하는지 확인한다.  
    - 권한 제어: `setGreeting`이 오직 `owner`만 호출 가능함을 `NotOwner()`로 검증한다.  
    - 최소 입금 검증: 0 ETH 또는 `minDeposit` 미만을 입금할 때 각각 `InvalidAmount` 또는 `DepositTooSmall`이 발생하는지 확인한다.  
  - 각 테스트에서 `vm.expectRevert`로 커스텀 에러 셀렉터와 인코딩된 인자를 명시적으로 검증한다.  
  - 이벤트 테스트에서는 `vm.expectEmit`을 사용해 `amount`, `newBalance`(또는 `remainingBalance`)가 기대값과 일치하는지 확인한다.  
- **빌드와 리포트**  
  - `forge build`, `forge test -vvvv`, `forge test --gas-report`를 모두 실행한다.  
  - `forge test --gas-report` 결과에서 `deposit`, `withdraw`, `setGreeting` 세 함수의 평균 가스 사용량을 `day2/RESULT.md`에 요약한다.  
- **제출 지침**  
  - Day 2 과제 제출 시 `day2/RESULT.md`에 체크리스트, 실행 로그 요약, 셀프 리뷰, 회고를 정리한다.  
  - 피드백은 `day2/FEEDBACK.md`에 적을 예정이므로 템플릿을 수정하지 말고 비워 둔다.  

[이해를 돕기 위한 예시]  
```solidity
// 커스텀 에러와 이벤트 파라미터 검증 패턴 예시
pragma solidity ^0.8.20;

error InvalidAmount(uint256 amount);

contract Example {
    event ValueChanged(uint256 previousValue, uint256 newValue);
    uint256 private value;

    function setValue(uint256 newValue) external {
        if (newValue == 0) revert InvalidAmount(newValue);
        uint256 previous = value;
        value = newValue;
        emit ValueChanged(previous, newValue);
    }
}

// Foundry 테스트에서 커스텀 에러와 이벤트 검증
// vm.expectRevert(abi.encodeWithSelector(InvalidAmount.selector, 0));
// vm.expectEmit();
// emit ValueChanged(1, 2);
```
커스텀 에러는 revert 문자열보다 가스 비용이 낮고, 테스트에서는 셀렉터와 인자를 정확히 지정해 회귀 버그를 빠르게 찾을 수 있다.
