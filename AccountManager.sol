import "TokenManager.sol";

pragma solidity ^0.4.2;

/*
 * This file is part of Pass DAO.
 
 * The Account Manager smart contract is used for the management of ether accounts.
 * The contract derives to the Token Manager smart contract for the management of tokens.
 * Allows to receive or withdraw ethers and to buy Dao shares.
 
 * Recipient is 0 for the Dao account manager and the address of
 * contractor's recipient for the account managers of contractors.
*/

/// @title Account Manager smart contract of the Pass Decentralized Autonomous Organisation
contract AccountManager is TokenManager {
    
    // Address of the creator or this smart contract
    address public creator;
    // Address of the account manager recipient;
    address public recipient;

    /// @dev The constructor function
    /// @param _creator The address of the creator
    /// @param _client The address of the Dao
    /// @param _recipient The address of the recipient. 0 for the Dao
    /// @param _initialSupply The initial supply of tokens for the recipient (not mandatory)
    function AccountManager(
        address _creator,
        address _client,
        address _recipient,
        uint256 _initialSupply
    ) TokenManager(
        _creator,
        _client,
        _recipient,
        _initialSupply) {
        
        creator = _creator;
        recipient = _recipient;

   }

     /// @return True if the sender is the creator of this account manager
    function IsCreator(address _sender) constant external returns (bool) {
        if (creator == _sender) return true;
    }

    /// @notice Fallback function to allow sending ethers to the account manager
    function () payable {
    }

    /// @notice Function to buy Dao shares according to the funding rules 
    /// with `msg.sender` as the beneficiary
    function buyShares() payable {
        buySharesFor(msg.sender);
    } 
    
    /// @notice Function to buy Dao shares according to the funding rules 
    /// @param _recipient The beneficiary of the created shares
    function buySharesFor(address _recipient) payable {
        
        if (recipient != 0
            || !FundingRules.publicCreation 
            || !createToken(_recipient, msg.value, now)) {
            throw;
        }

    }

    /// @dev Function used by the client to send ethers from the Dao account manager
    /// @param _recipient The address to send to
    /// @param _amount The amount (in wei) to send
    /// @return Whether the transfer was successful or not
    function sendTo(
        address _recipient, 
        uint _amount
    ) external onlyClient returns (bool _success) {
    
        if (_amount > 0 && recipient == 0) return _recipient.send(_amount);    

    }

    /// @notice Function to allow contractors to withdraw ethers from their account manager
    /// @param _amount The amount (in wei) to withdraw
    function withdraw(uint _amount) {
        if (msg.sender != recipient
            || recipient == 0
            || !recipient.send(_amount)) throw;
    }
    
}    
  
