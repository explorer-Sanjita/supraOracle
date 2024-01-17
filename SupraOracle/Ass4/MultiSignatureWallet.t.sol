// Considering 3 people having owner roles and threshold set to 2

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "foundry/Foundry.sol";
import "foundry/Assert.sol";
import "foundry/DeployedAddresses.sol";
import "MultiSignatureWallet.sol";

contract MultiSigWalletTest {
    MultiSigWallet private wallet;

    // Deploy the contract before each test
    function beforeEach() public {
        wallet = new MultiSigWallet([0x1, 0x2, 0x3], 2);
    }

    // Test case to check the initial state of the contract
    function testInitialState() public {
        Assert.equal(wallet.threshold(), 2, "Initial threshold should be 2");
        Assert.equal(wallet.hasRole(MultiSigWallet.OWNER_ROLE(), 0x1), true, "Owner 0x1 should have OWNER_ROLE");
        Assert.equal(wallet.hasRole(MultiSigWallet.OWNER_ROLE(), 0x2), true, "Owner 0x2 should have OWNER_ROLE");
        Assert.equal(wallet.hasRole(MultiSigWallet.OWNER_ROLE(), 0x3), true, "Owner 0x3 should have OWNER_ROLE");
    }

    // Test case to submit a transaction and check its details
    function testSubmitTransaction() public {
        uint transactionId = wallet.submitTransaction(address(0x4), 1 ether, "");
        Assert.equal(transactionId, 0, "Transaction ID should be 0");
        
        (address to, uint value, bytes memory data, uint approvals, bool executed) = wallet.transactions(0);
        Assert.equal(to, address(0x4), "Transaction to address should be 0x4");
        Assert.equal(value, 1 ether, "Transaction value should be 1 ether");
        Assert.equal(data.length, 0, "Transaction data length should be 0");
        Assert.equal(approvals, 0, "Transaction approvals should be 0");
        Assert.equal(executed, false, "Transaction should not be executed");
    }

    // Test case to confirm a transaction and check its details
    function testConfirmTransaction() public {
        wallet.submitTransaction(address(0x4), 1 ether, "");
        wallet.confirmTransaction(0);
        
        (address to, uint value, bytes memory data, uint approvals, bool executed) = wallet.transactions(0);
        Assert.equal(approvals, 1, "Transaction approvals should be 1 after confirmation");
    }

    // Test case to execute a transaction and check its details
    function testExecuteTransaction() public {
        wallet.submitTransaction(address(0x4), 1 ether, "");
        wallet.confirmTransaction(0);
        wallet.executeTransaction(0);
        
        (address to, uint value, bytes memory data, uint approvals, bool executed) = wallet.transactions(0);
        Assert.equal(executed, true, "Transaction should be executed");
    }
}
