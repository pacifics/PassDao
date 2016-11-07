import "PassTokenManager.sol";

pragma solidity ^0.4.2;

/*
 *
 * This file is part of Pass DAO.
 *
 * The Manager smart contract is used for the management of accounts and tokens.
 * Allows to receive or withdraw ethers and to buy Dao shares.
 * The contract derives to the Token Manager smart contract for the management of tokens.
 *
 * Recipient is 0 for the Dao account manager and the address of
 * contractor's recipient for the contractors's mahagers.
 *
*/

/// @title Manager smart contract of the Pass Decentralized Autonomous Organisation
contract PassManagerInterface is PassTokenManagerInterface {
    
    // Address of the recipient;
    address recipient;

    /// @return The recipient adress
    function getRecipient() constant external returns (address);
    
    /// @dev The constructor function
    /// @param _creator The address of the creator
    /// @param _client The address of the Dao
    /// @param _recipient The address of the recipient. 0 for the Dao
    //function PassManager(
        //address _creator,
        //address _client,
        //address _recipient
    //) TokenManager(
        //_client,
        //_recipient);

    /// @notice Fallback function to allow sending ethers to the manager
    function () payable;

    /// @notice Function to buy Dao shares according to the funding rules 
    /// with `msg.sender` as the beneficiary
    function buyShares() payable;
    
    /// @notice Function to buy Dao shares according to the funding rules 
    /// @param _recipient The beneficiary of the created shares
    function buySharesFor(address _recipient) payable;

    /// @dev Function used by the client to send ethers from the Dao manager
    /// @param _recipient The address to send to
    /// @param _amount The amount (in wei) to send
    /// @return Whether the transfer was successful or not
    function sendTo(
        address _recipient, 
        uint _amount
    ) external onlyClient;

    /// @notice Function to allow contractors to withdraw ethers from their manager
    /// @param _amount The amount (in wei) to withdraw
    function withdraw(uint _amount);
    
}    

contract PassManager is PassManagerInterface, PassTokenManager {

    function getRecipient() constant external returns (address) {
        return (recipient);
    }
    
    function PassManager(
        address _creator,
        address _client,
        address _recipient
    ) PassTokenManager(
        _creator,
        _client
        ) {
        
        recipient = _recipient;

   }

    function () payable {
    }


    function buyShares() payable {
        buySharesFor(msg.sender);
    } 
    
    function buySharesFor(address _recipient) payable {
        
        if (recipient != 0
            || !FundingRules.publicCreation 
            || !createToken(_recipient, msg.value, now)) {
            throw;
        }

    }

    function sendTo(
        address _recipient, 
        uint _amount
    ) external onlyClient {
    
        if (!_recipient.send(_amount)) throw;    

    }

    function withdraw(uint _amount) {
        if ((msg.sender != recipient && msg.sender != creator)
            || recipient == 0
            || !recipient.send(_amount)) throw;
    }
    
}    

contract PassManagerCreator {
    event NewPassManager(address Creator, address Client, address Recipient, address PassManager);
    function createManager(
        address _client,
        address _recipient
        ) returns (PassManager) {
        PassManager _passManager = new PassManager(
            msg.sender,
            _client,
            _recipient
        );
        NewPassManager(msg.sender, _client, _recipient, _passManager);
        return _passManager;
    }
}
