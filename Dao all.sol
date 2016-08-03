/*
Basic, standardized Token contract with no "premine". Defines the functions to
check token balances, send tokens, send tokens on behalf of a 3rd party and the
corresponding approval process.
*/

contract TokenInterface {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    /// Total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);
    
    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    
    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    /// its behalf
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _amount) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    /// to spend
    function allowance(
        address _owner,
        address _spender
    ) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
    );
}

contract Token is TokenInterface {
    // Protects users by preventing the execution of method calls that
    // inadvertently also transferred ether
    modifier noEther() {if (msg.value > 0) throw; _}

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) noEther returns (bool success) {
        if (balances[msg.sender] >= _amount && _amount > 0) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
           return false;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) noEther returns (bool success) {

        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0) {

            balances[_to] += _amount;
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

/*
This file is part of the DAO.

The DAO is free software: you can redistribute it and/or modify
it under the terms of the GNU lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The DAO is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the DAO.  If not, see <http://www.gnu.org/licenses/>.
*/


/*
 * Token Manager contract is used by the DAO for the management of tokens.
 * The tokens can be created by a crowdfunding or by a private funding
*/


contract TokenManagerInterface {

    address creator;
    
    struct fundingData {
        // True if crowdfunding
        bool publicTokenCreation; 
        // Minimum quantity of tokens to create
        uint256 minTokensToCreate; 
        // Maximum quantity of tokens to create
        uint256 maxTokensToCreate; 
        // Start time of the funding
        uint startTime; 
        // Closing time of the funding
        uint closingTime;  
        // The price (in wei) for a token without considering the inflation rate
        uint TokenPrice;
        // Rate per year applied to the token price 
        uint inflationRate; 
        // True if the funding is fueled
        bool isFueled;
    } fundingData public FundingRules;

    // Current total supply
    uint256 public totalSupply;
    // Map to allow token holder to refund if the funding didn't succeed
    mapping (address => uint256) weiGiven;
/*
    /// @dev The constructor function
    /// @param _creator The contract wich created the token manager
    /// @param _publicTokenCreation True if public
    /// @param _initialTokenPrice Price without considering any inflation rate
    /// @param _minTokensToCreate Minimum quantity of tokens to fuel the funding
    /// @param _maxTokensToCreate If the maximum is reached, the funding is closed
    /// @param _startTime The start time of the funding
    /// @param _closingTime After this date, the funding is closed
    /// @param _inflationRate If 0, the token price doesn't change during the funding
    /// @param _initialSupplyRecipient The address of recipient if there is an initial supply
    /// @param _initialSupply The quantity of tokens created before funding
    function TokenManager(
        address _creator, 
        bool _publicTokenCreation, 
        uint _initialTokenPrice, 
        uint256 _minTokensToCreate, 
        uint256 _maxTokensToCreate, 
        uint _startTime, 
        uint _closingTime,
        uint _inflationRate,
        address _initialSupplyRecipient, 
        uint256 _initialSupply
    );

    /// @notice Function to extent funding. Can be private or public
    /// @param _publicTokenCreation True if public
    /// @param _initialTokenPrice Price without considering any inflation rate
    /// @param _minTokensToCreate Minimum quantity of tokens to fuel the funding
    /// @param _maxTokensToCreate If the maximum is reached, the funding is closed
    /// @param _startTime If 0, the start time is the creation date of this contract
    /// @param _closingTime After this date, the funding is closed
    /// @param _inflationRate If 0, the token price doesn't change during the funding
    function extentFunding(
        bool _publicTokenCreation, 
        uint _initialTokenPrice, 
        uint256 _minTokensToCreate, 
        uint256 _maxTokensToCreate, 
        uint _startTime, 
        uint _closingTime, 
        uint _inflationRate
    ) onlyCreator;

    /// @notice Function to buy tokens in case of crowdfunding
    /// @param _tokenHolder The address of the token holder
    function buyToken(address _tokenHolder) 
    onlyPublicTokenCreation;

    /// @notice In case of private funding the creator can rewards tokens to the funders
    /// @param _tokenHolder The address of the token holder
    /// @param _amount The funded amount (in wei)
    /// @return Whether the transfer was successful or not    
    function rewardToken(address _tokenHolder, uint _amount) 
    onlyCreator external returns (bool success);
    
    /// @notice Internal function to create tokens
    /// @param _tokenHolder The address of the token holder
    /// @param _amount The funded amount (in wei)
    /// @return Whether the token creation was successful
    function createToken(
        address _tokenHolder, 
        uint _amount
        ) internal returns (bool success);    

    /// @notice Function to allow msg.sender to refund if the funding didn't succeed    
    function refund();

    /// @notice Internal function to get the actual token price    
    /// @return The actual token price considering the inflation rate 
    function tokenPrice() internal returns (uint tokenPrice);
*/
    // modifier to allow only the creator of the private funding to mint tokens
    modifier onlyCreator {if (msg.sender != address(creator)) throw; _ }
    // modifier to allow public to fund only in case of crowdfunding
    modifier onlyPublicTokenCreation {if (!FundingRules.publicTokenCreation) throw; _ }
    // modifier to allow partners to fund only in case of private funding
    modifier onlyPrivateTokenCreation {if (FundingRules.publicTokenCreation) throw; _ }

    event TokensCreated(address indexed tokenHolder, uint quantity);
    event FuelingToDate(uint value);
    event CreatedToken(address indexed to, uint amount);
    event Refund(address indexed to, uint value);
    
}

contract TokenManager is Token, TokenManagerInterface {

// Modifier that allows only shareholders to vote and create new proposals
modifier onlyTokenholders {if (balances[msg.sender] == 0) throw; _ }

    function TokenManager(
        address _creator, 
        bool _publicTokenCreation, 
        uint _initialTokenPrice, 
        uint256 _minTokensToCreate, 
        uint256 _maxTokensToCreate, 
        uint _startTime, 
        uint _closingTime,
        uint _inflationRate,
        address _initialSupplyRecipient, 
        uint256 _initialSupply
    ) {
        creator = _creator;

        FundingRules.startTime = _startTime;
        FundingRules.publicTokenCreation = _publicTokenCreation;
        FundingRules.closingTime = _closingTime; 
        FundingRules.minTokensToCreate = _minTokensToCreate; 
        FundingRules.maxTokensToCreate = _maxTokensToCreate;
        FundingRules.TokenPrice = _initialTokenPrice; 
        FundingRules.inflationRate = _inflationRate;  

        balances[_initialSupplyRecipient]=_initialSupply; 
        totalSupply=_initialSupply;

    }


    function extentFunding(
        bool _publicTokenCreation, 
        uint _initialTokenPrice, 
        uint256 _minTokensToCreate, 
        uint256 _maxTokensToCreate, 
        uint _startTime, 
        uint _closingTime, 
        uint _inflationRate
    ) onlyCreator noEther {

        FundingRules.publicTokenCreation = _publicTokenCreation;
        FundingRules.startTime = _startTime;
        FundingRules.closingTime = _closingTime; 
        FundingRules.minTokensToCreate = totalSupply + _minTokensToCreate; 
        FundingRules.maxTokensToCreate = totalSupply + _maxTokensToCreate;
        FundingRules.TokenPrice = _initialTokenPrice; 
        FundingRules.inflationRate = _inflationRate;  
    }


    function buyToken(address _tokenHolder) 
    onlyPublicTokenCreation {
        
        if (!createToken(_tokenHolder, msg.value)) throw;
        weiGiven[_tokenHolder] += msg.value;

    }

    
    function rewardToken(
        address _tokenHolder, 
        uint _amount
        ) onlyCreator noEther external returns (bool success) {
        
        return createToken(_tokenHolder, _amount);

    }


    function createToken(
        address _tokenHolder, 
        uint _amount
        ) internal returns (bool success) {

        uint quantity = _amount/tokenPrice();

        if ((totalSupply + quantity > FundingRules.maxTokensToCreate)
            || (now > FundingRules.closingTime) 
            || _amount <= 0
            || (now < FundingRules.startTime) ) {
            throw;
            }

        balances[_tokenHolder] += quantity; 
        totalSupply += quantity;
        TokensCreated(_tokenHolder, quantity);
        
        if (totalSupply == FundingRules.maxTokensToCreate) {
            FundingRules.closingTime = now;
        }

        if (totalSupply >= FundingRules.minTokensToCreate 
        && !FundingRules.isFueled) {
            FundingRules.isFueled = true; 
            FuelingToDate(totalSupply);
        }

        return true;
    }
    

    function refund() onlyTokenholders noEther {
        if (!FundingRules.isFueled && now > FundingRules.closingTime) {
            if (msg.sender.call.value(weiGiven[msg.sender])()) {
                 Refund(msg.sender, weiGiven[msg.sender]);
                totalSupply -= balances[msg.sender];
                balances[msg.sender] = 0; weiGiven[msg.sender] = 0;
            }
        }
        else throw;
    }
    

    function tokenPrice() internal returns (uint tokenPrice) {
        return (1 + (FundingRules.inflationRate) * (now - FundingRules.startTime)/(100*365 days)) * FundingRules.TokenPrice;
    }
    
}    
  

/*
This file is part of the DAO.

The DAO is free software: you can redistribute it and/or modify
it under the terms of the GNU lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The DAO is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the DAO.  If not, see <http://www.gnu.org/licenses/>.
*/


/*
Smart contract for a Decentralized Autonomous Organization (DAO)
to automate organizational governance and decision-making.
*/


contract DAOInterface {

    struct recipientData {
        // Address of the curator who checked the idendity of the recipient
        address curator; 
        // True if the idendity of the recipient has been checked
        bool isChecked;  
        // Deposit received when creating a new proposal and paid when checking the recipient
        uint depositForCurator;
        // Number used to identify the recipient
        uint ID; 
        // Name of the recipient
        string name;  
        // Physical addrees of the recipient
        bool hasATokenManager; 
        // The token management contract of the recipient
        TokenManager tokenManager; 
    }
    
    struct BoardMeeting {        
        // Address who created the board meeting for a proposal
        address creator;  
        // Index to identify the proposal to pay a contractor
        uint ContractorProposalID;
        // Index to identify the proposal to update the Dao rules 
        uint DaoRulesProposalID; 
        // Index to identify the proposal to a private funding of the Dao
        uint privateFundingProposalID;
        // Index to identify the proposal to a public funding for the Dao
        uint publicFundingProposalID;
        // unix timestamp, denoting the end of the set period
        uint setDeadline;
        // The deposit (in wei) required to submit the board meeting
        uint deposit; 
        // Fees (in wei) paid by the creator of the board meeting
        uint fees; 
        // Fees (in wei) rewarded to the voters
        uint totalRewardedAmount;
        // A unix timestamp, denoting the end of the voting period
        uint votingDeadline;
        // True if the proposal's votes have yet to be counted, otherwise False
        bool open; 
        // A unix timestamp, denoting the date of the execution of the voted procedure
        uint dateOfExecution;
        // Number of shares in favor of the proposal
        uint yea; 
        // Number of shares opposed to the proposal
        uint nay; 
        // mapping to check if a shareholder has voted
        mapping (address => bool) hasVoted;  
    }

    struct ContractorProposal {
        // Index to identify the board meeting of the proposal
        uint BoardMeetingID;
        // The address of the proposal creator where the `amount` will go to if the proposal is accepted
        address recipient;
        // The amount to transfer to `recipient` if the proposal is accepted.
        uint amount; 
        // The hash of the proposal's document
        bytes32 hashOfTheDocument;
        // The price (in wei) of a contractor token
        uint tokenPrice;  
        // The initial supply of contractor tokens for the recipient
        uint256 initialSupply; 
        // Period for voters to recieve contractor tokens after the execution of the proposal
        uint minutesRewardPeriod;
        // The number of shares of the voters allow them to recieve contractor tokens
        mapping (address => uint) weightToRecieve;
        // The total number of shares of the voters of the contractor proposal
        uint totalWeight; 
    }
    
    struct PrivateFundingProposal {
        // Index to identify the board meeting of the proposal
        uint BoardMeetingID;
        // The address of the creator of the proposal
//        address creator; 
        // The amount to fund
        uint fundingAmount; 
        // The price (in wei) for a token
        uint tokenPrice; 
        // Period for the partners to fund after the execution of the decision
        uint minutesFundingPeriod;
        // The total weight of partners if private funding
        uint totalWeight; 
        // The weight of a partner if private funding
        mapping (address => uint) weight; 
        // True if the partner has funded for private funding
        mapping (address => bool) hasFunded;
        // The total funded amount (in wei) if private funding
        uint totalFunded; 
    }
    
    struct PublicFundingProposal { 
        // Index to identify the board meeting of the proposal
        uint BoardMeetingID;
        // The address of the 'partners' if private funding
        uint startTime;
        // Closing time of the funding
        uint closingTime;
        // The minimum quantity of tokens to create for public funding
        uint minTokensToCreate; 
        // The maximum quantity of tokens to create for public funding
        uint maxTokensToCreate; 
        // The price (in wei) for a token without considering the inflation rate
        uint initialTokenPrice; 
        // Rate per year applied to the token price for public funding
        uint inflationRate;
    }

    struct Rules {
        // Address of the curator
        address curator; 
        // Index to identify the board meeting which decided to apply the rules
        uint BoardMeetingID;  
        // The quorum needed for each proposal is calculated by totalSupply / minQuorumDivisor
        uint minQuorumDivisor;  
        // The minimum debate period that a generic proposal can have
        uint minMinutesDebatePeriod; 
        // The maximum debate period that a generic proposal can have
        uint maxMinutesDebatePeriod;
        // Minimal fees (in wei) to create a board meeting for contractor and private funding proposals
        uint minBoardMeetingFees; 
        // Deposit returned to the creator of a proposal if the quorum is reached
        uint boardMeetingDeposit;  
        // Period after which a proposal is closed
        uint executeMinutesProposalPeriod;
        // Fees (in wei) paid to the curator when checking the identity of a contractor or private funding creator
        uint curatorFees; 
        // Period needed for the curator to check the idendity of a contractor or private funding creator
        uint minMinutesIdentityCheckingPeriod; 
    } 
        
    // Board meetings to decide the result of a proposal
    BoardMeeting[] public BoardMeetings; 
    // Proposals to pay a contractor
    ContractorProposal[] public ContractorProposals;
    // Proposals for a private funding of the Dao
    PrivateFundingProposal[] public PrivateFundingProposals;
    // Proposals for a public funding of the Dao
    PublicFundingProposal[] public PublicFundingProposals;
    // Proposals to update the Dao Rules
    Rules[] public DaoRulesProposals;
    // The current Dao rules
    Rules public DaoRules; 

    // Map of addresses blocked during a vote. The address points to the proposal ID
    mapping (address => uint) public blocked; 
    // Map of recipients to identify them
    mapping (address => recipientData) public recipientIdentity; 

    // the accumulated sum of all current proposal deposits and not rewarded boarding fees
    uint sumOfDeposits; 

    // Modifier that allows only curator to check the identity of a contractor or private funding creator
    modifier onlyCurator {if (msg.sender != address(DaoRules.curator)) throw; _ } 
    

/*
    /// @dev The constructor function
    /// @param _curator The address of the curator
    /// @param _minQuorumDivisor If 5, the minimum quorum is 20%
    /// @param _boardMeetingDeposit The deposit to be send by the creator of a Dao rules or public funding proposal
    /// @param _minMinutesDebatePeriod The minimum period in minutes of the board meeting
    /// @param _maxMinutesDebatePeriod The maximum period in minutes of the board meeting
    /// @param _curatorFees The amount for the curator to identify a recipient or a private funding creator
    /// @param _minMinutesIdentityCheckingPeriod The period needed for the curator to check a recipient or a private funding creator
    /// @param _minBoardMeetingFees The amount in wei for the voters to vote during a board meeting
    /// @param _executeMinutesProposalPeriod The period in minutes to execute a decision after a board meeting
    /// @param _publicTokenCreation True if the funding of the Dao is public
    /// @param _initialTokenPrice Price without considering any inflation rate
    /// @param _minTokensToCreate Minimum quantity of tokens to fuel the funding
    /// @param _maxTokensToCreate If the maximum is reached, the funding is closed
    /// @param _startTime If 0, the start time is the creation date of this contract
    /// @param _closingTime After this date, the funding is closed
    /// @param _inflationRate If 0, the token price doesn't change during the funding
    function DAO(
        address _curator, 
        uint _minQuorumDivisor, 
        uint _boardMeetingDeposit,
        uint _minMinutesDebatePeriod, 
        uint _maxMinutesDebatePeriod, 
        uint _curatorFees,
        uint _minMinutesIdentityCheckingPeriod,
        uint _minBoardMeetingFees,
        uint _executeMinutesProposalPeriod, 
        bool _publicTokenCreation, 
        uint _initialTokenPrice, 
        uint256 _minTokensToCreate, 
        uint256 _maxTokensToCreate, 
        uint _startTime, 
        uint _closingTime, 
        uint _inflationRate
    );
    
    /// @notice This function allows to buy tokens with `msg.sender` as the beneficiary during the crowdfunding
    function ();
    
    /// @notice Curator function to check the identity of a third party
    /// @param _thirdParty The address to be checked
    /// @param _ID A code to identify the third party
    /// @param _name of the third party
    function setRecipientData(
        address _thirdParty, 
        uint _ID, 
        string _name 
    ) onlyCurator;

    /// @notice Function to make a proposal to be a contractor of the Dao
    /// @param _amount The amount to be sent if the proposal is approved
    /// @param _description String describing the proposal
    /// @param _hashOfTheDocument The hash to identify the proposal document
    /// @param _TokenPrice The quantity of contractor tokens will depend on this price
    /// @param _initialSupply If the recipient ask for an initial supply of contractor tokens
    /// Default and minimum value is the period for curator to check the identity of the recipient
    /// @param _minutesRewardPeriod Period for the voters to recieve contractor tokens after the payment of the amount
    /// @param _MinutesDebatingPeriod Proposed period of the board meeting
    function newContractorProposal(
        uint _amount, 
        string _description, 
        bytes32 _hashOfTheDocument,
        uint _TokenPrice, 
        uint256 _initialSupply,
        uint _minutesRewardPeriod,
        uint _MinutesDebatingPeriod
    );

    /// @notice Function to make a proposal for a private funding of the Dao
    /// @param _fundingAmount The maximum amount to fund
    /// @param _tokenPrice The quantity of created tokens will depend on this price
    /// @param _minutesFundingPeriod Period for the partners to fund the Dao after the board meeting decision
    /// @param _MinutesDebatingPeriod Proposed period of the board meeting
    function newPrivateFundingProposal(
        uint _fundingAmount, 
        uint _tokenPrice,    
        uint _minutesFundingPeriod,
        uint _MinutesDebatingPeriod
    );

    /// @notice Function to make a proposal for a public funding of the Dao
    /// @param _startTime If 0, the start time is the date 
    /// of the board meeting decision
    /// @param _closingTime After this date, the funding is closed
    /// @param _initialTokenPrice Price without considering any inflation rate
    /// @param _minTokensToCreate Minimum quantity of tokens to fuel the funding
    /// @param _maxTokensToCreate If the maximum is reached, 
    /// the funding is closed
    /// @param _MinutesDebatingPeriod Proposed period of the board meeting
    /// @param _inflationRate If 0, the token price doesn't change 
    /// during the funding
    function newPublicFundingProposal(
        uint _startTime,
        uint _closingTime,
        uint _initialTokenPrice,    
        uint _minTokensToCreate,
        uint _maxTokensToCreate,
        uint _MinutesDebatingPeriod,
        uint _inflationRate
    );

    /// @notice Function to make a proposal to change the Dao rules 
    /// @param _curator The address of the curator
    /// @param _minQuorumDivisor If 5, the minimum quorum is 20%
    /// @param _boardMeetingDeposit The deposit to be send by the creator 
    /// of a Dao rules or public funding proposal
    /// @param _minMinutesDebatePeriod The minimum period in minutes 
    /// of the board meeting
    /// @param _maxMinutesDebatePeriod The maximum period in minutes 
    /// of the board meeting
    /// @param _curatorFees The amount for the curator to identify a recipient 
    /// or a private funding creator
    /// @param _minMinutesIdentityCheckingPeriod The period needed for the 
    /// curator to check a recipient or a private funding creator
    /// @param _minBoardMeetingFees The amount in wei for the voters to vote 
    /// during a board meeting
    /// @param _executeMinutesProposalPeriod The period in minutes to execute 
    /// a decision after a board meeting
    /// @param _MinutesDebatingPeriod Proposed period of the board meeting
    function newDaoRulesProposal(
        address _curator,
        uint _minQuorumDivisor, 
        uint _boardMeetingDeposit,
        uint _minMinutesDebatePeriod, 
        uint _maxMinutesDebatePeriod,
        uint _curatorFees,
        uint _minMinutesIdentityCheckingPeriod,
        uint _minBoardMeetingFees,
        uint _executeMinutesProposalPeriod,
        uint _MinutesDebatingPeriod
    );

    /// @notice Function to set the partner and their funding amount's share 
    /// in case of private funding proposal
    /// @param _PrivateFundingProposalID The index of the proposal
    /// @param _partner The address of the partner
    /// @param _quantity The share of the partner
    /// @return Whether the transfer was successful or not    
    function setPartner(
        uint _PrivateFundingProposalID, 
        address _partner, 
        uint _quantity
    ) returns (bool success);

    /// @notice Function to extent the set period before a board meeting
    /// @param _BoardMeetingID The index of the board meeting
    /// @param _MinutesProposalPeriod The period to extent
    function extentSetPeriod(
        uint _BoardMeetingID,
        uint  _MinutesProposalPeriod);
        
    /// @notice Function to vote during a board meeting
    /// @param _BoardMeetingID The index of the board meeting
    /// @param _supportsProposal True if the proposal is supported
    /// @return Whether the transfer was successful or not    
    function vote(
        uint _BoardMeetingID, 
        bool _supportsProposal
    ) returns (bool _success);

    /// @notice Function to executes a board meeting decision
    /// @param _BoardMeetingID The index of the board meeting
    /// @return Whether the transfer was successful or not    
    function executeDecision(uint _BoardMeetingID) returns (bool _success);

    /// @notice Function for the partners to fund the Dao 
    /// according to their funding amount's share
    /// @param _PrivateFundingProposalID The index of the proposal
    /// @return Whether the transfer was successful or not    
    function fund(uint _PrivateFundingProposalID) returns (bool _success);

    /// @notice Function for voters to recieve contractor tokens 
    /// after the execution of the contractor proposal,
    /// @param _contractorProposalID The index of the proposal
    /// @return Whether the transfer was successful or not    
    function RecieveContractorTokens(uint _contractorProposalID) returns (bool);

    /// @notice Interface function for a partner to get the funding amount 
    /// the partner can pay in case of private funding
    /// @param _PrivatefundingProposalID THe index of the proposal
    /// @param _partner address of the partner
    /// @return The amount to fund in wei
    function getFundingAmount(
        uint _PrivatefundingProposalID, 
        address _partner
    ) constant returns (uint);

    //// @dev internal function to close a board meeting
    /// @param _boardMeeting THe index of the proposal
    function closeBoardMeeting(uint _boardMeetingID);
   
    /// @notice Interface function to get the number of meetings 
    /// @return the number of meetings (passed or current)
    function getNumberOfMeetings() constant returns (uint);

    /// @notice Interface function to get the balance of the Dao 
    /// after considering all the deposits
    /// @return the balance
    function actualBalance() constant returns (uint);

    /// @dev internal function to create a board meeting
    /// @param _ContractorProposalID The index of the proposal if contractor
    /// @param _DaoRulesProposalID The index of the proposal if Dao rules
    /// @param _privateFundingProposalID The index of the proposal if private funding
    /// @param _publicFundingProposalID The index of the proposal if public funding
    /// @param _setdeadline The unix start date of the meating
    /// @param _MinutesDebatingPeriod The duration of the meeting
    /// @param _boardMeetingFees The fees rewrded to the voters by the creator of the proposal 
    /// @param _boardMeetingDeposit The deposit if public funding or Dao rules proposal
    /// @return the index of the board meeting
    function newBoardMeeting(
        uint _ContractorProposalID, 
        uint _DaoRulesProposalID, 
        uint _privateFundingProposalID, 
        uint _publicFundingProposalID, 
        uint _setdeadline, 
        uint _MinutesDebatingPeriod, 
        uint _boardMeetingFees,
        uint _boardMeetingDeposit
    ) internal returns (uint);

    /// @dev internal function to return deposit to the recipient if the curator didn't check his identity
    /// @param _BoardMeetingID The index of the board meeting
    /// @return True if not set
    function returnDepositsifnotSet(uint _BoardMeetingID) 
    internal returns (bool);

    /// @dev internal function to get the minimum quorum needed for a proposal    
    /// @return The minimum quorum for the proposal to pass 
    function minQuorum() internal constant returns (uint _minQuorum);

    /// @dev internal function to know if the shareholder account is blocked    
    /// @param _account The address of the account which is checked.
    /// @return Whether the account is blocked (not allowed to transfer tokens) or not.
    function isBlocked(address _account) internal returns (bool);
*/
    event RecipientIdentityChecked(address curator, address recipient);
    event newBoardMeetingAdded(uint indexed BoardMeetingID, uint setDeadline, uint votingDeadline);
    event TokenManagerCreated(address recipient, address TokenManagerAddress);
    event BoardMeetingDelayed(uint _BoardMeetingID, uint _MinutesProposalPeriod);
    event Voted(uint indexed proposalID, bool position, address voter, uint rewardedAmount);
    event ProposalTallied(uint indexed proposalID);
    event NewTokenManagerAccount(address TokenManagerAddress);
    event BoardMeetingCanceled(uint indexed BoardMeetingID);
    event CuratorUpdated(address _from, address _to);
    event BoardMeetingClosed(uint indexed BoardMeetingID);
    event TokensRecieved(uint indexed contractorProposalID, address Tokenholder, uint amount);

}

contract DAO is DAOInterface, TokenManager 
{

    function DAO(
        address _curator, 
        uint _minQuorumDivisor, 
        uint _boardMeetingDeposit,
        uint _minMinutesDebatePeriod, 
        uint _maxMinutesDebatePeriod, 
        uint _curatorFees,
        uint _minMinutesIdentityCheckingPeriod,
        uint _minBoardMeetingFees,
        uint _executeMinutesProposalPeriod, 
        bool _publicTokenCreation, 
        uint _initialTokenPrice, 
        uint256 _minTokensToCreate, 
        uint256 _maxTokensToCreate, 
        uint _startTime, 
        uint _closingTime, 
        uint _inflationRate
    ) TokenManager(address(this), _publicTokenCreation, _initialTokenPrice, _minTokensToCreate, 
        _maxTokensToCreate, _startTime, _closingTime, _inflationRate, 0, 0) 
        {

        DaoRules.curator = _curator;
        DaoRules.minQuorumDivisor = _minQuorumDivisor;
        DaoRules.minMinutesDebatePeriod = _minMinutesDebatePeriod;
        DaoRules.maxMinutesDebatePeriod = _maxMinutesDebatePeriod;
        DaoRules.minBoardMeetingFees = _minBoardMeetingFees;
        DaoRules.executeMinutesProposalPeriod = _executeMinutesProposalPeriod;
        DaoRules.curatorFees = _curatorFees;
        DaoRules.boardMeetingDeposit = _boardMeetingDeposit;
        DaoRules.minMinutesIdentityCheckingPeriod = _minMinutesIdentityCheckingPeriod;

        BoardMeetings.length = 1; 
        ContractorProposals.length = 1;
        DaoRulesProposals.length = 1;
        PrivateFundingProposals.length = 1;
        PublicFundingProposals.length = 1;

    }


    function () {buyToken(msg.sender);}


    function setRecipientData(
        address _thirdParty, 
        uint _ID, 
        string _name 
    ) onlyCurator noEther {

        recipientIdentity[_thirdParty].curator = msg.sender;
        recipientIdentity[_thirdParty].isChecked = true;
        recipientIdentity[_thirdParty].ID = _ID;
        recipientIdentity[_thirdParty].name = _name;

        uint _deposit = recipientIdentity[_thirdParty].depositForCurator;
        if (_deposit > 0) {
            if (!msg.sender.send(_deposit)) throw;
            sumOfDeposits -= _deposit;
            recipientIdentity[_thirdParty].depositForCurator = 0;
        }
        RecipientIdentityChecked(msg.sender, _thirdParty);
    }
    
    
    function newContractorProposal(
        uint _amount, 
        string _description, 
        bytes32 _hashOfTheDocument,
        uint _TokenPrice, 
        uint256 _initialSupply,
        uint _minutesRewardPeriod,
        uint _MinutesDebatingPeriod
    ) {

        if (msg.value < DaoRules.minBoardMeetingFees + DaoRules.curatorFees) throw;

        uint _ContractorProposalID = ContractorProposals.length++;
        ContractorProposal c = ContractorProposals[_ContractorProposalID];

        c.recipient = msg.sender; 

        recipientIdentity[c.recipient].depositForCurator = DaoRules.curatorFees;
        sumOfDeposits += DaoRules.curatorFees;
        recipientIdentity[c.recipient].isChecked = false;

        c.BoardMeetingID = newBoardMeeting(_ContractorProposalID, 0, 0, 0, 
        now + (DaoRules.minMinutesIdentityCheckingPeriod * 1 minutes), _MinutesDebatingPeriod, msg.value - DaoRules.curatorFees, 0);    
        
        c.amount = _amount;
        c.hashOfTheDocument = _hashOfTheDocument; 
        c.minutesRewardPeriod = _minutesRewardPeriod;
        c.tokenPrice = _TokenPrice;
        c.initialSupply = _initialSupply;
    }


    function newPrivateFundingProposal(
        uint _fundingAmount, 
        uint _tokenPrice,    
        uint _minutesFundingPeriod,
        uint _MinutesDebatingPeriod
    ) {

        if (msg.value < DaoRules.minBoardMeetingFees + DaoRules.curatorFees) throw;
        
        uint _PrivateFundingProposalID = PrivateFundingProposals.length++;
        PrivateFundingProposal f = PrivateFundingProposals[_PrivateFundingProposalID];

        recipientIdentity[msg.sender].isChecked = false;

        recipientIdentity[msg.sender].depositForCurator = DaoRules.curatorFees;
        sumOfDeposits += DaoRules.curatorFees;
        
        f.BoardMeetingID = newBoardMeeting(0, 0, _PrivateFundingProposalID, 0, 
        now + (DaoRules.minMinutesIdentityCheckingPeriod * 1 minutes),_MinutesDebatingPeriod, msg.value - DaoRules.curatorFees, 0);   
        
        f.fundingAmount = _fundingAmount;
        f.tokenPrice = _tokenPrice;
        f.minutesFundingPeriod = _minutesFundingPeriod;

    }


    function newPublicFundingProposal(
        uint _startTime,
        uint _closingTime,
        uint _initialTokenPrice,    
        uint _minTokensToCreate,
        uint _maxTokensToCreate,
        uint _MinutesDebatingPeriod,
        uint _inflationRate
    ) {

        if (msg.value < DaoRules.boardMeetingDeposit) throw;
        
        uint _PublicFundingProposalID = PublicFundingProposals.length++;
        PublicFundingProposal f = PublicFundingProposals[_PublicFundingProposalID];

        f.BoardMeetingID = newBoardMeeting(0, 0, 0, _PublicFundingProposalID, now, 
            _MinutesDebatingPeriod, msg.value - DaoRules.boardMeetingDeposit, DaoRules.boardMeetingDeposit);   
        
        f.startTime = _startTime;
        f.closingTime = _closingTime;
        f.initialTokenPrice = _initialTokenPrice;
        f.inflationRate = _inflationRate;
        f.minTokensToCreate = _minTokensToCreate;
        f.maxTokensToCreate = _maxTokensToCreate;
        
    }


    function newDaoRulesProposal(
        address _curator,
        uint _curatorFees,
        uint _minMinutesIdentityCheckingPeriod,
        uint _minQuorumDivisor, 
        uint _minBoardMeetingFees,
        uint _boardMeetingDeposit,
        uint _minMinutesDebatePeriod, 
        uint _maxMinutesDebatePeriod,
        uint _executeMinutesProposalPeriod,
        uint _MinutesDebatingPeriod
    ) {
    
        if (msg.value < DaoRules.boardMeetingDeposit) throw; 
        
        uint _DaoRulesProposalID = DaoRulesProposals.length++;
        Rules r = DaoRulesProposals[_DaoRulesProposalID];

        r.curator = _curator;
        r.minMinutesIdentityCheckingPeriod = _minMinutesIdentityCheckingPeriod;
        r.curatorFees = _curatorFees;
        r.minQuorumDivisor = _minQuorumDivisor;
        r.BoardMeetingID = newBoardMeeting(0, _DaoRulesProposalID, 0, 0, now, 
            _MinutesDebatingPeriod, msg.value - DaoRules.boardMeetingDeposit, DaoRules.boardMeetingDeposit);      
        r.minBoardMeetingFees = _minBoardMeetingFees;
        r.boardMeetingDeposit = _boardMeetingDeposit;
        r.minMinutesDebatePeriod = _minMinutesDebatePeriod;
        r.maxMinutesDebatePeriod = _maxMinutesDebatePeriod;
        r.executeMinutesProposalPeriod = _executeMinutesProposalPeriod;

    }
    
    
    function setPartner(
        uint _PrivateFundingProposalID, 
        address _partner, 
        uint _quantity
    ) noEther returns (bool success) {
        
        PrivateFundingProposal f = PrivateFundingProposals[_PrivateFundingProposalID];
        BoardMeeting p = BoardMeetings[f.BoardMeetingID];

        if (now > p.setDeadline 
            || msg.sender != address(p.creator)
            || !recipientIdentity[p.creator].isChecked
            || recipientIdentity[p.creator].ID == 0
            || _quantity <= 0
            ) { 
        throw;
        }
        
        f.weight[_partner] += _quantity; 
        f.totalWeight += _quantity;
        return true;
    }


    function extentSetPeriod(
        uint _BoardMeetingID,
        uint  _MinutesProposalPeriod) noEther {
        
        BoardMeeting p = BoardMeetings[_BoardMeetingID];
        if (now > p.setDeadline 
            || msg.sender != address(p.creator)) throw;
        
        p.setDeadline += _MinutesProposalPeriod * 1 minutes;
        p.votingDeadline += _MinutesProposalPeriod * 1 minutes;
        
        BoardMeetingDelayed(_BoardMeetingID, _MinutesProposalPeriod);
    }
        

    function vote(
        uint _BoardMeetingID, 
        bool _supportsProposal
    ) onlyTokenholders noEther returns (bool _success) {
            
        BoardMeeting p = BoardMeetings[_BoardMeetingID];
        if (p.hasVoted[msg.sender] 
            || now < p.setDeadline
            || now > p.votingDeadline 
            ||!p.open
        ) {
        throw;
        }

        if (p.ContractorProposalID != 0 || p.privateFundingProposalID != 0) {
            if (returnDepositsifnotSet(_BoardMeetingID)) return ;
        }

        if (p.fees > 0) {
            uint _rewardedamount = (uint(balances[msg.sender])*p.fees)/uint(totalSupply);
            if (!msg.sender.send(_rewardedamount)) throw;
            p.totalRewardedAmount += _rewardedamount;
            sumOfDeposits -= _rewardedamount;
        }

        if (_supportsProposal) {
            p.yea += balances[msg.sender];
        } 
        else {
            p.nay += balances[msg.sender]; 
        }

        if (p.ContractorProposalID != 0) {
            ContractorProposal c = ContractorProposals[p.ContractorProposalID];
            c.weightToRecieve[msg.sender] += balances[msg.sender]; 
            c.totalWeight += balances[msg.sender];
        }

        p.hasVoted[msg.sender] = true;

        if (blocked[msg.sender] == 0) {
            blocked[msg.sender] = _BoardMeetingID;
        }
        else if (p.votingDeadline > BoardMeetings[blocked[msg.sender]].votingDeadline) {
            blocked[msg.sender] = _BoardMeetingID;
        }

        Voted(_BoardMeetingID, _supportsProposal, msg.sender, _rewardedamount);
    }


    function executeDecision(uint _BoardMeetingID) noEther returns (bool _success) 
        {
        BoardMeeting p = BoardMeetings[_BoardMeetingID];

        if (now < p.votingDeadline
            || !p.open ) {
            throw;
        }
        
        uint quorum = p.yea + p.nay;
        
        if (p.deposit > 0
            && now > p.votingDeadline) {
                sumOfDeposits -= p.deposit;
                if (quorum >= minQuorum()) {
                    if (!p.creator.send(p.deposit)) throw;
                    p.deposit = 0;
                }
        }        
        
        if (now > p.votingDeadline + DaoRules.executeMinutesProposalPeriod * 1 minutes 
                    || now > p.votingDeadline && ( quorum < minQuorum() || p.yea < p.nay ) ) {
            p.open = false;
            return;
        }

        if (now > p.votingDeadline && ( quorum < minQuorum() || p.yea < p.nay )) {
            return;
        }
        
        if (p.privateFundingProposalID != 0) {
            PrivateFundingProposal pf = PrivateFundingProposals[p.privateFundingProposalID];
            this.extentFunding(false, pf.tokenPrice, 0, 
                pf.fundingAmount/pf.tokenPrice, now, now + pf.minutesFundingPeriod * 1 minutes, 0);
            
        }
        
        if (p.publicFundingProposalID != 0) {
            PublicFundingProposal cf = PublicFundingProposals[p.publicFundingProposalID];
            this.extentFunding(true, cf.initialTokenPrice, cf.minTokensToCreate, cf.maxTokensToCreate, cf.startTime, 
            cf.closingTime, cf.inflationRate);
        }

        if (p.ContractorProposalID != 0) {
            ContractorProposal c = ContractorProposals[p.ContractorProposalID];
            if (p.open && c.amount <= actualBalance()) {
                
                if (!c.recipient.send(c.amount)) throw;
                
                if (!recipientIdentity[c.recipient].hasATokenManager) {
                    TokenManager m = new TokenManager(address(this), false, 
                        c.tokenPrice, c.initialSupply, c.amount/c.tokenPrice + c.initialSupply, now, now + c.minutesRewardPeriod * 1 minutes,
                        0, c.recipient, c.initialSupply) ;
                    recipientIdentity[c.recipient].tokenManager = m;
                    TokenManagerCreated(c.recipient, address(m));
                    recipientIdentity[c.recipient].hasATokenManager = true;
                }
                else {
                    recipientIdentity[c.recipient].tokenManager.extentFunding(false, c.tokenPrice, c.initialSupply, 
                    c.amount/c.tokenPrice + c.initialSupply, now, now + c.minutesRewardPeriod * 1 minutes, 0);
                }
            }
        }
        
        if (p.DaoRulesProposalID != 0) {
            Rules r = DaoRulesProposals[p.DaoRulesProposalID];
            DaoRules.curator = r.curator;
            DaoRules.BoardMeetingID = r.BoardMeetingID;
            DaoRules.boardMeetingDeposit = r.boardMeetingDeposit;
            DaoRules.minQuorumDivisor = r.minQuorumDivisor;
            DaoRules.minMinutesDebatePeriod = r.minMinutesDebatePeriod;
            DaoRules.maxMinutesDebatePeriod = r.maxMinutesDebatePeriod;
            DaoRules.minBoardMeetingFees = r.minBoardMeetingFees;
            DaoRules.executeMinutesProposalPeriod = r.executeMinutesProposalPeriod;
            DaoRules.curatorFees = r.curatorFees;
            DaoRules.minMinutesIdentityCheckingPeriod = r.minMinutesIdentityCheckingPeriod;
        }
        
        _success = true; 
        p.dateOfExecution = now;

        takeBoardingFees(_BoardMeetingID);
        p.open = false;

        ProposalTallied(_BoardMeetingID);
    }


    function fund(uint _PrivateFundingProposalID) 
    onlyPrivateTokenCreation returns (bool _success) {
        
        PrivateFundingProposal f = PrivateFundingProposals[_PrivateFundingProposalID];
        BoardMeeting p = BoardMeetings[f.BoardMeetingID];

        if (p.dateOfExecution == 0 
            || f.hasFunded[msg.sender]
            || msg.value != getFundingAmount(_PrivateFundingProposalID, msg.sender)) {
            throw;
        }

        if (!createToken(msg.sender, msg.value)) throw;
        f.hasFunded[msg.sender] = true;
    }
    

    function RecieveContractorTokens(uint _contractorProposalID) 
    noEther returns (bool) {

        address _Tokenholder = msg.sender;

        ContractorProposal c = ContractorProposals[_contractorProposalID];
        BoardMeeting p = BoardMeetings[c.BoardMeetingID];
        
        if (now > p.dateOfExecution + c.minutesRewardPeriod * 1 minutes) {
            p.open = false;
            takeBoardingFees(c.BoardMeetingID);
            return;
        }

        if (p.dateOfExecution == 0 || c.weightToRecieve[_Tokenholder]==0) {throw; }
        
        uint _amount = c.amount*c.weightToRecieve[_Tokenholder]/c.totalWeight;

        TokenManager m =  recipientIdentity[c.recipient].tokenManager;
        if (!m.rewardToken(_Tokenholder, _amount)) throw;
        c.weightToRecieve[_Tokenholder] = 0;

        TokensRecieved(_contractorProposalID, _Tokenholder, _amount);

    }


    function transfer(address _to, uint256 _value) returns (bool success) {
        if (FundingRules.isFueled
            && now > FundingRules.closingTime
            && !isBlocked(msg.sender)
            && super.transfer(_to, _value)) {
                return true;
            } else {
            throw;
        }
    }


    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (FundingRules.isFueled
            && now > FundingRules.closingTime
            && !isBlocked(msg.sender)
            && super.transferFrom(_from, _to, _value)) {
            return true;
        } else {
            throw;
        }
    }


    function getFundingAmount(
        uint _PrivatefundingProposalID, 
        address _partner
    ) constant returns (uint) {

        PrivateFundingProposal f = PrivateFundingProposals[_PrivatefundingProposalID];
        BoardMeeting p = BoardMeetings[f.BoardMeetingID];

        return f.fundingAmount*f.weight[_partner]/f.totalWeight;
    }


    function takeBoardingFees(uint _boardMeetingID) {
        BoardMeeting p = BoardMeetings[_boardMeetingID];
        sumOfDeposits -= p.fees - p.totalRewardedAmount;
        p.totalRewardedAmount = p.fees;
        }
        

    function getNumberOfMeetings() constant returns (uint) {
        return BoardMeetings.length - 1;
    }
 

     function actualBalance() constant returns (uint) {
        return this.balance - sumOfDeposits;
    }
   

    function newBoardMeeting(
        uint _ContractorProposalID, 
        uint _DaoRulesProposalID, 
        uint _privateFundingProposalID, 
        uint _publicFundingProposalID, 
        uint _setdeadline, 
        uint _MinutesDebatingPeriod, 
        uint _boardMeetingFees,
        uint _boardMeetingDeposit
    ) internal returns (uint) {

        if (!FundingRules.isFueled
            || _MinutesDebatingPeriod > DaoRules.maxMinutesDebatePeriod 
            || _MinutesDebatingPeriod < DaoRules.minMinutesDebatePeriod) {
            throw;
        }

        uint _BoardMeetingID = BoardMeetings.length++;
        BoardMeeting p = BoardMeetings[_BoardMeetingID];

        p.creator = msg.sender;
        p.ContractorProposalID = _ContractorProposalID;
        p.DaoRulesProposalID = _DaoRulesProposalID;
        p.privateFundingProposalID = _privateFundingProposalID;
        p.publicFundingProposalID = _publicFundingProposalID;
        p.fees = _boardMeetingFees;
        p.deposit = DaoRules.boardMeetingDeposit;
        p.setDeadline =_setdeadline;        
        
        uint _DebatePeriod;
        if (_MinutesDebatingPeriod < DaoRules.minMinutesDebatePeriod) _DebatePeriod = DaoRules.minMinutesDebatePeriod; 
        else _DebatePeriod = _MinutesDebatingPeriod; 
        p.votingDeadline = _setdeadline + (_DebatePeriod * 1 minutes); 

        p.open = true; 
        
        sumOfDeposits += _boardMeetingFees + _boardMeetingDeposit;
        p.deposit = _boardMeetingDeposit;

        newBoardMeetingAdded(_BoardMeetingID, p.setDeadline, p.votingDeadline);
        return _BoardMeetingID;

    }


    function returnDepositsifnotSet(uint _BoardMeetingID) 
    internal returns (bool) {

        bool _isnotSet;
        BoardMeeting p = BoardMeetings[_BoardMeetingID];
        
       address _recipient;        
        if (p.ContractorProposalID != 0) {
            _recipient = ContractorProposals[p.ContractorProposalID].recipient;
        }
        else if (p.privateFundingProposalID != 0) {
            _recipient =  p.creator;
            if (PrivateFundingProposals[p.privateFundingProposalID].totalWeight == 0) {
                _isnotSet = true; 
            }
        }
        else return;

        uint _deposits = p.fees;
        
        if (!recipientIdentity[_recipient].isChecked) {
            _deposits += recipientIdentity[_recipient].depositForCurator;
            _isnotSet = true;
        }
        else
        if (recipientIdentity[_recipient].ID == 0) {
            _isnotSet = true;
        }

        if (_isnotSet) {
            if (!p.creator.send(_deposits)) throw;
            sumOfDeposits -= _deposits;
            p.open = false;
            return true;
        }
    }    


    function minQuorum() internal constant returns (uint _minQuorum) {
        return uint(totalSupply) / DaoRules.minQuorumDivisor;
    }
 

    function isBlocked(address _account) internal returns (bool) {
 
        if (blocked[_account] == 0) return false;
        
        BoardMeeting p = BoardMeetings[blocked[_account]];
        if (now > p.votingDeadline) {
            blocked[_account] = 0;
            return false;
        } else {
            return true;
        }
    }

}
