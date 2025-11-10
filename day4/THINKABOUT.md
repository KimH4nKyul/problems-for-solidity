# Day 4 THINKABOUT

## 메타인지 체크
1. 머클 루트가 바뀌었는데 epoch 번호를 잘못 증가시키면 어떤 사용자가 보상을 두 번 받게 될까요?
2. `claimedBitMap`에서 word/bit 계산이 잘못되면 어떤 경계 케이스에서 실패가 드러나는지 스스로 재현할 수 있나요?
3. Epoch별 예치 잔액이 `claim` 실행 중에 줄어들 때, 토큰 전송 이전에 반드시 확인해야 하는 불변식은 무엇인가요?

## 직접 리서치해 볼 문제
1. Optimism/Arbitrum에서 사용하는 다중 루트 에어드롭 설계를 조사하고, 당신의 설계와 비교해 어떤 추가 안전장치가 있는지 정리하세요.
2. Merkle proof를 off-chain에서 생성할 때 흔히 발생하는 직렬화 실수(endianness, `abi.encodePacked` vs `abi.encode`)를 사례와 함께 조사하세요.
3. ERC20 토큰이 수수료형(fee-on-transfer)일 때 현재 설계가 깨지는 지점을 찾아보고, 이를 완화할 수 있는 컨트랙트/테스트 개선 아이디어를 적어보세요.
