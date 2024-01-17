// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin's AccessControl library to manage roles and permissions
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title MultiSigWallet
 * @dev A contract for managing multi-signature wallets.
 */
contract MultiSigWallet is AccessControl {
   // Define the role identifier for owners
   bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
   // Store the threshold number of approvals needed to execute a transaction
   uint public threshold;
   // Map transaction IDs to transactions
   mapping (uint => Transaction) public transactions;
   // Keep track of the total number of transactions
   uint public transactionCount;

   /**
    * @dev Structure to represent a transaction.
    * @param to Recipient of the transaction.
    * @param value Amount of Ether sent with the transaction.
    * @param data Additional data sent along with the transaction.
    * @param approvals Number of approvals the transaction has received.
    * @param executed Whether the transaction has been executed.
    */
   struct Transaction {
       address to;
       uint value;
       bytes data;
       uint approvals;
       bool executed;
   }

   // Event to log when a transaction is submitted
   event SubmitTransaction(uint transactionId, address indexed owner);
   // Event to log when a transaction is confirmed
   event ConfirmTransaction(uint transactionId, address indexed owner);
   // Event to log when a transaction is executed
   event ExecuteTransaction(uint transactionId, address indexed owner);

   /**
    * @dev Constructor for the contract.
    * @param _owners Array of addresses representing the owners of the wallet.
    * @param _threshold The number of approvals needed to execute a transaction.
    */
   constructor(address[] memory _owners, uint _threshold) {
       // Ensure that the number of owners does not exceed 10
       require(_owners.length <= 10, "Maximum 10 owners allowed");
       // Ensure that the threshold is less than or equal to the number of owners
       require(_threshold <= _owners.length, "Threshold must be less than or equal to the number of owners");
       // Grant the OWNER_ROLE to each owner
       for (uint i=0; i<_owners.length; i++) {
           grantRole(OWNER_ROLE, _owners[i]);
       }
       // Set the threshold
       threshold = _threshold;
   }

   /*
    * @dev Allows an owner to submit a new transaction.
    * @param _to The recipient of the transaction.
    * @param _value The amount of Ether sent with the transaction.
    * @param _data Additional data sent along with the transaction.
    * @return Returns the ID of the newly created transaction.
    */
   function submitTransaction(address _to, uint _value, bytes memory _data) public onlyRole(OWNER_ROLE) returns (uint transactionId) {
       // Assign a new ID to the transaction
       transactionId = transactionCount++;
       // Create a new transaction with the provided details
       transactions[transactionId] = Transaction({
           to: _to,
           value: _value,
           data: _data,
           approvals: 0,
           executed: false
       });
       // Emit an event to log the transaction submission
       emit SubmitTransaction(transactionId, msg.sender);
   }

   /**
    * @dev Allows an owner to confirm a transaction.
    * @param _transactionId The ID of the transaction to confirm.
    */
   function confirmTransaction(uint _transactionId) public onlyRole(OWNER_ROLE) {
       // Get the transaction from the transactions mapping
       Transaction storage txn = transactions[_transactionId];
       // Ensure that the transaction has not been executed yet
       require(!txn.executed, "Transaction already executed");
       // Increment the number of approvals for the transaction
       txn.approvals++;
       // Emit an event to log the transaction confirmation
       emit ConfirmTransaction(_transactionId, msg.sender);
       // If the transaction has received enough approvals, execute it
       if (txn.approvals >= threshold) {
           executeTransaction(_transactionId);
       }
   }

   /**
    * @dev Executes a transaction.
    * @param _transactionId The ID of the transaction to execute.
    */
   function executeTransaction(uint _transactionId) internal {
       // Get the transaction from the transactions mapping
       Transaction storage txn = transactions[_transactionId];
       // Ensure that the transaction has not been executed yet
       require(!txn.executed, "Transaction already executed");
       // Mark the transaction as executed
       txn.executed = true;
       // Attempt to send the Ether and call the function of the contract
       (bool success, ) = txn.to.call{value: txn.value}(txn.data);
       // Require that the transaction was successful
       require(success, "Transaction failed");
       // Emit an event to log the transaction execution
       emit ExecuteTransaction(_transactionId, msg.sender);
   }
}
