# Day 4 — 머클 기반 에어드롭 에스크로 만들기

난이도: HARD

[전날 과제 요약]  
- `DayThreeVault`에 allowlist + timelock 출금 흐름을 설계하고, 대기/실행/취소 상태 전이를 테스트했다.  
- 재진입 안전 패턴과 커스텀 에러 설계를 익혔고, 이벤트/에러를 `vm.expectEmit`·`vm.expectRevert`로 검증했다.

[전날 과제로 얻은 역량]  
- 역할 기반 접근 제어를 온체인 상태와 테스트에 반영할 수 있다.  
- 시간 지연 로직을 `vm.warp`로 시뮬레이션하고, 다단계 상태 기계를 테스트로 보증할 수 있다.  
- 커스텀 에러 인자 검증을 통해 회귀를 조기에 포착하는 습관을 들였다.

[오늘 과제 목표]  
1. 머클 트리를 이용해 대규모 보상 배포를 안전하게 검증하는 패턴을 익힌다.  
2. 비트맵 기반 소비 상태(Claim bitmap)를 저장·검증하고, epoch별 루트 교체 흐름을 구현한다.  
3. 오프체인 데이터(루트/인덱스/금액)를 온체인 컨트랙트와 테스트가 같은 방식으로 해시하도록 TDD를 수행한다.  
4. 이벤트 기반 감사 로그와 재진입/재사용 방지 에러를 추가로 연습한다.

[오늘 과제 설명]
- **프로젝트 구조**: `day4/merkle-airdrop-escrow` Foundry 프로젝트를 새로 만들고, `src/DayFourMerkleEscrow.sol`, `test/DayFourMerkleEscrow.t.sol`을 작성한다.  
- **컨트랙트 요구사항 (`DayFourMerkleEscrow`)**  
  - 상태 변수  
    - `IERC20 public immutable rewardToken;` 지급 토큰.  
    - `address public immutable owner;` 루트/자금 관리 권한.  
    - `uint64 public currentEpoch;` 최신 epoch 번호.  
    - `mapping(uint64 => bytes32) public merkleRoots;` epoch별 머클 루트.  
    - `mapping(uint64 => mapping(uint256 => uint256)) private claimedBitMap;` 인덱스 기반 소비 상태(256개 단위 비트맵).  
    - `mapping(uint64 => uint256) public epochBalances;` epoch별 예치 잔액.  
  - 이벤트  
    - `event EpochFunded(uint64 indexed epoch, uint256 amount, uint256 newBalance);`  
    - `event MerkleRootUpdated(uint64 indexed epoch, bytes32 oldRoot, bytes32 newRoot);`  
    - `event Claimed(uint64 indexed epoch, uint256 indexed index, address account, uint256 amount);`  
    - `event EmergencyWithdrawn(address indexed to, uint256 amount);`  
  - 커스텀 에러  
    - `error NotOwner();`  
    - `error InvalidEpoch(uint64 epoch);` (루트/자금이 없는 epoch)  
    - `error AlreadyClaimed(uint64 epoch, uint256 index);`  
    - `error InvalidProof();`  
    - `error InsufficientEpochBalance(uint64 epoch, uint256 requested, uint256 available);`  
    - `error TransferFailed(address to, uint256 amount);`  
  - 핵심 함수  
    - `constructor(IERC20 token)` : `owner = msg.sender`, `currentEpoch = 0`, `merkleRoots[0] = bytes32(0)`.  
    - `function fundEpoch(uint64 epoch, uint256 amount)` : 오너만 호출, `epoch >= currentEpoch` 검사, `rewardToken.transferFrom`. 성공 시 `epochBalances[epoch] += amount`, 이벤트.  
    - `function setMerkleRoot(uint64 epoch, bytes32 newRoot)` : 오너만, `epoch == currentEpoch + 1` 이면 `currentEpoch` 증가 후 루트 설정, `epoch < currentEpoch`이면 revert `InvalidEpoch`. 이벤트에 이전 루트 포함.  
    - `function isClaimed(uint64 epoch, uint256 index) public view returns (bool)` : 비트맵 검사.  
    - `function _setClaimed(uint64 epoch, uint256 index)` : 내부 함수, 해당 비트를 1로 설정.  
    - `function claim(uint64 epoch, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof)`  
      - epoch 유효성 및 루트 존재 확인.  
      - 이미 청구된 인덱스면 `AlreadyClaimed`.  
      - `keccak256(abi.encodePacked(index, account, amount))` 형태의 leaf를 사용해 `MerkleProof.verify`로 검증.  
      - epoch 잔액 부족 시 `InsufficientEpochBalance`.  
      - `_setClaimed`, `epochBalances[epoch] -= amount`, `rewardToken.transfer(account, amount)` (실패 시 revert).  
      - `Claimed` 이벤트 발행.  
    - `function emergencyWithdraw(address to, uint256 amount)` : 오너만, `rewardToken.transfer(to, amount)` 실패 시 `TransferFailed`.  
  - 보안 고려  
    - 외부 토큰 전송 전 모든 상태 업데이트.  
    - epoch 이동 시 루트 히스토리를 덮어쓰지 않도록 `currentEpoch` 단조 증가.  
    - 비트 연산 시 `unchecked` 사용 여부는 가스와 안전성 모두 고려 (테스트 포함).  

