// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract DayOneVault { 
    address owner; // deployer address 
    string public greeting;
    mapping(address => uint256) deposits; // 주소별 예치금 

    event Deposited(address indexed account, uint256 amount);

    modifier onlyOwner { 
        require(msg.sender == owner, "Owner must be contract deployer");
        _;
    }

    constructor(string memory _greeting) { 
        owner = msg.sender; // `msg.sender` 는 컨트랙트를 배포한 주소로 자동 설정됨
        greeting = _greeting;
    }
    
    function setGreeting(string calldata _greeting) onlyOwner public {
        require(bytes(_greeting).length > 0, "Greeting greater than zero");
        greeting = _greeting;   
    }

    function deposit() payable public { 
        require(msg.value != 0, "Token greater than zero");
        deposits[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function getDeposit(address _address) view public returns(uint256) { 
        return deposits[_address];
    }
}