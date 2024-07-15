// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ErrandApp {
    // State variables
    address public owner;
    uint256 public tokenRewardRate;
    uint256 public transactionFeeRate; // 2.5% transaction fee

    enum UserType { General, Agent, ServiceProvider }

    struct User {
        bool isRegistered;
        uint256 balance;
        uint256 subscriptionExpiry;
        UserType userType;
    }

    struct Feedback {
        address user;
        uint8 rating; // 1 to 5
        string comment;
    }

    mapping(address => User) public users;
    Feedback[] public feedbacks;

    // Events
    event UserRegistered(address user, UserType userType);
    event ServicePaid(address indexed user, uint256 amount, uint256 tokensRewarded);
    event Withdrawal(address indexed user, uint256 amount);
    event FeedbackGiven(address indexed user, uint8 rating, string comment);
    event PaymentProcessed(address indexed from, address indexed to, uint256 amount, uint256 fee);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyRegisteredUser() {
        require(users[msg.sender].isRegistered, "User not registered");
        _;
    }

    // Constructor
    constructor(uint256 _tokenRewardRate, uint256 _transactionFeeRate) {
        owner = msg.sender;
        tokenRewardRate = _tokenRewardRate;
        transactionFeeRate = _transactionFeeRate;
    }

    // User registration
    function registerUser(UserType _userType) external {
        require(!users[msg.sender].isRegistered, "User already registered");
        users[msg.sender] = User(true, 0, 0, _userType);
        emit UserRegistered(msg.sender, _userType);
    }

    // Subscription payment
    function subscribe(uint256 duration) external payable onlyRegisteredUser {
        require(msg.value > 0, "Payment must be greater than zero");
        users[msg.sender].subscriptionExpiry = block.timestamp + duration;
        users[msg.sender].balance += msg.value;
        uint256 tokensRewarded = msg.value * tokenRewardRate;
        emit ServicePaid(msg.sender, msg.value, tokensRewarded);
    }

    // Pay for a service
    function payForService(address payable _to, uint256 _amount) external onlyRegisteredUser {
        require(users[msg.sender].balance >= _amount, "Insufficient balance");
        require(_amount > 0, "Payment must be greater than zero");

        uint256 fee = (_amount * transactionFeeRate) / 100;
        uint256 amountAfterFee = _amount - fee;

        users[msg.sender].balance -= _amount;
        _to.transfer(amountAfterFee);
        emit PaymentProcessed(msg.sender, _to, _amount, fee);
    }

    // Withdraw funds
    function withdraw(uint256 _amount) external onlyRegisteredUser {
        require(users[msg.sender].balance >= _amount, "Insufficient balance");
        payable(msg.sender).transfer(_amount);
        users[msg.sender].balance -= _amount;
        emit Withdrawal(msg.sender, _amount);
    }

    // Check balance
    function checkBalance() external view onlyRegisteredUser returns (uint256) {
        return users[msg.sender].balance;
    }

    // Give feedback and rating
    function giveFeedback(uint8 _rating, string calldata _comment) external onlyRegisteredUser {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        feedbacks.push(Feedback(msg.sender, _rating, _comment));
        emit FeedbackGiven(msg.sender, _rating, _comment);
    }

    // Owner-only function to withdraw contract balance
    function ownerWithdraw(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient contract balance");
        payable(owner).transfer(_amount);
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
