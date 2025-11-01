// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract DayThreeVault {
    address public immutable owner; // deployer address
    uint256 public immutable minDeposit; // 최소 입금 단위 (wei, 1e18 = 1 ether)
    uint256 public totalDeposits; // 전체 예치액 추적
    mapping(address => uint256) private balances; // 주소별 예치금

    // 새로 추가되는 것
    uint64 public immutable minDelay;
    mapping(address => bool) public allowlist;

    struct WithdrawalRequest {
        uint256 amount;
        uint64 readyAt;
        address recipient;
    }
    mapping(address => WithdrawalRequest) private pendingWithdrawals; // 사용자별 보류 중 출금 요청

    event Deposited(address indexed account, uint256 amount, uint256 newBalance);
    event Withdrawn(address indexed account, uint256 amount, uint256 remainingBalance);

    // 새로 추가된 이벤트
    event AllowlistUpdated(address indexed account, bool allowed);
    event WithdrawalRequested(address indexed account, uint256 amount, address recipient, uint64 readyAt);
    event WithdrawalExecuted(address indexed account, uint256 amount, address recipient);
    event WithdrawalCancelled(address indexed account, uint256 amount);

    error NotOwner();
    error InvalidAmount(uint256 amount);
    error DepositTooSmall(uint256 sent, uint256 minimum);
    error InsufficientBalance(uint256 requested, uint256 available);
    error TransferFailed(address recipient, uint256 amount);

    // 새로 추가된 에러
    error NotAllowlisted(address account);
    error PendingWithdrawalExists();
    error NoPendingWithdrawal();
    error WithdrawalNotReady(uint64 readyAt, uint64 currentTime);
    error InvalidRecipient(address recipient);

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

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _notAllowed() internal view {
        if (!allowlist[msg.sender]) revert NotAllowlisted(msg.sender);
    }

    modifier notAllowed() {
        _notAllowed();
        _;
    }

    constructor(uint256 _minDeposit, uint64 _minDelay, address[] memory initialAllowlist) {
        // _minDeposit이 0이면 트랜잭션을 취소한다.
        if (_minDeposit == 0 || _minDelay == 0) {
            revert InvalidAmount(0);
        }
        owner = msg.sender;
        minDeposit = _minDeposit;
        minDelay = _minDelay;
        totalDeposits = 0;

        for (uint256 i = 0; i < initialAllowlist.length; i++) {
            allowlist[initialAllowlist[i]] = true;
            emit AllowlistUpdated(initialAllowlist[i], true);
        }
    }

    function setAllowlist(address account, bool allowed) external onlyOwner {
        allowlist[account] = allowed;
        emit AllowlistUpdated(account, allowed);
    }

    function deposit() external payable notAllowed notZeroValue(msg.value) {
        if (msg.value < minDeposit) revert DepositTooSmall(msg.value, minDeposit);

        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value, balances[msg.sender]);
    }

    function requestWithdrawal(uint256 amount, address payable recipient) external notAllowed notZeroValue(amount) {
        if (recipient == address(0)) revert InvalidRecipient(recipient);

        uint256 balance = balances[msg.sender];
        if (balance < amount) revert InsufficientBalance(amount, balance);

        WithdrawalRequest storage request = pendingWithdrawals[msg.sender];
        if (request.recipient != address(0)) revert PendingWithdrawalExists();

        request.readyAt = uint64(block.timestamp + minDelay);
        request.recipient = recipient;
        request.amount = amount;

        pendingWithdrawals[msg.sender] = request;
        emit WithdrawalRequested(msg.sender, amount, recipient, request.readyAt);
    }

    function cancelWithdrawal() public {
        WithdrawalRequest storage request = pendingWithdrawals[msg.sender];
        if (request.recipient == address(0)) revert NoPendingWithdrawal();

        emit WithdrawalCancelled(msg.sender, request.amount);
        delete pendingWithdrawals[msg.sender];
    }

    function executeWithdrawal() public {
        WithdrawalRequest memory request = pendingWithdrawals[msg.sender];
        if (request.recipient == address(0)) revert NoPendingWithdrawal();

        if (block.timestamp < request.readyAt) { revert WithdrawalNotReady(request.readyAt, uint64(block.timestamp)); }

        uint256 balance = balances[msg.sender];
        if (balance < request.amount) { revert InsufficientBalance(request.amount, balance); }

        delete pendingWithdrawals[msg.sender];
        balances[msg.sender] = balance - request.amount;
        totalDeposits -= request.amount;

        (bool success, ) = request.recipient.call{ value: request.amount }("");
        if (!success) { revert TransferFailed(request.recipient, request.amount); }

        emit WithdrawalExecuted(msg.sender, request.amount, request.recipient);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function getPendingWithdrawal(address account) external view returns (WithdrawalRequest memory) {
        return pendingWithdrawals[account];
    }
}
