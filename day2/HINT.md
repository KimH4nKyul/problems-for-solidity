# Day 2 — HINT

## 힌트
- 커스텀 에러는 `error Name(Type param);` 형태로 선언하고 `revert Name(args);`로 사용하면 된다. 테스트에서는 `abi.encodeWithSelector(Name.selector, args…)`로 인코딩한 값을 `vm.expectRevert`에 전달한다.
- `vm.expectEmit`은 기본적으로 모든 인덱스 필드를 체크하지 않으므로, 필요한 필드를 명시적으로 지정하려면 `vm.expectEmit(address, topics, data, dataCheck);` 시그니처를 사용하거나 `emit` 직전까지 `vm.expectEmit()`을 호출한 뒤 이벤트를 발생시킨다.
- 출금 시에는 외부 송금이 실패할 가능성을 고려해 `recipient.call{value: amount}("")` 패턴을 사용하고, 성공 여부를 반드시 확인하라.
- `totalDeposits`는 입금·출금 로직 모두에서 업데이트되어야 하며, underflow가 발생하지 않도록 순서를 주의하라. Solidity 0.8 이후에는 기본적으로 underflow 시 revert되지만, 테스트로 미리 감지하는 것이 중요하다.
- 최소 입금 금액 검증은 `minDeposit`보다 작은 값을 넣었을 때와 0 ETH를 넣었을 때 서로 다른 에러가 발생해야 한다. 단위 테스트에서 이 두 케이스를 분리해 검증하라.

## 참고자료
- Foundry Book — Cheatcodes: <https://book.getfoundry.sh/cheatcodes/>
- Solidity 공식 문서 — Errors and Exceptions: <https://docs.soliditylang.org/en/latest/control-structures.html#errors-and-the-revert-statement>
- Solidity 공식 문서 — Sending and Receiving Ether: <https://docs.soliditylang.org/en/latest/security-considerations.html#sending-and-receiving-ether>
- OpenZeppelin 블로그 — Reentrancy After Istanbul: <https://blog.openzeppelin.com/reentrancy-after-istanbul/>
- Smart Contract Best Practices — Reentrancy: <https://consensys.github.io/smart-contract-best-practices/known_attacks/#reentrancy>

## 참고 키워드
- `custom error`, `immutable`
- `vm.expectRevert`, `abi.encodeWithSelector`
- `call` vs `transfer`
- `totalDeposits`, `state accounting`
- `event parameter testing`
