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
    
    // Address of the creator or this smart contract
    address creator;
    // Address of the recipient;
    address public recipient;

    /// @dev The constructor function
    /// @param _creator The address of the creator
    /// @param _client The address of the Dao
    /// @param _recipient The address of the recipient. 0 for the Dao
    /// @param _initialSupply The initial supply of tokens for the recipient (not mandatory)
    /// @param _tokenName The token name for display purpose
    //function PassManager(
        //address _creator,
        //address _client,
        //address _recipient,
        //uint256 _initialSupply,
        //string _tokenName
    //) TokenManager(
        //_creator,
        //_client,
        //_recipient,
        //_initialSupply,
        //_tokenName) {}

     /// @return True if the sender is the creator of this manager
    function IsCreator(address _sender) constant external returns (bool);

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
    
    function PassManager(
        address _creator,
        address _client,
        address _recipient,
        uint256 _initialSupply,
        string _tokenName
    ) PassTokenManager(
        _creator,
        _client,
        _recipient,
        _initialSupply,
        _tokenName
        ) {
        
        if (_creator == 0 || _client == 0) throw;
        
        creator = _creator;
        recipient = _recipient;

   }

    function IsCreator(address _sender) constant external returns (bool) {
        if (creator == _sender) return true;
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
    event NewPassManager(address Creator, address Client, address Recipient, 
        uint256 InitialSupply, string TokenName, address PassManager);
    function createManager(
        address _creator,
        address _client,
        address _recipient,
        uint256 _initialSupply,
        string _tokenName
        ) returns (PassManager) {
        PassManager _passManager = new PassManager(
            _creator,
            _client,
            _recipient,
            _initialSupply,
            _tokenName
        );
        NewPassManager(_creator, _client, _recipient, _initialSupply, _tokenName, _passManager);
        return _passManager;
    }
}
