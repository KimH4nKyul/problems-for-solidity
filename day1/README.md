# Day 1 — Solidity 개발 환경 준비와 첫 컨트랙트

난이도: EASY

[전날 과제 요약]  
- 첫날 과제이므로 해당 없음.

[전날 과제로 얻은 역량]  
- 첫날 과제이므로 해당 없음.

[오늘 과제 목표]  
1. Foundry 개발 환경을 설치하고 기본 명령어에 익숙해진다.  
2. 간단한 상태 변수 읽기·쓰기가 가능한 Solidity 컨트랙트를 작성한다.  
3. Foundry의 단위 테스트를 통해 컨트랙트 동작을 검증한다.  
4. 기본적인 가스 리포트와 ABI 산출물을 살펴보며 결과를 이해한다.

[오늘 과제 설명]  
- **Foundry 설치**: `foundryup` 스크립트를 사용해 Foundry를 설치하고 `forge --version`, `cast --version`으로 정상 설치 여부를 확인한다.  
- **프로젝트 생성**: 프로젝트 루트(`problems-for-solidity/day1`)에서 `foundryup` 설치 후 `forge init foundry-playground`를 실행해 샘플 프로젝트를 생성한다.  
  - `src/DayOne.sol`이라는 새 컨트랙트 파일을 만들고, 샘플로 제공된 `Counter.sol` 대신 오늘 과제 요구사항을 구현한다.  
  - `script/`, `test/` 디렉터리 구조를 검토하고, 필요 없는 템플릿 파일은 유지해도 무방하다.  
- **컨트랙트 구현 요구사항**:  
  - 컨트랙트 이름은 `DayOneVault`로 한다.  
  - 상태 변수  
    - `owner`: 배포자 주소 저장 (변경 불가).  
    - `greeting`: 문자열 인사말 저장.  
    - `deposits`: 주소별 입금 총액을 추적하는 `mapping(address => uint256)`.  
  - 함수  
    - `constructor(string memory _greeting)`는 배포 시 `owner`와 초기 인사말을 설정한다.  
    - `setGreeting(string calldata _greeting)`은 오직 `owner`만 호출할 수 있고, 새로운 인사말을 설정한다.  
    - `deposit()`는 `payable` 함수로, 호출자의 `deposits[msg.sender]`를 `msg.value`만큼 증가시키고 `deposit` 이벤트를 발생시킨다.  
    - `getDeposit(address _account)`는 해당 주소의 누적 입금액을 반환한다.  
  - 이벤트  
    - `event Deposited(address indexed account, uint256 amount);`  
  - `setGreeting`은 빈 문자열이 들어오면 revert해야 한다.  
  - `deposit` 호출 시 `msg.value == 0`이면 revert한다.  
- **테스트 작성**:  
  - `test/DayOneVault.t.sol` 파일을 생성한다.  
  - `setUp()`에서 `DayOneVault`를 배포하고 기본 인사말을 설정한다.  
  - 최소 세 가지 시나리오 테스트를 작성한다. 예:  
    - 인사말을 변경하려는 경우 `owner`일 때만 성공하고, 다른 주소는 revert.  
    - `deposit` 이벤트와 입금액 누적 동작 검증.  
    - `deposit`에 0 ETH를 보낼 시 revert.  
  - 이벤트 검사에는 `vm.expectEmit`을 활용해 본다.  
- **빌드와 리포트**:  
  - `forge build`를 실행하여 성공 여부를 확인한다.  
  - `forge test -vvvv`로 테스트 로그를 확인하고, 테스트 출력 중 revert 사유가 잘 드러나도록 한다.  
  - `forge test --gas-report`를 실행해 가스 리포트를 출력하고, `RESULT.md`에 주요 수치를 요약한다.  
- **제출 지침**:  
  - 코드와 테스트는 모두 `day1/foundry-playground` 디렉터리에 커밋한다고 가정한다.  
  - 오늘 과제를 마친 후 루트의 `day1/RESULT.md`에 요구된 정보를 정리해 제출한다.

[이해를 돕기 위한 예시]  
```solidity
// 예시: 이벤트와 권한 제어를 포함한 간단한 패턴
pragma solidity ^0.8.20;

contract Greeter {
    address public owner;
    string private greeting;

    event GreetingChanged(address indexed changer, string newGreeting);

    constructor(string memory _greeting) {
        owner = msg.sender;
        greeting = _greeting;
    }

    function setGreeting(string calldata _greeting) external {
        require(msg.sender == owner, "Only owner");
        require(bytes(_greeting).length > 0, "Empty greeting");
        greeting = _greeting;
        emit GreetingChanged(msg.sender, _greeting);
    }

    function greet() external view returns (string memory) {
        return greeting;
    }
}
```
위 예시는 `require`, 이벤트 기록, 접근 제어 패턴을 어떻게 구성하는지 보여준다. `DayOneVault` 구현 시에도 비슷한 형태로 권한과 입력 검증, 이벤트 발행을 적용해 본다.
