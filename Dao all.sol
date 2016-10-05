//Compiler version 0.3.6

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
 * The Account Manager smart contract is associated with a recipient 
 * (the Dao for dao shares and the recipient for contractor tokens) 
 * and used for the management of tokens by a client smart contract (the Dao)
*/

// import "Token.sol";

contract AccountManagerInterface {

    // Rules for the funding
    fundingData public FundingRules;
    struct fundingData {
        // The address which set partners in case of private funding
        address mainPartner;
        // True if crowdfunding
        bool publicTokenCreation; 
        // Minimum quantity of tokens to create
        uint256 minTotalSupply; 
        // Maximum quantity of tokens to create
        uint256 maxTotalSupply; 
        // Start time of the funding
        uint startTime; 
        // Closing time of the funding
        uint closingTime;  
        // The price (in wei) for a token without considering the inflation rate
        uint initialTokenPrice;
        // Rate per year applied to the token price 
        uint inflationRate; 
    } 

     // address of the Dao    
    address public client;
    // Address of the recipient
    address public recipient;

    // True if the funding is fueled
    bool isFueled;
   // If true, the tokens can be transfered
    bool public transferAble;
    // Total amount funded
    uint weiGivenTotal;

    // Map to allow token holder to refund if the funding didn't succeed
    mapping (address => uint256) weiGiven;
    // Map of addresses blocked during a vote. The address points to the proposal ID
    mapping (address => uint) blocked; 

    // Modifier that allows only the cient to manage tokens
    modifier onlyClient {if (msg.sender != address(client)) throw; _ }
    // modifier to allow public to fund only in case of crowdfunding
    modifier onlyRecipient {if (msg.sender != address(recipient)) throw; _ }
    // Modifier that allows public to buy tokens only in case of crowdfunding
    modifier onlyPublicTokenCreation {if (!FundingRules.publicTokenCreation) throw; _ }
    // Modifier that allows the main partner to buy tokens only in case of private funding
    modifier onlyPrivateTokenCreation {if (FundingRules.publicTokenCreation) throw; _ }

    event RecipientChecked(address curator);
    event TokensCreated(address indexed tokenHolder, uint quantity);
    event FuelingToDate(uint value);
    event CreatedToken(address indexed to, uint amount);
    event Refund(address indexed to, uint value);
    event Clientupdated(address newClient);

}

