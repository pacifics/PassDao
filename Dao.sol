import "AccountManager.sol";

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

// import "AccountManager.sol";

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
        // The initial price (in wei) of a contractor token
        uint initialTokenPrice;
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
        // The price (in wei) for a token
        uint tokenPrice; 
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
    /// @param _initialTokenPrice The quantity of contractor tokens will depend on this price    
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
        uint _initialTokenPrice, 
        uint _inflationRate,
        uint256 _initialSupply,
        uint _totalAmountForTokenReward,
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
        c.initialTokenPrice = _initialTokenPrice;
        c.inflationRate = _inflationRate;

        c.totalAmountForTokenReward = _totalAmountForTokenReward;
        ContractorAccountManager[c.recipient].extentFunding(address(this), false, c.initialTokenPrice, 
                    c.totalAmountForTokenReward, now, 0, c.inflationRate);

        ContractorAccountManager[c.recipient].Fueled(false); 

        return _ContractorProposalID;
    }

    /// @notice Function to make a proposal for a funding of the Dao
    /// @param _publicTokenCreation True if crowdfunding
    /// @param _mainPartner The address of the funding contract if private
    /// @param _maxFundingAmount The maximum amount to fund
    /// @param _tokenPrice The quantity of created tokens will depend on this price
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
        uint _tokenPrice,    
        uint _inflationRate,
        uint _contractorProposalID,
        uint _minutesFundingPeriod,
        uint _minutesSetPeriod,
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
        f.contractorProposalID = _contractorProposalID;
        f.minutesFundingPeriod = _minutesFundingPeriod;

        if (_contractorProposalID != 0) {
            ContractorProposal cf = ContractorProposals[_contractorProposalID];
            BoardMeeting p = BoardMeetings[cf.BoardMeetingID];
            if (!p.open || now > p.executionDeadline || p.creator != msg.sender || cf.amount > f.fundingAmount) throw;

            cf.fundingProposalID = _FundingProposalID;
            cf.totalAmountForTokenReward = 0;
            uint _amountToGiveBack = p.fees;
            p.fees = 0;
            if (!address(p.creator).send(_amountToGiveBack)) throw;
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
            if (c.fundingProposalID == 0) throw;
            if (c.totalAmountForTokenReward > 0) {
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
        
    }

    /// @notice Function to executes a board meeting decision
    /// @param _BoardMeetingID The index of the board meeting
    /// @return Whether the transfer was successful or not    
    function executeDecision(uint _BoardMeetingID) noEther returns (bool _success) 
        {

        BoardMeeting p = BoardMeetings[_BoardMeetingID];

        if (now <= p.votingDeadline
            || !p.open ) {
            throw;
        }

        p.open = false;
        
        uint quorum = p.yea + p.nay;
        uint _amountToGiveBack = 0;
        
        if (p.FundingProposalID != 0 || p.DaoRulesProposalID != 0) {
                if (p.fees > 0 && quorum >= minQuorum()  
                ) {
                    _amountToGiveBack = p.fees;
                    p.fees = 0;
                }
        }        

        bool _contractorProposalFueled = false;
        if (p.ContractorProposalID != 0) {
            ContractorProposal c = ContractorProposals[p.ContractorProposalID];
            _contractorProposalFueled = ContractorAccountManager[c.recipient].IsFueled();
        }

        if (now > p.executionDeadline 
            || ((quorum < minQuorum() || p.yea <= p.nay) && !_contractorProposalFueled)
            ) {
            takeBoardMeetingFees(_BoardMeetingID);
            if (_amountToGiveBack > 0) {
                if (!address(p.creator).send(_amountToGiveBack)) throw;
                _amountToGiveBack = 0;
            }
            return;
        }

        p.dateOfExecution = now;
        takeBoardMeetingFees(_BoardMeetingID);

        if (p.FundingProposalID != 0) {

            FundingProposal f = FundingProposals[p.FundingProposalID];

            DaoAccountManager.extentFunding(f.mainPartner, f.publicTokenCreation, f.tokenPrice, 
                f.fundingAmount, now, now + f.minutesFundingPeriod * 1 minutes, f.inflationRate);

            if (f.contractorProposalID != 0) {
                ContractorProposal cf = ContractorProposals[f.contractorProposalID];
                ContractorAccountManager[cf.recipient].extentFunding(f.mainPartner, false, cf.initialTokenPrice, 
                    f.fundingAmount, now, now + f.minutesFundingPeriod * 1 minutes, cf.inflationRate);
            }
            
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
            DaoAccountManager.sendTo(address(c.recipient), c.amount);
        }

        if (_amountToGiveBack > 0) {
            if (!address(p.creator).send(_amountToGiveBack)) throw;
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
        BoardMeeting p = BoardMeetings[c.BoardMeetingID];

        if (p.dateOfExecution == 0 || c.weightToRecieve[_Tokenholder]==0 || c.totalAmountForTokenReward == 0) {throw; }
        
        uint _amount = (c.totalAmountForTokenReward*c.weightToRecieve[_Tokenholder])/c.totalWeight;

        c.weightToRecieve[_Tokenholder] = 0;

        AccountManager m = ContractorAccountManager[c.recipient];
        m.rewardToken(_Tokenholder, _amount, now);

        TokensBoughtFor(_contractorProposalID, _Tokenholder, _amount);

    }

    /// @dev internal function to put to the Dao balance the board meeting fees of non voters
    /// @param _boardMeetingID THe index of the proposal
    function takeBoardMeetingFees(uint _boardMeetingID) internal {

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
        return c.weightToRecieve[_Tokenholder];
        
    }
        
    /// @dev internal function to get the minimum quorum needed for a proposal    
    /// @return The minimum quorum for the proposal to pass 
    function minQuorum() constant returns (uint) {
        return uint(DaoAccountManager.TotalSupply()) / DaoRules.minQuorumDivisor;
    }


}
