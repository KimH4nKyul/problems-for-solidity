// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {DayOneVault} from "../src/DayOneVault.sol";

contract DayOneVaultTest is Test {
    DayOneVault public vault;
    address owner;

    event Deposited(address indexed account, uint256 amount);

    function setUp() public {
        // `makeAddr`로 임의 어드레스를 생성
        owner = makeAddr("owner"); 
        // `prank` 내에서 컨트랙트를 실행하는 어드레스는 `makeAddr`에서 생성된 주소를 사용
        vm.startPrank(owner);        
        string memory greeting = "Hello!";
        vault = new DayOneVault(greeting);
        vm.stopPrank();
    }

    function test_can_emit_deposited_when_deposit() public { 
        address _address = makeAddr("test1");
        vm.deal(_address, 10 ether); // 지정된 주소로 ether 지급 
        vm.startPrank(_address);

        // first event validation
        vm.expectEmit(address(vault));
        emit Deposited(_address, 1 ether);

        vault.deposit{ value: 1 ether }(); 

        uint256 result = vault.getDeposit(_address);
        vm.assertEq(result, 1 ether);

        // second event validation
        vm.expectEmit(address(vault));
        emit Deposited(_address, 1 ether);

        vault.deposit{ value: 1 ether }(); 

        uint256 result2 = vault.getDeposit(_address);
        vm.assertEq(result2, 2 ether);

        vault.deposit{ value: 1 ether }(); 
        vm.stopPrank();
    }

    function test_can_not_deposit_with_zero_ether() public { 
        address _address = makeAddr("test1");
        vm.deal(_address, 10 ether); // 지정된 주소로 ether 지급 
        vm.prank(_address);
        vm.expectRevert();
        vault.deposit{ value: 0 ether }(); // 특정 함수의 msg.value로 사용될 값 지정
    }

    function test_can_deposit() public { 
        address _address = makeAddr("test1");
        vm.deal(_address, 10 ether); // 지정된 주소로 ether 지급 
        vm.prank(_address);
        vault.deposit{ value: 1 ether }(); // 특정 함수의 msg.value로 사용될 값 지정
        // vm.stopPrank();

        uint256 result = vault.getDeposit(_address);
        vm.assertEq(result, 1 ether);
    }

    function test_revert_when_zero_length_greeting() public { 
        vm.prank(owner);
        vm.expectRevert();
        vault.setGreeting("");
    }

    function test_other_can_not_update_new_greeting() public { 
        vm.expectRevert();
        vault.setGreeting("Hi!");
    }

    function test_owner_can_update_new_greeting() public { 
        owner = makeAddr("owner");
        vm.startPrank(owner);
        vault.setGreeting("Hi!");
        string memory result = vault.greeting();
        vm.stopPrank();
        vm.assertEq(result, "Hi!");
    }
}
