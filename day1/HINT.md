# Day 1 — 힌트 & 참고자료

## [힌트]
- Foundry 설치는 [install guide](https://book.getfoundry.sh/getting-started/installation) 그대로 따라가면 된다. `foundryup` 실행 후에는 터미널을 다시 열거나 `source ~/.zshrc`로 alias를 적용해 보자.
- `DayOneVault`의 `owner` 검증은 `require(msg.sender == owner, "Not owner");`처럼 간단히 시작하고, 추후 커스텀 에러로 확장할 수 있다.
- 문자열이 비어 있는지 확인하려면 `bytes(_greeting).length > 0` 패턴을 활용한다.
- 테스트에서 다른 지갑을 시뮬레이션하려면 `vm.prank(otherUser)` 혹은 `vm.startPrank`/`vm.stopPrank`를 사용한다.
- `vm.expectEmit`으로 이벤트를 검사할 때는 인덱스 여부(`(bool indexed)`)를 올바르게 설정하고, `emit DayOneVault.Deposited(address(this), 1 ether);`처럼 정확한 값으로 호출해야 한다.

## [참고자료]
- Foundry Book: https://book.getfoundry.sh/
- Solidity 공식 문서(0.8.x): https://docs.soliditylang.org/en/v0.8.21/
- Solidity by Example — Events: https://solidity-by-example.org/events/
- Paradigm CTF Foundry Template: https://github.com/paradigmxyz/paradigm-ctf/tree/master/forge-template

## [참고 키워드]
- `foundryup`
- `forge init`
- `require`, `revert`
- `vm.prank`, `vm.expectEmit`
- `payable`, `msg.value`
