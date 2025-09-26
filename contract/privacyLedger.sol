// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title PrivacyLedger
 * @dev A privacy-focused ledger system for secure and anonymous transactions
 * @author privacyLedger Team
 */
contract Project {
    
    // Struct to represent a private transaction
    struct PrivateTransaction {
        bytes32 transactionHash;
        uint256 timestamp;
        uint256 amount;
        bool isActive;
    }
    
    // Mapping to store encrypted transaction data
    mapping(bytes32 => PrivateTransaction) private transactions;
    mapping(address => bytes32[]) private userTransactions;
    mapping(address => uint256) private balances;
    
    // Events
    event TransactionCreated(bytes32 indexed transactionHash, address indexed user);
    event BalanceUpdated(address indexed user, uint256 newBalance);
    event TransactionVerified(bytes32 indexed transactionHash, bool isValid);
    
    // Modifiers
    modifier onlyValidTransaction(bytes32 _hash) {
        require(transactions[_hash].isActive, "Transaction does not exist or is inactive");
        _;
    }
    
    modifier hasBalance(uint256 _amount) {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        _;
    }
    
    /**
     * @dev Core Function 1: Create a private transaction entry
     * @param _encryptedData Encrypted transaction data
     * @param _amount Transaction amount
     * @return transactionHash The hash of the created transaction
     */
    function createPrivateTransaction(
        bytes32 _encryptedData, 
        uint256 _amount
    ) external hasBalance(_amount) returns (bytes32) {
        
        // Generate unique transaction hash
        bytes32 transactionHash = keccak256(
            abi.encodePacked(
                msg.sender,
                _encryptedData,
                block.timestamp,
                block.difficulty
            )
        );
        
        // Create transaction record
        transactions[transactionHash] = PrivateTransaction({
            transactionHash: transactionHash,
            timestamp: block.timestamp,
            amount: _amount,
            isActive: true
        });
        
        // Update user's transaction list
        userTransactions[msg.sender].push(transactionHash);
        
        // Deduct amount from sender's balance
        balances[msg.sender] -= _amount;
        
        emit TransactionCreated(transactionHash, msg.sender);
        emit BalanceUpdated(msg.sender, balances[msg.sender]);
        
        return transactionHash;
    }
    
    /**
     * @dev Core Function 2: Verify transaction authenticity using zero-knowledge proof concept
     * @param _transactionHash Hash of the transaction to verify
     * @param _proof Cryptographic proof for verification
     * @return isValid Whether the transaction is valid
     */
    function verifyTransaction(
        bytes32 _transactionHash,
        bytes32 _proof
    ) external view onlyValidTransaction(_transactionHash) returns (bool) {
        
        PrivateTransaction memory txn = transactions[_transactionHash];
        
        // Simple proof verification (in real implementation, this would use zk-SNARKs)
        bytes32 expectedProof = keccak256(
            abi.encodePacked(
                txn.transactionHash,
                txn.timestamp,
                txn.amount
            )
        );
        
        bool isValid = (expectedProof == _proof);
        
        return isValid;
    }
    
    /**
     * @dev Core Function 3: Deposit funds to maintain privacy balance
     * @param _amount Amount to deposit
     */
    function depositFunds(uint256 _amount) external payable {
        require(msg.value == _amount, "Sent value must match amount parameter");
        require(_amount > 0, "Amount must be greater than zero");
        
        balances[msg.sender] += _amount;
        
        emit BalanceUpdated(msg.sender, balances[msg.sender]);
    }
    
    // Additional utility functions
    
    /**
     * @dev Get user's current balance
     * @return Current balance of the caller
     */
    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    /**
     * @dev Get transaction count for user
     * @return Number of transactions created by the caller
     */
    function getUserTransactionCount() external view returns (uint256) {
        return userTransactions[msg.sender].length;
    }
    
    /**
     * @dev Get transaction details (limited info for privacy)
     * @param _transactionHash Hash of the transaction
     * @return timestamp Transaction timestamp
     * @return isActive Whether transaction is active
     */
    function getTransactionInfo(bytes32 _transactionHash) 
        external 
        view 
        onlyValidTransaction(_transactionHash) 
        returns (uint256 timestamp, bool isActive) 
    {
        PrivateTransaction memory txn = transactions[_transactionHash];
        return (txn.timestamp, txn.isActive);
    }
    
    /**
     * @dev Emergency function to deactivate a transaction (only by creator)
     * @param _transactionHash Hash of the transaction to deactivate
     */
    function deactivateTransaction(bytes32 _transactionHash) external {
        require(transactions[_transactionHash].isActive, "Transaction already inactive");
        
        // Check if caller is in the transaction list (simplified ownership check)
        bool isOwner = false;
        bytes32[] memory userTxns = userTransactions[msg.sender];
        
        for (uint i = 0; i < userTxns.length; i++) {
            if (userTxns[i] == _transactionHash) {
                isOwner = true;
                break;
            }
        }
        
        require(isOwner, "Only transaction creator can deactivate");
        
        transactions[_transactionHash].isActive = false;
        
        // Refund the amount
        balances[msg.sender] += transactions[_transactionHash].amount;
        
        emit BalanceUpdated(msg.sender, balances[msg.sender]);
    }
}