- **테스트 작성 (`test/DayFourMerkleEscrow.t.sol`)**  
  - 최소 7개의 테스트를 작성하고 필수 시나리오 포함:  
    1. Happy path: 루트·자금 세팅 후 올바른 proof로 claim, 잔액 감소·비트표시·이벤트 검증.  
    2. Double claim 방지: 동일 인덱스 두 번째 claim 시 `AlreadyClaimed`.  
    3. 잘못된 proof: leaf 혹은 amount를 바꿔 `InvalidProof` 확인.  
    4. epoch 전환: `setMerkleRoot` 호출 시 `currentEpoch` 증가 및 이전 epoch에 대한 청구 허용 로직.  
    5. epoch 잔액 부족: claim 금액이 `epochBalances` 초과 시 revert.  
    6. `fundEpoch`/`setMerkleRoot` 권한: 비오너 호출 시 `NotOwner`.  
    7. `emergencyWithdraw` 정상 동작 및 잔액 감소/이벤트(직접 작성) 검증.  
  - `vm.expectRevert(abi.encodeWithSelector(...))`, `vm.expectEmit` 활용.  
  - 머클 proof는 Foundry 스크립트 없이 테스트에서 직접 계산하거나, `Test` 계약에 `function _calcProof(...)`로 보조 함수를 만들어도 된다.  
  - `deal(address(token), address(sut), amount)`로 토큰 잔액 초기화, `vm.prank`로 승인 흐름을 구성한다.  

- **빌드와 리포트**  
  - `forge build`, `forge test -vvvv`, `forge test --gas-report`를 모두 실행하고 로그를 `day4/RESULT.md`에 요약한다.  
  - 가스 리포트에는 `fundEpoch`, `setMerkleRoot`, `claim`, `emergencyWithdraw` 평균 가스를 정리한다.  

- **제출 지침**  
  - `day4/RESULT.md`에 체크리스트, 테스트/가스 리포트 요약, 구현 회고, 셀프 리뷰를 작성한다.  
  - 피드백은 `day4/FEEDBACK.md` 템플릿에 기록할 예정이니 구조를 수정하지 말 것.

[이해를 돕기 위한 예시]
```solidity
function _leaf(uint256 index, address account, uint256 amount) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(index, account, amount));
}

function _verify(
    bytes32[] memory proof,
    bytes32 root,
    bytes32 leaf
) internal pure returns (bool) {
    return MerkleProof.verify(proof, root, leaf);
}
```

```solidity
// 비트맵 set/조회 예시
function _setClaimed(mapping(uint256 => uint256) storage bitmap, uint256 index) internal {
    uint256 wordIndex = index / 256;
    uint256 bitIndex = index % 256;
    uint256 mask = 1 << bitIndex;
    bitmap[wordIndex] |= mask;
}
```

```solidity
function test_claim_happy_path() public {
    bytes32[] memory proof = new bytes32[](2);
    proof[0] = keccak256("dummy");
    // ... 루트/leaf 계산 생략

    vm.expectEmit(true, true, true, true);
    emit Claimed(epoch, index, alice, amount);
    vault.claim(epoch, index, alice, amount, proof);
}
```
