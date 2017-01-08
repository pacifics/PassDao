import "PassTokenManager.sol";

pragma solidity ^0.4.6;

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
        // The index of the last approved client proposal
        uint lastClientProposalID;
        // The sum amount (in wei) ordered for this proposal 
        uint orderAmount;
        // A unix timestamp, denoting the date of the last order for the approved proposal
        uint dateOfOrder;
    }
        
    // Proposals to work for the client
    proposal[] public proposals;
    
    // The address of the last Manager before cloning
    address public clonedFrom;
    
    /// @dev The constructor function
    /// @param _client The address of the Dao
    /// @param _recipient The address of the recipient. 0 for the Dao
    /// @param _clonedFrom The address of the last Manager before cloning
    /// @param _tokenName The token name for display purpose
    /// @param _tokenSymbol The token symbol for display purpose
    /// @param _tokenDecimals The quantity of decimals for display purpose
    /// @param _transferable True if allows the transfer of tokens
    //function PassManager(
    //    address _client,
    //    address _recipient,
    //    address _clonedFrom,
    //    string _tokenName,
    //    string _tokenSymbol,
    //    uint8 _tokenDecimals,
    //    bool _transferable
    //) PassTokenManager(
    //    msg.sender,
    //    _client,
    //    _recipient,
    //    _tokenName,
    //    _tokenSymbol,
    //    _tokenDecimals,
    //    _transferable);

    /// @notice Function to allow sending fees in wei to the Dao
    function receiveFees() payable;
    /// @notice Function to allow the contractor making a deposit in wei
    function receiveDeposit() payable;

    /// @notice Function to clone a proposal from another manager contract
    /// @param _amount Amount (in wei) of the proposal
    /// @param _description A description of the proposal
    /// @param _hashOfTheDocument The hash of the proposal's document
    /// @param _dateOfProposal A unix timestamp, denoting the date when the proposal was created
    /// @param _lastClientProposalID The index of the last approved client proposal
    /// @param _orderAmount The sum amount (in wei) ordered for this proposal 
    /// @param _dateOfOrder A unix timestamp, denoting the date of the last order for the approved proposal
    function cloneProposal(
        uint _amount,
        string _description,
        bytes32 _hashOfTheDocument,
        uint _dateOfProposal,
        uint _lastClientProposalID,
        uint _orderAmount,
        uint _dateOfOrder);
    
    /// @notice Function to clone tokens from a manager
    /// @param _from The index of the first holder
    /// @param _to The index of the last holder
    function cloneTokens(
        uint _from, 
        uint _to);
    
    /// @notice Function to update the client address
    function updateClient(address _newClient);
    
    /// @notice Function to update the recipent address
    /// @param _newRecipient The adress of the recipient
    function updateRecipient(address _newRecipient);

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
    
    /// @notice Function used by the client to order according to the contractor proposal
    /// @param _clientProposalID The index of the last approved client proposal
    /// @param _proposalID The index of the contractor proposal
    /// @param _amount The amount (in wei) of the order
    /// @return Whether the order was made or not
    function order(
        uint _clientProposalID,
        uint _proposalID,
        uint _amount
    ) external returns (bool) ;
    
    /// @notice Function used by the client to send ethers from the Dao manager
    /// @param _recipient The address to send to
    /// @param _amount The amount (in wei) to send
    /// @return Whether the transfer was successful or not
    function sendTo(
        address _recipient, 
        uint _amount
    ) external returns (bool);

    /// @notice Function to allow contractors to withdraw ethers
    /// @param _amount The amount (in wei) to withdraw
    function withdraw(uint _amount);
    
    /// @return The number of Dao rules proposals     
    function numberOfProposals() constant returns (uint);
    
    event FeesReceived(address indexed From, uint Amount);
    event DepositReceived(address indexed From, uint Amount);
    event ProposalCloned(uint indexed LastClientProposalID, uint indexed ProposalID, uint Amount, string Description, bytes32 HashOfTheDocument);
    event ClientUpdated(address LastClient, address NewClient);
    event RecipientUpdated(address LastRecipient, address NewRecipient);
    event ProposalAdded(uint indexed ProposalID, uint Amount, string Description, bytes32 HashOfTheDocument);
    event Order(uint indexed clientProposalID, uint indexed ProposalID, uint Amount);
    event Withdawal(address indexed Recipient, uint Amount);

}    