contract AccountManager is Token, AccountManagerInterface {


    // Modifier that allows only shareholders to vote and create new proposals
    modifier onlyTokenholders {if (balances[msg.sender] == 0) throw; _ }

    /// @dev Constructor setting the Client, Recipient and initial Supply
    /// @param _client The Dao address
    /// @param _recipient The recipient address
    /// @param _initialSupply The initial supply of tokens for the recipient
    function AccountManager(
        address _client,
        address _recipient,
        uint256 _initialSupply
    ) {
        client = _client;

        recipient = _recipient;

        balances[_recipient] = _initialSupply; 
        totalSupply =_initialSupply;
        TokensCreated(_recipient, _initialSupply);
        
   }

    /// @notice Create Token with `msg.sender` as the beneficiary in case of public funding
    function () {
        if (FundingRules.publicTokenCreation) {
            buyToken(msg.sender, msg.value);
        }
    }

    /// @notice Create Token with `_tokenHolder` as the beneficiary
    /// @param _tokenHolder the beneficiary of the created tokens
    /// @param _amount the amount funded
    /// @return Whether the transfer was successful or not
    function buyTokenFor(
        address _tokenHolder,
        uint _amount
        ) onlyPrivateTokenCreation returns (bool _succes) {
        
        if (msg.sender != FundingRules.mainPartner) throw;

        return buyToken(_tokenHolder, _amount);

    }
     
    /// @notice Create Token with `_tokenHolder` as the beneficiary
    /// @param _tokenHolder the beneficiary of the created tokens
    /// @param _amount the amount funded
    /// @return Whether the transfer was successful or not
    function buyToken(
        address _tokenHolder,
        uint _amount) internal returns (bool _succes) {
        
        if (createToken(_tokenHolder, _amount)) {
            weiGiven[_tokenHolder] += _amount;
            weiGivenTotal += _amount;
            return true;
        }
        else throw;

    }
    
    /// @notice Refund in case the funding is not fueled
    function refund() noEther {
        
        if (!isFueled && now > FundingRules.closingTime) {
 
            uint _amount = weiGiven[msg.sender];
            weiGiven[msg.sender] = 0;
            totalSupply -= balances[msg.sender];
            balances[msg.sender] = 0; 

            if (!msg.sender.send(_amount)) throw;

            Refund(msg.sender, _amount);

        }
    }

    /// @notice If the tokenholder account is blocked by a proposal whose voting deadline
    /// has exprired then unblock him.
    /// @param _account The address of the tokenHolder
    /// @return Whether the account is blocked (not allowed to transfer tokens) or not.
    function unblockAccount(address _account) noEther returns (bool) {
    
        uint _deadLine = blocked[_account];
        
        if (_deadLine == 0) return false;
        
        if (now > _deadLine) {
            blocked[_account] = 0;
            return false;
        } else {
            return true;
        }
    }

    /// @dev Function used by the client
    /// @return The total supply of tokens 
    function TotalSupply() external returns (uint256) {
        return totalSupply;
    }
    
    /// @dev Function used by the client
    /// @return Whether the funding is fueled or not
    function IsFueled() external constant returns (bool) {
        return isFueled;
    }

    function setMinTotalSupply(uint256 _minTotalSupply) external returns (uint) {
        FundingRules.minTotalSupply = _minTotalSupply; 
    }
        
    /// @dev Function used by the client
    /// @return The maximum tokens after the funding
    function MaxTotalSupply() external returns (uint) {
        return (FundingRules.maxTotalSupply);
    }
    
    /// @dev Function used by the client
    /// @return the actual token price condidering the inflation rate
    function tokenPrice() constant returns (uint) {
        if ((now > FundingRules.closingTime && FundingRules.closingTime !=0) 
            || (now < FundingRules.startTime) ) {
            return 0;
            }
        else
        return FundingRules.initialTokenPrice 
            + FundingRules.initialTokenPrice*(FundingRules.inflationRate)*(now - FundingRules.startTime)/(100*365 days);
    }

    /// @dev Function to extent funding. Can be private or public
    /// @param _publicTokenCreation True if public
    /// @param _initialTokenPrice Price without considering any inflation rate
    /// @param _maxTokensToCreate If the maximum is reached, the funding is closed
    /// @param _startTime If 0, the start time is the creation date of this contract
    /// @param _closingTime After this date, the funding is closed
    /// @param _inflationRate If 0, the token price doesn't change during the funding
    function extentFunding(
        address _mainPartner,
        bool _publicTokenCreation, 
        uint _initialTokenPrice, 
        uint256 _maxTokensToCreate, 
        uint _startTime, 
        uint _closingTime, 
        uint _inflationRate
    ) external onlyClient {

        FundingRules.mainPartner = _mainPartner;
        FundingRules.publicTokenCreation = _publicTokenCreation;
        FundingRules.startTime = _startTime;
        FundingRules.closingTime = _closingTime; 
        FundingRules.maxTotalSupply = totalSupply + _maxTokensToCreate;
        FundingRules.initialTokenPrice = _initialTokenPrice; 
        FundingRules.inflationRate = _inflationRate;  
        
    } 
        
    /// @dev Function used by the client to send ethers
    /// @param _recipient The address to send to
    /// @param _amount The amount to send
    function sendTo(
        address _recipient, 
        uint _amount
    ) external onlyClient {
        if (!_recipient.send(_amount)) throw;    
    }
    
    /// @dev Function used by the Dao to reward of tokens
    /// @param _tokenHolder The address of the token holder
    /// @param _amount The amount in Wei
    /// @return Whether the transfer was successful or not
    function rewardToken(
        address _tokenHolder, 
        uint _amount
        ) external returns (bool _success) {
        
        if (msg.sender != address(client) && msg.sender != FundingRules.mainPartner) {
            throw;
        }
        if (createToken(_tokenHolder, _amount)) return true;
        else throw;

    }

    /// @dev Function used by the client to block tokens transfer of from a tokenholder
    /// @param _account The address of the tokenHolder
    /// @return When the account can be unblocked
    function blockedAccountDeadLine(address _account) external constant returns (uint) {
        
        return blocked[_account];

    }
    
    /// @dev Function used by the client to block tokens transfer of from a tokenholder
    /// @param _account The address of the tokenHolder
    /// @param _deadLine When the account can be unblocked
    function blockAccount(address _account, uint _deadLine) external onlyClient {
        
        blocked[_account] = _deadLine;

    }
    
    /// @dev Function used by the client to able the transfer of tokens
    function TransferAble() external onlyClient {
        transferAble = true;
    }

    /// @dev Internal function for the creation of tokens
    /// @param _tokenHolder The address of the token holder
    /// @param _amount The funded amount (in wei)
    /// @return Whether the token creation was successful or not
    function createToken(
        address _tokenHolder, 
        uint _amount
    ) internal returns (bool _success) {

        uint _tokenholderID;
        uint _quantity = _amount/tokenPrice();

        if ((totalSupply + _quantity > FundingRules.maxTotalSupply)
            || (now > FundingRules.closingTime && FundingRules.closingTime !=0) 
            || _amount <= 0
            || (now < FundingRules.startTime) ) {
            throw;
            }

        balances[_tokenHolder] += _quantity; 
        totalSupply += _quantity;
        TokensCreated(_tokenHolder, _quantity);
        
        if (totalSupply == FundingRules.maxTotalSupply) {
            FundingRules.closingTime = now;
        }

        if (totalSupply >= FundingRules.minTotalSupply 
        && !isFueled) {
            isFueled = true; 
            FuelingToDate(totalSupply);
        }
        
        return true;
        
    }
   
    // Function transfer only if the funding is not fueled and the account is not blocked
    function transfer(
        address _to, 
        uint256 _value
        ) returns (bool success) {  

        if (isFueled
            && transferAble
            && blocked[msg.sender] == 0
            && blocked[_to] == 0
            && _to != address(this)
            && now > FundingRules.closingTime
            && super.transfer(_to, _value)) {
                return true;
            } else {
            throw;
        }

    }

    // Function transferFrom only if the funding is not fueled and the account is not blocked
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
        ) returns (bool success) {
        
        if (isFueled
            && transferAble
            && blocked[_from] == 0
            && blocked[_to] == 0
            && _to != address(this)
            && now > FundingRules.closingTime 
            && super.transferFrom(_from, _to, _value)) {
            return true;
        } else {
            throw;
        }
        
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

    struct BoardMeeting {        
        // Address who created the board meeting for a proposal
        address creator;  
        // Index to identify the proposal to pay a contractor
        uint ContractorProposalID;
        // Index to identify the proposal to update the Dao rules 
        uint DaoRulesProposalID; 
        // Index to identify the proposal to a private funding of the Dao
        uint FundingProposalID;
        // unix timestamp, denoting the end of the set period
        uint setDeadline;
        // Fees (in wei) paid by the creator of the board meeting
        uint fees; 
        // Fees (in wei) rewarded to the voters
        uint totalRewardedAmount;
        // A unix timestamp, denoting the end of the voting period
        uint votingDeadline;
        // True if the proposal's votes have yet to be counted, otherwise False
        bool open; 
        // A unix timestamp, denoting the date of the execution of the voted proposal
        uint dateOfExecution;
        // A unix timestamp, denoting the deadline to execution of the voted proposal 
        uint executionDeadline;
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
        // True if the proposal foreseen to reward tokens to voters
        bool rewardTokensToVoters;
        // The number of shares of the voters allow them to recieve contractor tokens
        mapping (address => uint) weightToRecieve;
        // The total number of shares of the voters of the contractor proposal
        uint totalWeight; 

    }
    
    struct FundingProposal {
        // The address which set partners in case of private funding
        address mainPartner;
        // True if crowdfunding
        bool publicTokenCreation; 
        // Index to identify the board meeting of the proposal
        uint BoardMeetingID;
        // The amount to fund
        uint fundingAmount; 
        // The price (in wei) for a token
        uint tokenPrice; 
        // Rate per year applied to the token price 
        uint inflationRate;
        // Period for the partners to fund after the execution of the decision
        uint minutesFundingPeriod;
    }

    struct Rules {
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
        // Period after which a proposal is closed
        uint minutesExecuteProposalPeriod;
        // Period needed for the curator to check the idendity of a contractor or private funding creator
        uint minMinutesSetPeriod; 
        // Address of the account manager of transferable tokens
        address tokenTransferAble;
    } 

    // The Dao account manager contract
    AccountManager public DaoAccountManager;

    // Map to check if a recipient has an account manager or not
    mapping (address => bool) hasAnAccountManager; 
    // The account management contract of the recipient
    mapping (address => AccountManager) public ContractorAccountManager; 

    // Board meetings to decide the result of a proposal
    BoardMeeting[] public BoardMeetings; 
    // Proposals to pay a contractor
    ContractorProposal[] public ContractorProposals;
    // Proposals for a funding of the Dao
    FundingProposal[] public FundingProposals;
   // Proposals to update the Dao Rules
    Rules[] public DaoRulesProposals;
    // The current Dao rules
    Rules public DaoRules; 
    
    bool mutex;

    event newBoardMeetingAdded(uint indexed BoardMeetingID, uint setDeadline, uint votingDeadline);
    event AccountManagerCreated(address recipient, address AccountManagerAddress);
    event BoardMeetingDelayed(uint _BoardMeetingID, uint _MinutesProposalPeriod);
    event Voted(uint indexed proposalID, bool position, address voter, uint rewardedAmount);
    event ProposalTallied(uint indexed proposalID);
    event NewTokenManagerAccount(address TokenManagerAddress);
    event BoardMeetingCanceled(uint indexed BoardMeetingID);
    event CuratorUpdated(address _from, address _to);
    event BoardMeetingClosed(uint indexed BoardMeetingID);
    event TokensBoughtFor(uint indexed contractorProposalID, address Tokenholder, uint amount);

}

