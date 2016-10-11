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

import "AccountManager.sol";

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
        // mapping to indicate the vote date
        mapping (address => uint) voteDate;  
    }

    struct ContractorProposal {
        // Index to identify the board meeting of the proposal
        uint BoardMeetingID;
        // The address of the proposal creator where the `amount` will go to if the proposal is accepted
        address recipient;
        // The amount to transfer to `recipient` if the proposal is accepted.
        uint amount; 
        // The description of the proposal
        string description;
        // The hash of the proposal's document
        bytes32 hashOfTheDocument;
        // The initial price multiplier of a contractor token
        uint initialTokenPriceMultiplier;
        // The inflation rate to calculate the actual token price.
        uint inflationRate;
        // The initial supply of contractor tokens for the recipient
        uint256 initialSupply;
        // The index of the fundink proposal if linked to the contractor proposal
        uint fundingProposalID;
        // Total amount if the proposal foreseen to reward tokens to voters
        uint totalAmountForTokenReward;
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
        // The price multiplier for a token
        uint tokenPriceMultiplier; 
        // Rate per year applied to the token price 
        uint inflationRate;
        // Period for the partners to fund after the execution of the decision
        uint minutesFundingPeriod;
        // Index of the contractor proposal (not mandatory)
        uint contractorProposalID;
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
        // The minimum inflation rate for the creation of contractor tokens to voters
        uint minContractorTokenInflationRate;
        // The maximum inflation rate for the reward of contractor tokens to voters
        uint maxContractorTokenInflationRate;
        // Address of the account manager of transferable tokens
        address tokenTransferAble;
    } 

    // The Dao account manager contract
    AccountManager public DaoAccountManager;

    // Map to allow to withdraw board meeting fees
    mapping (address => uint) public pendingWithdrawals;
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
    
    event newBoardMeetingAdded(uint indexed BoardMeetingID, uint setDeadline, uint votingDeadline);
    event AccountManagerCreated(address recipient, address AccountManagerAddress);
    event BoardMeetingDelayed(uint indexed BoardMeetingID, uint MinutesProposalPeriod);
    event Voted(uint indexed proposalID, bool position, address indexed voter, uint rewardedAmount);
    event BoardMeetingFeesGivenBack(uint indexed boardMeetingID);
    event BoardMeetingClosed(uint indexed boardMeetingID);
    event ProposalTallied(uint indexed boardMeetingID);
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
    function DAO(address _creator) {

        DaoAccountManager = new AccountManager(address(this), _creator, 10);

        DaoRules.maxMinutesDebatePeriod = 57600;
        DaoRules.minutesExecuteProposalPeriod = 57600;

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

        if (_MinutesDebatingPeriod > DaoRules.maxMinutesDebatePeriod 
            || _MinutesDebatingPeriod < DaoRules.minMinutesDebatePeriod) {
            throw;
        }

        uint _BoardMeetingID = BoardMeetings.length++;
        BoardMeeting b = BoardMeetings[_BoardMeetingID];

        b.creator = msg.sender;
        b.ContractorProposalID = _ContractorProposalID;
        b.DaoRulesProposalID = _DaoRulesProposalID;
        b.FundingProposalID = _FundingProposalID;
        b.fees = _boardMeetingFees;
        b.setDeadline =_setdeadline;        
        
        uint _DebatePeriod;
        if (_MinutesDebatingPeriod < DaoRules.minMinutesDebatePeriod) _DebatePeriod = DaoRules.minMinutesDebatePeriod; 
        else _DebatePeriod = _MinutesDebatingPeriod; 

        b.votingDeadline = _setdeadline + (_DebatePeriod * 1 minutes); 
        b.executionDeadline = b.votingDeadline + DaoRules.minutesExecuteProposalPeriod * 1 minutes;

        b.open = true; 

        newBoardMeetingAdded(_BoardMeetingID, b.setDeadline, b.votingDeadline);

        return _BoardMeetingID;

    }

    /// @notice Function to make a proposal to be a contractor of the Dao
    /// @param _amount The amount to be sent if the proposal is approved
    /// @param _description String describing the proposal
    /// @param _hashOfTheDocument The hash to identify the proposal document
    /// @param _initialTokenPriceMultiplier The quantity of contractor tokens will depend on this multiplier    
    /// @param _inflationRate If 0, the token price doesn't change during the funding
    /// @param _initialSupply If the recipient ask for an initial supply of contractor tokens
    /// Default and minimum value is the period for curator to check the identity of the recipient
    /// @param _totalAmountForTokenReward Total amount if the proposal foreseen to reward tokens to voters
    /// @param _MinutesDebatingPeriod Proposed period of the board meeting
    /// @return The index of the proposal
    function newContractorProposal(
        address _recipient,
        uint _amount, 
        string _description, 
        bytes32 _hashOfTheDocument,
        uint _initialTokenPriceMultiplier, 
        uint _inflationRate,
        uint256 _initialSupply,
        uint _totalAmountForTokenReward,
        uint _MinutesDebatingPeriod
    ) returns (uint) {

        if (msg.value < DaoRules.minBoardMeetingFees) throw;
        if (_inflationRate < DaoRules.minContractorTokenInflationRate
                || (_inflationRate > DaoRules.maxContractorTokenInflationRate 
                    && DaoRules.maxContractorTokenInflationRate != 0)) throw;

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
        c.description = _description;
        c.hashOfTheDocument = _hashOfTheDocument; 
        c.initialTokenPriceMultiplier = _initialTokenPriceMultiplier;
        c.inflationRate = _inflationRate;

        c.totalAmountForTokenReward = _totalAmountForTokenReward;

        ContractorAccountManager[c.recipient].extentFunding(address(this), false, c.initialTokenPriceMultiplier, 
                    c.totalAmountForTokenReward, now, 0, c.inflationRate);

        return _ContractorProposalID;
        
    }

    /// @notice Function to make a proposal for a funding of the Dao
    /// @param _publicTokenCreation True if crowdfunding
    /// @param _mainPartner The address of the funding contract if private
    /// @param _maxFundingAmount The maximum amount to fund
    /// @param _tokenPriceMultiplier The quantity of created tokens will depend on this multiplier
    /// @param _inflationRate If 0, the token price doesn't change 
    /// @param _contractorProposalID Index of the contractor proposal (not mandatory)
    /// @param _minutesFundingPeriod Period for the partners to fund the Dao after the board meeting decision
    /// @param _minutesSetPeriod Period before the voting period 
    /// and for the main partner to set the partners
    /// @param _MinutesDebatingPeriod Proposed period of the board meeting
    /// @return The index of the proposal
    function newFundingProposal(
        bool _publicTokenCreation,
        address _mainPartner,
        uint _maxFundingAmount, 
        uint _tokenPriceMultiplier,    
        uint _inflationRate,
        uint _contractorProposalID,
        uint _minutesFundingPeriod,
        uint _minutesSetPeriod,
        uint _MinutesDebatingPeriod
    ) onlyTokenholders returns (uint) {

        if (msg.value < DaoRules.minBoardMeetingFees ) throw;

        uint _FundingProposalID = FundingProposals.length++;
        FundingProposal f = FundingProposals[_FundingProposalID];

        f.BoardMeetingID = newBoardMeeting(0, 0, _FundingProposalID, now + (_minutesSetPeriod * 1 minutes),
        _MinutesDebatingPeriod, msg.value);   
        
        f.mainPartner = _mainPartner;
        f.publicTokenCreation = _publicTokenCreation;
        f.fundingAmount = _maxFundingAmount;
        f.tokenPriceMultiplier = _tokenPriceMultiplier;
        f.inflationRate = _inflationRate;
        f.contractorProposalID = _contractorProposalID;
        f.minutesFundingPeriod = _minutesFundingPeriod;

        if (_contractorProposalID != 0) {

            ContractorProposal cf = ContractorProposals[_contractorProposalID];
            BoardMeeting b = BoardMeetings[cf.BoardMeetingID];
            if (!b.open || now > b.executionDeadline || b.creator != msg.sender) throw;

            cf.fundingProposalID = _FundingProposalID;
            cf.totalAmountForTokenReward = 0;

            b.fees = 0;
            pendingWithdrawals[b.creator] += b.fees;

        }
        
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
    /// @param _minContractorTokenInflationRate The minimum inflation rate for the reward of tokens to voters
    /// @param _maxContractorTokenInflationRate The maximum inflation rate for the reward of tokens tp voters
    /// @param _MinutesDebatingPeriod Proposed period of the board meeting
    /// @param _tokenTransferAble Address of the account manager of transferable tokens
    function newDaoRulesProposal(
        uint _minMinutesSetPeriod,
        uint _minQuorumDivisor, 
        uint _minBoardMeetingFees,
        uint _minMinutesDebatePeriod, 
        uint _maxMinutesDebatePeriod,
        uint _minutesExecuteProposalPeriod,
        uint _minContractorTokenInflationRate,
        uint _maxContractorTokenInflationRate,
        uint _MinutesDebatingPeriod,
        address _tokenTransferAble
    ) onlyTokenholders returns (uint) {
    
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
        r.minContractorTokenInflationRate = _minContractorTokenInflationRate;
        r.maxContractorTokenInflationRate = _maxContractorTokenInflationRate;
        r.tokenTransferAble = _tokenTransferAble;

        return _DaoRulesProposalID;
        
    }
 
    /// @notice Function to extent the set period before a board meeting
    /// @param _BoardMeetingID The index of the board meeting
    /// @param _MinutesPeriod The period to extent
    function extentSetPeriod(
        uint _BoardMeetingID,
        uint  _MinutesPeriod) {
        
        BoardMeeting b = BoardMeetings[_BoardMeetingID];
        if (now > b.setDeadline 
            || msg.sender != address(b.creator)) throw;
        
        b.setDeadline += _MinutesPeriod * 1 minutes;
        b.votingDeadline += _MinutesPeriod * 1 minutes;
        
        BoardMeetingDelayed(_BoardMeetingID, _MinutesPeriod);
        
    }
    
    /// @notice Function to vote during a board meeting
    /// @param _BoardMeetingID The index of the board meeting
    /// @param _supportsProposal True if the proposal is supported
    /// @return Whether the transfer was successful or not    
    function vote(
        uint _BoardMeetingID, 
        bool _supportsProposal
    ) noEther onlyTokenholders returns (bool _success) {
        
        BoardMeeting b = BoardMeetings[_BoardMeetingID];
        if (b.voteDate[msg.sender] != 0 
            || now < b.setDeadline
            || now > b.votingDeadline 
            ||!b.open
        ) {
        throw;
        }

        b.voteDate[msg.sender] = now;
        
        if (_supportsProposal) {
            b.yea += DaoAccountManager.balanceOf(msg.sender);
        } 
        else {
            b.nay += DaoAccountManager.balanceOf(msg.sender); 
        }

        if (b.ContractorProposalID != 0) {
            ContractorProposal c = ContractorProposals[b.ContractorProposalID];
            if (c.fundingProposalID != 0) throw;
            if (c.totalAmountForTokenReward > 0) {
                uint _weight = DaoAccountManager.balanceOf(msg.sender);
                c.weightToRecieve[msg.sender] += _weight; 
                c.totalWeight += _weight;
            }
        }

        uint _deadline = DaoAccountManager.blockedAccountDeadLine(msg.sender);
        if (_deadline == 0) {
            DaoAccountManager.blockAccount(msg.sender, b.votingDeadline);
        }
        else if (b.votingDeadline > _deadline) {
            DaoAccountManager.blockAccount(msg.sender, b.votingDeadline);
        }

        if (b.fees > 0 && b.ContractorProposalID != 0) {
            uint _rewardedamount = b.fees*DaoAccountManager.balanceOf(msg.sender)/DaoAccountManager.TotalSupply();
            b.totalRewardedAmount += _rewardedamount;
            pendingWithdrawals[msg.sender] += _rewardedamount;
        }

        Voted(_BoardMeetingID, _supportsProposal, msg.sender, _rewardedamount);
        
    }

    /// @notice Function to executes a board meeting decision
    /// @param _BoardMeetingID The index of the board meeting
    /// @return Whether the transfer was successful or not    
    function executeDecision(uint _BoardMeetingID) noEther returns (bool _success) 
        {

        BoardMeeting b = BoardMeetings[_BoardMeetingID];

        if (now <= b.votingDeadline
            || !b.open ) {
            throw;
        }
        
        uint quorum = b.yea + b.nay;

        if (b.FundingProposalID != 0 || b.DaoRulesProposalID != 0) {
                if (b.fees > 0 && quorum >= minQuorum()  
                ) {
                    pendingWithdrawals[b.creator] += b.fees;
                    b.fees = 0;
                }
        }        

        bool _contractorProposalFueled;
        if (b.ContractorProposalID != 0) {
            ContractorProposal c = ContractorProposals[b.ContractorProposalID];
            _contractorProposalFueled = DaoAccountManager.IsFueled(b.ContractorProposalID);
            if (now < b.executionDeadline && c.fundingProposalID != 0 && !_contractorProposalFueled) {
                return; 
            }
        }
        
        b.open = false;
        takeBoardMeetingFees(_BoardMeetingID);
        BoardMeetingClosed(_BoardMeetingID);
        
        if (now > b.executionDeadline 
            || ((quorum < minQuorum() || b.yea <= b.nay) && !_contractorProposalFueled)
            ) {
            return;
        }

        b.dateOfExecution = now;

        if (b.FundingProposalID != 0) {

            FundingProposal f = FundingProposals[b.FundingProposalID];

            DaoAccountManager.extentFunding(f.mainPartner, f.publicTokenCreation, f.tokenPriceMultiplier, 
                f.fundingAmount, now, now + f.minutesFundingPeriod * 1 minutes, f.inflationRate);

            if (f.contractorProposalID != 0) {
                ContractorProposal cf = ContractorProposals[f.contractorProposalID];
                ContractorAccountManager[cf.recipient].extentFunding(f.mainPartner, false, cf.initialTokenPriceMultiplier, 
                    f.fundingAmount, now, now + f.minutesFundingPeriod * 1 minutes, cf.inflationRate);
            }
            
        }
        
        if (b.DaoRulesProposalID != 0) {

            Rules r = DaoRulesProposals[b.DaoRulesProposalID];

            DaoRules.BoardMeetingID = r.BoardMeetingID;
            DaoRules.minQuorumDivisor = r.minQuorumDivisor;
            DaoRules.minMinutesDebatePeriod = r.minMinutesDebatePeriod;
            DaoRules.maxMinutesDebatePeriod = r.maxMinutesDebatePeriod;
            DaoRules.minBoardMeetingFees = r.minBoardMeetingFees;
            DaoRules.minutesExecuteProposalPeriod = r.minutesExecuteProposalPeriod;
            DaoRules.minMinutesSetPeriod = r.minMinutesSetPeriod;
            DaoRules.minContractorTokenInflationRate = r.minContractorTokenInflationRate;
            DaoRules.maxContractorTokenInflationRate = r.maxContractorTokenInflationRate;

            if (r.tokenTransferAble != 0) {
                AccountManager m = AccountManager(r.tokenTransferAble);
                m.TransferAble();
                if (m == DaoAccountManager) {
                    DaoRules.tokenTransferAble = m;
                }
            }
            
        }
            
        if (b.ContractorProposalID != 0) {
            DaoAccountManager.sendTo(address(c.recipient), c.amount);
        }

        ProposalTallied(_BoardMeetingID);
        
    }

    /// @notice Function to reward contractor tokens for voters 
    /// after the execution of the contractor proposal,
    /// @param _contractorProposalID The index of the proposal
    /// @param _Tokenholder The address of the tokenholder
    /// @return Whether the transfer was successful or not    
    function RewardContractorTokens(uint _contractorProposalID, address _Tokenholder) 
    noEther returns (bool) {

        ContractorProposal c = ContractorProposals[_contractorProposalID];
        BoardMeeting b = BoardMeetings[c.BoardMeetingID];

        if (b.dateOfExecution == 0 || c.weightToRecieve[_Tokenholder]==0 || c.totalAmountForTokenReward == 0) {throw; }
        
        uint _weight = c.weightToRecieve[_Tokenholder]
        c.weightToRecieve[_Tokenholder] = 0;
        uint _amount = (c.totalAmountForTokenReward*_weight)/c.totalWeight;

        AccountManager m = ContractorAccountManager[c.recipient];
        m.rewardToken(_Tokenholder, _amount, b.voteDate[_Tokenholder]);

        TokensBoughtFor(_contractorProposalID, _Tokenholder, _amount);

    }

    /// @notice Function to reward contractor tokens to voters 
    /// @return Whether the withdraw was successful or not    
    function withdrawFees() returns (bool) {
        uint amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        if (msg.sender.send(amount)) {
            return true;
        } else {
            pendingWithdrawals[msg.sender] = amount;
            return false;
        }
    }

    /// @dev internal function to put to the Dao balance the board meeting fees of non voters
    /// @param _boardMeetingID THe index of the proposal
    function takeBoardMeetingFees(uint _boardMeetingID) internal {

        BoardMeeting b = BoardMeetings[_boardMeetingID];
        if (b.fees - b.totalRewardedAmount > 0) {
            uint _amount = b.fees - b.totalRewardedAmount;
            b.totalRewardedAmount = b.fees;
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
        return c.weightToRecieve[_Tokenholder];
        
    }
        
    /// @dev internal function to get the minimum quorum needed for a proposal    
    /// @return The minimum quorum for the proposal to pass 
    function minQuorum() constant returns (uint) {
        return uint(DaoAccountManager.TotalSupply()) / DaoRules.minQuorumDivisor;
    }

}

contract DAOCreator {
    event NewDao(address creator, address newDao);
    function createDAO() returns (DAO) {
        DAO _newDao = new DAO(msg.sender);
        NewDao(msg.sender, address(_newDao));
        return _newDao;
    }
}
