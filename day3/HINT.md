# Day 3 힌트 모음

## [힌트]
- 출금 요청과 실행을 분리할 때는 **상태를 먼저 업데이트하고** 외부 호출(`call`)을 나중에 실행하는 순서를 고수하세요. 실패 시 데이터를 `delete`한 뒤 revert하면 상태가 원래대로 돌아갑니다.
- `uint64 readyAt = uint64(block.timestamp + minDelay);`와 같이 타입 캐스팅을 명시적으로 해 두면 컴파일러 경고 없이 의도를 드러낼 수 있습니다.
- 테스트에서 `vm.warp`를 호출하기 전에 `uint64 readyAt` 값을 캡처해 두면, 기대값과 실제값을 비교하기 쉬워집니다.
- allowlist 토글 로직은 `if (allowlist[account] == allowed) return;`처럼 중복 이벤트를 방지하는 방식을 적용할 수도 있습니다. 다만 과제에서는 이벤트 발행을 확인해야 하므로 조건 분기를 조심하세요.

## [참고자료]
- Solidity 공식 문서 – [Mappings](https://docs.soliditylang.org/en/latest/types.html#mappings), [Structs](https://docs.soliditylang.org/en/latest/types.html#structs)
- OpenZeppelin Docs – [Reentrancy Guard Patterns](https://docs.openzeppelin.com/contracts/4.x/api/security#ReentrancyGuard)
- Foundry Book – [Cheatcodes: Time](https://book.getfoundry.sh/cheatcodes/time) 및 [Expect Revert](https://book.getfoundry.sh/cheatcodes/expect-revert)
- Trail of Bits 블로그 – [Smart Contract Timelocks Explained](https://blog.trailofbits.com/2020/06/08/timelock-smart-contracts/)

## [참고 키워드]
- time-lock vault
- state machine testing
- optimistic vs pessimistic accounting
- reentrancy safety pattern
- allowlist toggling gas cost
