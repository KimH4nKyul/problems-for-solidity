// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract DayTwoVault {
    address public immutable owner; // deployer address
    uint256 public immutable minDeposit; // 최소 입금 단위 (wei, 1e18 = 1 ether)
    uint256 public totalDeposits; // 전체 예치액 추적
    mapping(address => uint256) private balances; // 주소별 예치금
    string private greeting;

    event Deposited(address indexed account, uint256 amount, uint256 newBalance);
    event Withdrawn(address indexed account, uint256 amount, uint256 remainingBalance);
    event GreetingChanged(address indexed changer, string prevGreeting, string newGreeting);

    error NotOwner();
    error InvalidAmount(uint256 amount);
    error DepositTooSmall(uint256 sent, uint256 minimum);
    error InsufficientBalance(uint256 requested, uint256 available);
    error TransferFailed(address recipient, uint256 amount);

    function _notZeroValue(uint256 _value) internal pure {
        if (0 == _value) revert InvalidAmount(0);
    }

    modifier notZeroValue(uint256 _value) {
        _notZeroValue(_value);
        _;
    }

    function _onlyOwner() internal view {
        if (owner != msg.sender) {
            revert NotOwner();
        }
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    // 인삿말과 최소 입금 단위를 런타임에 결정한다.
    constructor(string memory _greeting, uint256 _minDeposit) {
        // _minDeposit이 0이면 트랜잭션을 취소한다.
        if (_minDeposit == 0) {
            revert InvalidAmount(0);
        }
        owner = msg.sender;
        greeting = _greeting;
        minDeposit = _minDeposit;
        totalDeposits = 0;
    }

    function setGreeting(string calldata _greeting) onlyOwner external {
        if (bytes(_greeting).length <= 0) revert InvalidAmount(0);
        string memory prevGreeting = greeting;
        greeting = _greeting;
        emit GreetingChanged(msg.sender, prevGreeting, greeting);
    }

    function deposit() notZeroValue(msg.value) payable external {
        if (msg.value < minDeposit) revert DepositTooSmall(msg.value, minDeposit);

        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value, balances[msg.sender]);
    }

    function withdraw(uint256 amount, address payable recipient) notZeroValue(amount) external {
        if (balances[msg.sender] <= 0 || amount > balances[msg.sender])
            revert InsufficientBalance(amount, balances[msg.sender]);
        if (recipient == address(0)) revert InvalidAmount(0);

        // 출금 가능하다면 잔액과 전체 잔금을 감소시키고
        balances[msg.sender] -= amount;
        totalDeposits -= amount;
        // recipient 에게 송금하고
        (bool success, ) = recipient.call{ value: amount }("");
        // Withdrawn 이벤트를 발행
        if (!success) revert TransferFailed(recipient, amount);
        emit Withdrawn(msg.sender, amount, balances[msg.sender]);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function getGreeting() external view returns (string memory) {
        return greeting;
    }
}