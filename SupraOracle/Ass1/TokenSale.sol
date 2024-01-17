

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSale is Ownable {
    using SafeERC20 for IERC20;

    // ERC-20 token used in the sale
    IERC20 public projectToken;

    // Enum to track the current sale phase
    enum SalePhase { Presale, PublicSale }
    SalePhase public currentPhase;

    // Caps and limits for the presale and public sale
    uint256 public presaleCap;
    uint256 public publicSaleCap;
    uint256 public minContribution;
    uint256 public maxContribution;

    // Mapping to track contributions per participant
    mapping(address => uint256) public contributions;

    // Mapping to track whether a contributor claimed a refund during the public sale
    mapping(address => bool) public claimedRefund;

    // Events to log significant actions
    event TokenPurchase(address indexed buyer, uint256 amount, SalePhase phase);
    event TokenDistribution(address indexed recipient, uint256 amount);
    event RefundClaimed(address indexed contributor, uint256 amount);

    // Constructor to initialize the contract with parameters
    constructor(
        IERC20 _projectToken,
        uint256 _presaleCap,
        uint256 _publicSaleCap,
        uint256 _minContribution,
        uint256 _maxContribution,
        address initialOwner
    ) Ownable(initialOwner) {
        // Set the ERC-20 token
        projectToken = _projectToken;

        // Set caps and contribution limits
        presaleCap = _presaleCap;
        publicSaleCap = _publicSaleCap;
        minContribution = _minContribution;
        maxContribution = _maxContribution;

        // Set the initial sale phase to Presale
        currentPhase = SalePhase.Presale;
    }

    // Modifier to restrict functions to the presale phase
    modifier inPresalePhase() {
        require(currentPhase == SalePhase.Presale, "Not in presale phase");
        _;
    }

    // Modifier to restrict functions to the public sale phase
    modifier inPublicSalePhase() {
        require(currentPhase == SalePhase.PublicSale, "Not in public sale phase");
        _;
    }

    // Function for contributors to participate in the presale
    function contributeToPresale() external payable inPresalePhase {
        // Check contribution limits and caps
        require(msg.value >= minContribution, "Contribution below minimum limit");
        require(contributions[msg.sender] + msg.value <= maxContribution, "Contribution exceeds maximum limit");
        require(address(this).balance + msg.value <= presaleCap, "Presale cap reached");

        // Record the contribution
        contributions[msg.sender] += msg.value;

        // Transfer tokens to the contributor
        projectToken.safeTransfer(msg.sender, getTokenAmount(msg.value));

        // Emit a purchase event
        emit TokenPurchase(msg.sender, msg.value, SalePhase.Presale);
    }

    // Function for contributors to participate in the public sale
    function contributeToPublicSale() external payable inPublicSalePhase {
        // Check contribution limits and caps
        require(msg.value >= minContribution, "Contribution below minimum limit");
        require(contributions[msg.sender] + msg.value <= maxContribution, "Contribution exceeds maximum limit");
        require(address(this).balance + msg.value <= publicSaleCap, "Public sale cap reached");

        // Record the contribution
        contributions[msg.sender] += msg.value;

        // Transfer tokens to the contributor
        projectToken.safeTransfer(msg.sender, getTokenAmount(msg.value));

        // Emit a purchase event
        emit TokenPurchase(msg.sender, msg.value, SalePhase.PublicSale);
    }

    // Function for the owner to distribute tokens to a specific address
    function distributeTokens(address recipient, uint256 amount) external onlyOwner {
        // Transfer tokens to the specified recipient
        projectToken.safeTransfer(recipient, amount);

        // Emit a distribution event
        emit TokenDistribution(recipient, amount);
    }

    // Function for contributors to claim a refund if the minimum cap is not reached in the public sale
    function claimRefund() external {
        require(currentPhase == SalePhase.PublicSale, "Refunds only available in public sale phase");
        require(contributions[msg.sender] > 0, "No contribution to refund");
        require(!claimedRefund[msg.sender], "Refund already claimed");

        // Mark the refund as claimed
        claimedRefund[msg.sender] = true;

        // Transfer Ether back to the contributor
        payable(msg.sender).transfer(contributions[msg.sender]);

        // Emit a refund claimed event
        emit RefundClaimed(msg.sender, contributions[msg.sender]);
    }

    // Function for the owner to set the public sale phase
    function setPublicSalePhase() external onlyOwner {
        require(currentPhase == SalePhase.Presale, "Already in public sale phase");
        currentPhase = SalePhase.PublicSale;
    }

    // Internal function to calculate token amount based on the contributed Ether
    function getTokenAmount(uint256 weiAmount) internal pure returns (uint256) {
        // Adjust this function to calculate the actual token amount based on your project's conversion rate
        // For simplicity, assuming 1 ETH = 1000 Project Tokens
        return weiAmount * 1000;
    }

    // Fallback function to reject direct Ether transfers
    receive() external payable {
        revert("Use contributeToPresale or contributeToPublicSale functions");
    }
}