/// @title Our Decentralized Autonomous Organisation
contract DAO is DAOInterface
{

    // Protects users by preventing the execution of method calls that
    // inadvertently also transferred ether
    modifier noEther() {if (msg.value > 0) throw; _}
    
    // Modifier that allows only shareholders to vote and create new proposals
    modifier onlyTokenholders {
        if (DaoAccountManager.balanceOf(msg.sender) == 0) throw; _}
    
    /// @dev The constructor function
    /// @param _minBoardMeetingFees The amount in wei for the voters to vote during a board meeting
    /// @param _minQuorumDivisor If 5, the minimum quorum is 20%
    /// @param _minMinutesDebatePeriod The minimum period in minutes of the board meeting
    /// @param _maxMinutesDebatePeriod The maximum period in minutes of the board meeting
    /// @param _minutesExecuteProposalPeriod The period in minutes to execute a decision after a board meeting    
    function DAO(
        uint _minBoardMeetingFees,
        uint _minQuorumDivisor, 
        uint _minMinutesDebatePeriod, 
        uint _maxMinutesDebatePeriod, 
        uint _minMinutesSetingPeriod,
        uint _minutesExecuteProposalPeriod,
        uint256 _minTotalSupply 
    ) {

        DaoAccountManager = new AccountManager(address(this), msg.sender, 10);

        DaoRules.minQuorumDivisor = _minQuorumDivisor;
        DaoRules.minMinutesDebatePeriod = _minMinutesDebatePeriod;
        DaoRules.maxMinutesDebatePeriod = _maxMinutesDebatePeriod;
        DaoRules.minBoardMeetingFees = _minBoardMeetingFees;
        DaoRules.minutesExecuteProposalPeriod = _minutesExecuteProposalPeriod;
        DaoRules.minMinutesSetPeriod = _minMinutesSetingPeriod;

        DaoAccountManager.setMinTotalSupply(_minTotalSupply);

        BoardMeetings.length = 1; 
        ContractorProposals.length = 1;
        FundingProposals.length = 1;
        DaoRulesProposals.length = 1;

    }
    
    /// @dev This function is to avoid tokenholders to send ethers to this address
    function () {throw;}

    /// @dev internal function to create a board meeting
    /// @param _ContractorProposalID The index of the proposal if contractor
    /// @param _DaoRulesProposalID The index of the proposal if Dao rules
    /// @param _FundingProposalID The index of the proposal if funding
    /// @param _setdeadline The unix start date of the meating
    /// @param _MinutesDebatingPeriod The duration of the meeting
    /// @param _boardMeetingFees The fees rewrded to the voters by the creator of the proposal 
    /// @return the index of the board meeting
    function newBoardMeeting(
        uint _ContractorProposalID, 
        uint _DaoRulesProposalID, 
        uint _FundingProposalID, 
        uint _setdeadline, 
        uint _MinutesDebatingPeriod, 
        uint _boardMeetingFees
    ) internal returns (uint) {

        if ((!DaoAccountManager.IsFueled() && DaoAccountManager.TotalSupply() > 1 finney)
            ||_MinutesDebatingPeriod > DaoRules.maxMinutesDebatePeriod 
            || _MinutesDebatingPeriod < DaoRules.minMinutesDebatePeriod) {
            throw;
        }

        uint _BoardMeetingID = BoardMeetings.length++;
        BoardMeeting p = BoardMeetings[_BoardMeetingID];

        p.creator = msg.sender;
        p.ContractorProposalID = _ContractorProposalID;
        p.DaoRulesProposalID = _DaoRulesProposalID;
        p.FundingProposalID = _FundingProposalID;
        p.fees = _boardMeetingFees;
        p.setDeadline =_setdeadline;        
        
        uint _DebatePeriod;
        if (_MinutesDebatingPeriod < DaoRules.minMinutesDebatePeriod) _DebatePeriod = DaoRules.minMinutesDebatePeriod; 
        else _DebatePeriod = _MinutesDebatingPeriod; 

        p.votingDeadline = _setdeadline + (_DebatePeriod * 1 minutes); 
        p.executionDeadline = p.votingDeadline + DaoRules.minutesExecuteProposalPeriod * 1 minutes;

        p.open = true; 

        newBoardMeetingAdded(_BoardMeetingID, p.setDeadline, p.votingDeadline);

        return _BoardMeetingID;

    }

    /// @notice Function to make a proposal to be a contractor of the Dao
    /// @param _amount The amount to be sent if the proposal is approved
    /// @param _description String describing the proposal
    /// @param _hashOfTheDocument The hash to identify the proposal document
    /// @param _TokenPrice The quantity of contractor tokens will depend on this price
    /// @param _initialSupply If the recipient ask for an initial supply of contractor tokens
    /// Default and minimum value is the period for curator to check the identity of the recipient
    /// @param _MinutesDebatingPeriod Proposed period of the board meeting
    /// @return The index of the proposal
    function newContractorProposal(
        address _recipient,
        uint _amount, 
        string _description, 
        bytes32 _hashOfTheDocument,
        uint _TokenPrice, 
        uint256 _initialSupply,
        bool _rewardTokensToVoters,
        uint _MinutesDebatingPeriod
    ) returns (uint) {

        if (msg.value < DaoRules.minBoardMeetingFees) throw;

        uint _ContractorProposalID = ContractorProposals.length++;
        ContractorProposal c = ContractorProposals[_ContractorProposalID];

        c.recipient = _recipient;       
        c.initialSupply = _initialSupply;
        if (!hasAnAccountManager[c.recipient]) {
            AccountManager m = new AccountManager(address(this), c.recipient, c.initialSupply) ;
                
            ContractorAccountManager[c.recipient] = m;
            AccountManagerCreated(c.recipient, address(m));
            hasAnAccountManager[c.recipient] = true;
        }
        
       c.BoardMeetingID = newBoardMeeting(_ContractorProposalID, 0, 0, now + (DaoRules.minMinutesSetPeriod * 1 minutes), 
        _MinutesDebatingPeriod, msg.value);    

        c.amount = _amount;
        c.hashOfTheDocument = _hashOfTheDocument; 
        c.tokenPrice = _TokenPrice;
        c.rewardTokensToVoters = _rewardTokensToVoters;

        return _ContractorProposalID;
    }

    /// @notice Function to make a proposal for a funding of the Dao
    /// @param _publicTokenCreation True if crowdfunding
    /// @param _mainPartner The address of the funding contract if private
    /// @param _maxFundingAmount The maximum amount to fund
    /// @param _tokenPrice The quantity of created tokens will depend on this price
    /// @param _inflationRate If 0, the token price doesn't change 
    /// @param _minutesSetPeriod Period before the voting period 
    /// and for the main partner to set the partners
    /// @param _minutesFundingPeriod Period for the partners to fund the Dao after the board meeting decision
    /// @param _MinutesDebatingPeriod Proposed period of the board meeting
    /// @return The index of the proposal
    function newFundingProposal(
        bool _publicTokenCreation,
        address _mainPartner,
        uint _maxFundingAmount, 
        uint _tokenPrice,    
        uint _inflationRate,
        uint _minutesSetPeriod,
        uint _minutesFundingPeriod,
        uint _MinutesDebatingPeriod
    ) returns (uint) {

        if (msg.value < DaoRules.minBoardMeetingFees ) throw;
        
        uint _FundingProposalID = FundingProposals.length++;
        FundingProposal f = FundingProposals[_FundingProposalID];

        f.BoardMeetingID = newBoardMeeting(0, 0, _FundingProposalID, now + (_minutesSetPeriod * 1 minutes),
        _MinutesDebatingPeriod, msg.value);   
        
        f.mainPartner = _mainPartner;
        f.publicTokenCreation = _publicTokenCreation;
        f.fundingAmount = _maxFundingAmount;
        f.tokenPrice = _tokenPrice;
        f.inflationRate = _inflationRate;
        f.minutesFundingPeriod = _minutesFundingPeriod;

        return _FundingProposalID;
    }

    /// @notice Function to make a proposal to change the Dao rules 
    /// @param _minMinutesSetPeriod Minimum period before a board meeting
    /// @param _minQuorumDivisor If 5, the minimum quorum is 20%
    /// @param _minBoardMeetingFees The amount in wei for the voters to vote 
    /// during a board meeting
    /// @param _minMinutesDebatePeriod The minimum period in minutes 
    /// of the board meeting
    /// @param _maxMinutesDebatePeriod The maximum period in minutes 
    /// of the board meeting
    /// @param _minutesExecuteProposalPeriod The period in minutes to execute 
    /// a decision after a board meeting
    /// @param _MinutesDebatingPeriod Proposed period of the board meeting
    /// @param _tokenTransferAble Address of the account manager of transferable tokens
    function newDaoRulesProposal(
        uint _minMinutesSetPeriod,
        uint _minQuorumDivisor, 
        uint _minBoardMeetingFees,
        uint _minMinutesDebatePeriod, 
        uint _maxMinutesDebatePeriod,
        uint _minutesExecuteProposalPeriod,
        uint _MinutesDebatingPeriod,
        address _tokenTransferAble
    ) returns (uint) {
    
        if (msg.value < DaoRules.minBoardMeetingFees ) throw; 
        
        uint _DaoRulesProposalID = DaoRulesProposals.length++;
        Rules r = DaoRulesProposals[_DaoRulesProposalID];

        r.minMinutesSetPeriod = _minMinutesSetPeriod;
        r.minQuorumDivisor = _minQuorumDivisor;
        r.BoardMeetingID = newBoardMeeting(0, _DaoRulesProposalID, 0, now, _MinutesDebatingPeriod, msg.value);      
        r.minBoardMeetingFees = _minBoardMeetingFees;
        r.minMinutesDebatePeriod = _minMinutesDebatePeriod;
        r.maxMinutesDebatePeriod = _maxMinutesDebatePeriod;
        r.minutesExecuteProposalPeriod = _minutesExecuteProposalPeriod;
        r.tokenTransferAble = _tokenTransferAble;

        return _DaoRulesProposalID;
    }
 
    /// @notice Function to extent the set period before a board meeting
    /// @param _BoardMeetingID The index of the board meeting
    /// @param _MinutesProposalPeriod The period to extent
    function extentSetPeriod(
        uint _BoardMeetingID,
        uint  _MinutesProposalPeriod) {
        
        BoardMeeting p = BoardMeetings[_BoardMeetingID];
        if (now > p.setDeadline 
            || msg.sender != address(p.creator)) throw;
        
        p.setDeadline += _MinutesProposalPeriod * 1 minutes;
        p.votingDeadline += _MinutesProposalPeriod * 1 minutes;
        
        BoardMeetingDelayed(_BoardMeetingID, _MinutesProposalPeriod);
    }
    
    /// @notice Function to vote during a board meeting
    /// @param _BoardMeetingID The index of the board meeting
    /// @param _supportsProposal True if the proposal is supported
    /// @return Whether the transfer was successful or not    
    function vote(
        uint _BoardMeetingID, 
        bool _supportsProposal
    ) noEther onlyTokenholders returns (bool _success) {
        
        if (mutex) { throw; }
        mutex = true;
            
        BoardMeeting p = BoardMeetings[_BoardMeetingID];
        if (p.hasVoted[msg.sender] 
            || now < p.setDeadline
            || now > p.votingDeadline 
            ||!p.open
        ) {
        throw;
        }

        p.hasVoted[msg.sender] = true;
        
        if (_supportsProposal) {
            p.yea += DaoAccountManager.balanceOf(msg.sender);
        } 
        else {
            p.nay += DaoAccountManager.balanceOf(msg.sender); 
        }

        if (p.ContractorProposalID != 0) {
            ContractorProposal c = ContractorProposals[p.ContractorProposalID];
            if (c.rewardTokensToVoters) {
                uint _weight = DaoAccountManager.balanceOf(msg.sender);
                c.weightToRecieve[msg.sender] += _weight; 
                c.totalWeight += _weight;
            }
        }

        uint _deadline = DaoAccountManager.blockedAccountDeadLine(msg.sender);
        if (_deadline == 0) {
            DaoAccountManager.blockAccount(msg.sender, p.votingDeadline);
        }
        else if (p.votingDeadline > _deadline) {
            DaoAccountManager.blockAccount(msg.sender, p.votingDeadline);
        }

        if (p.fees > 0 && p.ContractorProposalID != 0) {
            uint _rewardedamount = p.fees*DaoAccountManager.balanceOf(msg.sender)/DaoAccountManager.TotalSupply();
            p.totalRewardedAmount += _rewardedamount;
            if (!msg.sender.send(_rewardedamount)) throw;
        }

        Voted(_BoardMeetingID, _supportsProposal, msg.sender, _rewardedamount);
        
        mutex = false;
        
    }

    /// @notice Function to executes a board meeting decision
    /// @param _BoardMeetingID The index of the board meeting
    /// @return Whether the transfer was successful or not    
    function executeDecision(uint _BoardMeetingID) noEther returns (bool _success) 
        {

        if (mutex) { throw; }
        mutex = true;

        BoardMeeting p = BoardMeetings[_BoardMeetingID];

        if (now <= p.votingDeadline
            || !p.open ) {
            throw;
        }
        
        uint quorum = p.yea + p.nay;
        
        if (p.FundingProposalID != 0 || p.DaoRulesProposalID != 0) {
                if (p.fees > 0 && quorum >= minQuorum()  
                ) {
                    uint _amountToGiveBack = p.fees;
                    p.fees = 0;
                }
        }        

        if (p.ContractorProposalID != 1 &&
                (now > p.executionDeadline || (quorum < minQuorum() || p.yea <= p.nay))
            ) {
            takeBoardingFees(_BoardMeetingID);
            p.open = false;
            if (_amountToGiveBack > 0) {
                if (!p.creator.send(_amountToGiveBack)) throw;
                _amountToGiveBack = 0;
            }
            return;
        }

        p.open = false;
        _success = true; 
        p.dateOfExecution = now;
        takeBoardingFees(_BoardMeetingID);

        if (p.FundingProposalID != 0) {

            FundingProposal f = FundingProposals[p.FundingProposalID];
            DaoAccountManager.extentFunding(f.mainPartner, f.publicTokenCreation, f.tokenPrice, 
                f.fundingAmount/f.tokenPrice, now, now + f.minutesFundingPeriod * 1 minutes, f.inflationRate);
            
        }
        
        if (p.DaoRulesProposalID != 0) {

            Rules r = DaoRulesProposals[p.DaoRulesProposalID];
            DaoRules.BoardMeetingID = r.BoardMeetingID;
            DaoRules.minQuorumDivisor = r.minQuorumDivisor;
            DaoRules.minMinutesDebatePeriod = r.minMinutesDebatePeriod;
            DaoRules.maxMinutesDebatePeriod = r.maxMinutesDebatePeriod;
            DaoRules.minBoardMeetingFees = r.minBoardMeetingFees;
            DaoRules.minutesExecuteProposalPeriod = r.minutesExecuteProposalPeriod;
            DaoRules.minMinutesSetPeriod = r.minMinutesSetPeriod;

            if (r.tokenTransferAble != 0) {
                AccountManager m = AccountManager(r.tokenTransferAble);
                m.TransferAble();
                if (m == DaoAccountManager) {
                    DaoRules.tokenTransferAble = m;
                }
            }
        }
            
        if (p.ContractorProposalID != 0) {

            ContractorProposal c = ContractorProposals[p.ContractorProposalID];
            ContractorAccountManager[c.recipient].extentFunding(address(this), false, c.tokenPrice, 
                    c.amount/c.tokenPrice, now, 0, 0);
            DaoAccountManager.sendTo(c.recipient, c.amount);
                    
        }

        if (_amountToGiveBack > 0) {
            if (!p.creator.send(_amountToGiveBack)) throw;
        }

        ProposalTallied(_BoardMeetingID);
        
        mutex = false;
    }

    /// @notice Function to reward contractor tokens for voters 
    /// after the execution of the contractor proposal,
    /// @param _contractorProposalID The index of the proposal
    /// @param _Tokenholder The address of the tokenholder
    /// @return Whether the transfer was successful or not    
    function RewardContractorTokens(uint _contractorProposalID, address _Tokenholder) 
    noEther returns (bool) {

        ContractorProposal c = ContractorProposals[_contractorProposalID];
        BoardMeeting p = BoardMeetings[c.BoardMeetingID];

        if (p.dateOfExecution == 0 || c.weightToRecieve[_Tokenholder]==0 || !c.rewardTokensToVoters) {throw; }
        
        uint _amount = (c.amount*c.weightToRecieve[_Tokenholder])/c.totalWeight;

        c.weightToRecieve[_Tokenholder] = 0;

        AccountManager m = ContractorAccountManager[c.recipient];
        m.rewardToken(_Tokenholder, _amount);

        TokensBoughtFor(_contractorProposalID, _Tokenholder, _amount);

    }

    /// @dev internal function to put to the Dao balance the board meeting fees of non voters
    /// @param _boardMeetingID THe index of the proposal
    function takeBoardingFees(uint _boardMeetingID) internal {

        BoardMeeting p = BoardMeetings[_boardMeetingID];
        if (p.fees - p.totalRewardedAmount > 0) {
            uint _amount = p.fees - p.totalRewardedAmount;
            p.totalRewardedAmount = p.fees;
            if (!DaoAccountManager.send(_amount)) throw;
        }
        
    }
        
    /// @notice Interface function to get the number of meetings 
    /// @return the number of meetings (passed or current)
    function numberOfMeetings() constant returns (uint) {
        return BoardMeetings.length - 1;
    }

    /// @notice Interface function to get the right of a tokenholder to receive contractor tokens 
    /// @param _contractorProposalID The index of the proposal
    /// @param _Tokenholder The address of the tokenholder
    /// @return the weight of the tokenholder
    function weightToReceive(
            uint _contractorProposalID, 
            address _Tokenholder) constant returns (uint) {
                
        ContractorProposal c = ContractorProposals[_contractorProposalID];
        return (c.amount*c.weightToRecieve[_Tokenholder])/c.totalWeight;
        
    }
        
    /// @dev internal function to get the minimum quorum needed for a proposal    
    /// @return The minimum quorum for the proposal to pass 
    function minQuorum() constant returns (uint) {
        return uint(DaoAccountManager.TotalSupply()) / DaoRules.minQuorumDivisor;
    }


}
