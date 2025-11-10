# Day 4 HINT

## 힌트
- Merkle leaf 생성 시 `abi.encodePacked(index, account, amount)` 순서를 테스트와 컨트랙트에서 동일하게 유지하세요. 하나라도 `abi.encode`로 바뀌면 해시가 달라집니다.
- Claim 비트맵은 `index / 256`, `index % 256`을 이용해 word와 bit를 구합니다. 읽기/쓰기 로직을 별도 내부 함수로 추출하면 테스트에서 직접 호출해 검증하기 쉽습니다.
- Epoch 자금은 토큰 transfer 이전에 감소시키고, `TransferFailed`를 잡기 위해 `try/catch` 대신 bool 리턴을 확인하세요.
- `setMerkleRoot`에서 epoch 증가를 하나의 require로 묶지 말고, 조건별로 명확한 revert 메시지를 커스텀 에러와 함께 제공하면 테스트가 쉬워집니다.
- 테스트에서 머클 proof를 하드코딩하기 어렵다면, 작은 트리(예: 2~3 leaf)만 만들어 중간 노드를 직접 계산하세요.

## 참고자료
1. [OpenZeppelin - MerkleProof.sol](https://docs.openzeppelin.com/contracts/4.x/utilities#merkleproof)
2. [Uniswap Merkle Distributor](https://github.com/Uniswap/merkle-distributor)
3. [Paradigm CTF - Merkle Tree Basics](https://www.paradigm.xyz/2020/08/merkle-tree-tricks)

## 참고 키워드
- `MerkleProof.verify`
- 비트 조작(bitwise OR, shift)
- epoch-based airdrop
- `deal` + `vm.prank`
- fee-on-transfer ERC20 edge case
