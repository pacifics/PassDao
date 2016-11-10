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

    struct proposal {
        // Amount (in wei) of the proposal
        uint amount;
        // A description of the proposal
        string description;
        // The hash of the proposal's document
        bytes32 hashOfTheDocument;
        // A unix timestamp, denoting the date when the proposal was created
        uint dateOfProposal;
        // The sum amount (in wei) ordered for this proposal 
        uint orderAmount;
        // A unix timestamp, denoting the date of the last order for the approved proposal
        uint dateOfOrder;
    }
        
    // Proposals to work for the client
    proposal[] public proposals;
    
    /// @dev The constructor function
    /// @param _creator The address of the creator
    /// @param _client The address of the Dao
    /// @param _recipient The address of the recipient. 0 for the Dao
    //function PassManager(
        //address _creator,
        //address _client,
        //address _recipient
    //) PassTokenManager(
        //_creator,
        //_client,
        //_recipient);

    /// @notice Fallback function to allow sending ethers to the manager
    function () payable;
    
    /// @notice Function to update the recipent address
    /// @param _newRecipient The adress of the recipient
    function updateRecipient(address _newRecipient) onlyContractor;

    /// @notice Function to buy Dao shares according to the funding rules 
    /// with `msg.sender` as the beneficiary
    function buyShares() payable;
    
    /// @notice Function to buy Dao shares according to the funding rules 
    /// @param _recipient The beneficiary of the created shares
    function buySharesFor(address _recipient) payable;

    /// @notice Function to make a proposal to work for the client
    /// @param _amount The amount (in wei) of the proposal
    /// @param _description String describing the proposal
    /// @param _hashOfTheDocument The hash of the proposal document
    /// @return The index of the contractor proposal
    function newProposal(
        uint _amount,
        string _description, 
        bytes32 _hashOfTheDocument
    ) returns (uint);
    
    /// @notice Function used by the client to order the contractor proposal
    /// @param _proposalID The index of the contractor proposal
    /// @param _amount The amount (in wei) of the order
    /// @return Whether the order was made or not
    function order(
        uint _proposalID,
        uint _amount
    ) external onlyClient returns (bool) ;
    
    /// @notice Function used by the client to send ethers from the Dao manager
    /// @param _recipient The address to send to
    /// @param _amount The amount (in wei) to send
    /// @return Whether the transfer was successful or not
    function sendTo(
        address _recipient, 
        uint _amount
    ) external onlyClient returns (bool);

    /// @notice Function to allow contractors to withdraw ethers from their manager
    /// @param _amount The amount (in wei) to withdraw
    function withdraw(uint _amount) onlyContractor;
    
    event ProposalAdded(uint indexed ProposalID, uint Amount, string Description);

}    

contract PassManager is PassManagerInterface, PassTokenManager {

    function PassManager(
        address _creator,
        address _client,
        address _recipient
    ) PassTokenManager(
        _creator,
        _client,
        _recipient
        ) {
        proposals.length = 1;
    }

    function () payable {
    }

    function updateRecipient(address _newRecipient) onlyContractor {

        if (recipient == 0 
            || _newRecipient == 0 
            || _newRecipient == client) throw;

        recipient = _newRecipient;
    } 

    function buyShares() payable {
        buySharesFor(msg.sender);
    } 
    
    function buySharesFor(address _recipient) payable {
        
        if (recipient != 0
            || !FundingRules[0].publicCreation 
            || !createToken(_recipient, msg.value, now)) {
            throw;
        }

    }
   
    function newProposal(
        uint _amount,
        string _description, 
        bytes32 _hashOfTheDocument
    ) returns (uint) {
        
        if (msg.sender != recipient && msg.sender != creator) throw;

        uint _proposalID = proposals.length++;
        proposal c = proposals[_proposalID];

        c.amount = _amount;
        c.description = _description;
        c.hashOfTheDocument = _hashOfTheDocument; 
        c.dateOfProposal = now;
        
        ProposalAdded(_proposalID, c.amount, c.description);
        
        return _proposalID;
        
    }
    
    function order(
        uint _proposalID,
        uint _orderAmount
    ) external onlyClient returns (bool) {
    
        proposal c = proposals[_proposalID];
        
        if (c.orderAmount + _orderAmount > c.amount) return; 

        c.orderAmount += _orderAmount;
        c.dateOfOrder = now;
        
        return true;

    }

    function sendTo(
        address _recipient,
        uint _amount
    ) external onlyClient returns (bool) {
    
        if (_recipient.send(_amount)) return true;
        else return false;

    }
   
    function withdraw(uint _amount) onlyContractor {
        if (recipient == 0 || !recipient.send(_amount)) throw;
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