contract PassManager is PassManagerInterface, PassTokenManager {

    function PassManager(
        address _client,
        address _recipient,
        address _clonedFrom,
        string _tokenName,
        string _tokenSymbol,
        uint8 _tokenDecimals,
        bool _transferable
    ) PassTokenManager(
        msg.sender,
        _client,
        _recipient,
        _tokenName,
        _tokenSymbol,
        _tokenDecimals,
        _transferable
        ) {

        clonedFrom = _clonedFrom;            
        proposals.length = 1;

    }

    function receiveFees() payable onlyDao {
        FeesReceived(msg.sender, msg.value);
    }

    function receiveDeposit() payable onlyContractor {
        DepositReceived(msg.sender, msg.value);
    }

    function cloneProposal(
        uint _amount,
        string _description,
        bytes32 _hashOfTheDocument,
        uint _dateOfProposal,
        uint _lastClientProposalID,
        uint _orderAmount,
        uint _dateOfOrder
    ) {
            
        if (smartContractStartDate != 0 || recipient == 0) throw;
        
        uint _proposalID = proposals.length++;
        proposal c = proposals[_proposalID];

        c.amount = _amount;
        c.description = _description;
        c.hashOfTheDocument = _hashOfTheDocument; 
        c.dateOfProposal = _dateOfProposal;
        c.lastClientProposalID = _lastClientProposalID;
        c.orderAmount = _orderAmount;
        c.dateOfOrder = _dateOfOrder;
        
        ProposalCloned(_lastClientProposalID, _proposalID, c.amount, c.description, c.hashOfTheDocument);
            
    }

    function cloneTokens(
        uint _from,
        uint _to) {
        
        if (smartContractStartDate != 0) throw;

        PassManager _clonedFrom = PassManager(_clonedFrom);

        if (_from < 1 || _to > _clonedFrom.numberOfHolders()) throw;

        address _holder;

        for (uint i = _from; i <= _to; i++) {
            _holder = _clonedFrom.HolderAddress(i);
            if (balances[_holder] == 0) {
                createInitialTokens(_holder, _clonedFrom.balanceOf(_holder));
            }
        }

    }
    
    
    function updateClient(address _newClient) onlyClient {
        
        if (_newClient == 0 
            || _newClient == recipient) throw;

        ClientUpdated(client, _newClient);
        client = _newClient;        

    }

    function updateRecipient(address _newRecipient) onlyContractor {

        if (_newRecipient == 0 
            || _newRecipient == client) throw;

        RecipientUpdated(recipient, _newRecipient);
        recipient = _newRecipient;

    } 

    function buyShares() payable {
        buySharesFor(msg.sender);
    } 
    
    function buySharesFor(address _recipient) payable onlyDao {
        
        if (!FundingRules[0].publicCreation 
            || !createToken(_recipient, msg.value, now)) throw;

    }
   
    function newProposal(
        uint _amount,
        string _description, 
        bytes32 _hashOfTheDocument
    ) onlyContractor returns (uint) {

        uint _proposalID = proposals.length++;
        proposal c = proposals[_proposalID];

        c.amount = _amount;
        c.description = _description;
        c.hashOfTheDocument = _hashOfTheDocument; 
        c.dateOfProposal = now;
        
        ProposalAdded(_proposalID, c.amount, c.description, c.hashOfTheDocument);
        
        return _proposalID;
        
    }
    
    function order(
        uint _clientProposalID,
        uint _proposalID,
        uint _orderAmount
    ) external onlyClient returns (bool) {
    
        proposal c = proposals[_proposalID];
        
        uint _sum = c.orderAmount + _orderAmount;
        if (_sum > c.amount
            || _sum < c.orderAmount
            || _sum < _orderAmount) return; 

        c.lastClientProposalID =  _clientProposalID;
        c.orderAmount = _sum;
        c.dateOfOrder = now;
        
        Order(_clientProposalID, _proposalID, _orderAmount);
        
        return true;

    }

    function sendTo(
        address _recipient,
        uint _amount
    ) external onlyClient onlyDao returns (bool) {
    
        if (_recipient.send(_amount)) return true;
        else return false;

    }
   
    function withdraw(uint _amount) onlyContractor {
        if (!recipient.send(_amount)) throw;
        Withdawal(recipient, _amount);
    }
    
    function numberOfProposals() constant returns (uint) {
        return proposals.length - 1;
    }
    
}    
