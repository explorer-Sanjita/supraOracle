/*
Token Swap Smart Contract

Problem Description:
Create a smart contract that facilitates the swapping of one ERC-20 token for another at a predefined
exchange rate. The smart contract should include the following features:
● Users can swap Token A for Token B and vice versa.
● The exchange rate between Token A and Token B is fixed.
● Implement proper checks to ensure that the swap adheres to the exchange rate.
● Include events to log swap details.

Requirements:
● Implement the smart contract in Solidity.
● Use the ERC-20 standard for both tokens.
● Ensure proper error handling and event logging.
● Implement the swap functionality securely and efficiently.
*/

/*
Design choices
1) I have used openzeppelin libraries to reuse code. Their codes are also audited regularly ensuring safety measures.
2) Importing IERC20 (Interface for ERC20), SafeERC20 (ensures safety measures for ERC20 Tokens), Ownable contract
3) Ensuring gas optimization : If I were to import and use ERC20 directly, it would get the full 
implementation of an ERC-20 token, including additional functions that might not be needed in this 
contract. This could result in a larger and more expensive contract. Hence IERC20 imported instead of ERC20
*/

// Additional feature: Setting Exchange rate, I haven't hard coded the exchange rate to provide greater flexiblity
//Only owner is allowed to change the exchange rate through the setExchangeRate function.



// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSwap is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public exchangeRate; // 1 Token A = exchangeRate Token B

    event Swap(address indexed user, uint256 amountA, uint256 amountB);

    constructor(
        address _tokenA,
        address _tokenB,
        uint256 _exchangeRate,
        address _owner
    ) Ownable(_owner) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        exchangeRate = _exchangeRate;
    }

    function swapAToB(uint256 _amountA) public  {
        require(_amountA > 0, "Amount must be greater than 0");

        uint256 amountB = (_amountA * exchangeRate) / 1e18;

        // Ensure the user has enough Token A
        require(tokenA.balanceOf(msg.sender) >= _amountA, "Insufficient Token A balance");

        // Transfer Token A from the user to the contract
        tokenA.safeTransferFrom(msg.sender, address(this), _amountA);

        // Transfer Token B from the contract to the user
        tokenB.safeTransfer(msg.sender, amountB);

        emit Swap(msg.sender, _amountA, amountB);
    }

    function swapBToA(uint256 _amountB) public  {
        require(_amountB > 0, "Amount must be greater than 0");

        uint256 amountA = (_amountB * 1e18) / exchangeRate;

        // Ensure the user has enough Token B
        require(tokenB.balanceOf(msg.sender) >= _amountB, "Insufficient Token B balance");

        // Transfer Token B from the user to the contract
        tokenB.safeTransferFrom(msg.sender, address(this), _amountB);

        // Transfer Token A from the contract to the user
        tokenA.safeTransfer(msg.sender, amountA);

        emit Swap(msg.sender, amountA, _amountB);
    }

    function setExchangeRate(uint256 _newExchangeRate) public  onlyOwner {
        require(_newExchangeRate > 0, "Exchange rate must be greater than 0");
        exchangeRate = _newExchangeRate;
    }
}
