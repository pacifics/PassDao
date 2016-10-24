import "AccountManager.sol";

pragma solidity ^0.4.2;

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

/// @title Pass Decentralized Autonomous Organisation
contract DAO {

    struct BoardMeeting {        
        // Address who created the board meeting for a proposal
        address creator;  
        // Index to identify the proposal to pay a contractor
        uint ContractorProposalID;
        // Index to identify the proposal to update the Dao rules 
        uint DaoRulesProposalID; 
        // Index to identify the proposal for a funding of the Dao
        uint FundingProposalID;
        // unix timestamp, denoting the end of the set period of a proposal before the board meeting 
        uint setDeadline;
        // Fees (in wei) paid by the creator of the board meeting
        uint fees; 
        // Total of fees (in wei) rewarded to the voters
        uint totalRewardedAmount;
        // A unix timestamp, denoting the end of the voting period
        uint votingDeadline;
        // True if the proposal's votes have yet to be counted, otherwise False
        bool open; 
        // A unix timestamp, denoting the date of the execution of the approved proposal
        uint dateOfExecution;
        // A unix timestamp, denoting the deadline to execute the approved proposal 
        uint executionDeadline;
        // Number of shares in favor of the proposal
        uint yea; 
        // Number of shares opposed to the proposal
        uint nay; 
        // mapping to indicate if a shareholder has voted
        mapping (address => bool) hasVoted;  
    }

    struct ContractorProposal {
        // Index to identify the board meeting of the proposal
        uint BoardMeetingID;
        // The address of the proposal recipient where the `amount` will go to if the proposal is accepted
        address recipient;
        // The amount (in wei) to transfer to `recipient` if the proposal is accepted.
        uint amount; 
        // The description of the proposal
        string description;
        // The hash of the proposal's document
        bytes32 hashOfTheDocument;
        // The initial price multiplier of the contractor token
        uint initialTokenPriceMultiplier;
        // The inflation rate to calculate the actual contractor token price
        uint inflationRate;
        // The initial supply of contractor tokens for the recipient
        uint256 initialSupply;
        // The index of the funding proposal linked to the contractor proposal (not mandatory)
        uint fundingProposalID;
        // Total amount for the reward of tokens to voters
        uint totalAmountForTokenReward;

    }
    
    struct FundingProposal {
        // Index to identify the board meeting of the proposal
        uint BoardMeetingID;
        // The address which set partners in case of private funding (not mandatory)
        address mainPartner;
        // True if crowdfunding
        bool publicShareCreation; 
        // The maximum amount (in wei) to fund
        uint fundingAmount; 
        // The initial price multiplier of a Dao share
        uint sharePriceMultiplier; 
        // The inflation rate to calculate the actual contractor share price
        uint inflationRate;
        // A unix timestamp, denoting the start time of the funding
        uint startTime;
        // Period in minutes for the funding after the start time
        uint minutesFundingPeriod;
        // Index of the contractor proposal linked to the funding proposal (not mandatory)
        uint contractorProposalID;
    }

    struct Rules {
        // Index to identify the board meeting that decided to apply the rules
        uint BoardMeetingID;  
        // The quorum needed for each proposal is calculated by totalSupply / minQuorumDivisor
        uint minQuorumDivisor;  
        // Minimal fees (in wei) to create a proposal
        uint minBoardMeetingFees; 
        // Period in minutes to consider or set a proposal before the voting procedure
        uint minutesSetProposalPeriod; 
        // The minimum debate period in minutes that a generic proposal can have
        uint minMinutesDebatePeriod; 
        // Period in minutes after the board meeting to execute a proposal
        uint minutesExecuteProposalPeriod;
        // True if the dao tokens are transferable
        bool transferable;
    } 

    // The Dao account manager smart contract
    AccountManager public DaoAccountManager;
    
    // Map to allow to withdraw board meeting fees
    mapping (address => uint) public pendingFeesWithdrawals;
    // Map to to know the number of opened proposals of a recipient
    mapping (address => uint) public numberOfRecipientOpenedProposals; 
    // Map to to know the last contractor proposal of a recipient
    mapping (address => uint) public lastRecipientProposalId; 
    // Map to know the account management smart contracts of contractors
    mapping (address => AccountManager) public ContractorAccountManager; 

    // Board meetings to vote for or against a proposal
    BoardMeeting[] public BoardMeetings; 
    // Proposals to pay a contractor
    ContractorProposal[] public ContractorProposals;
    // Proposals for a funding of the Dao
    FundingProposal[] public FundingProposals;
   // Proposals to update the Dao Rules
    Rules[] public DaoRulesProposals;
    // The current Dao rules
    Rules public DaoRules; 
    
    // Modifier that allows only shareholders to vote
    modifier onlyTokenholders {
        if (DaoAccountManager.balanceOf(msg.sender) == 0) throw; _;}
    
    event AccountManagerCreated(address Recipient, address AccountManagerAddress);
    event ContractorProposalAdded(uint indexed BoardMeetingID, 
        uint ContractorProposalID, address indexed recipient, uint Amount);
    event FundingProposalAdded(uint indexed BoardMeetingID, uint FundingProposalID, 
        uint maxFundingAmount,uint ContractorProposalID);
    event DaoRulesProposalAdded(uint indexed BoardMeetingID, uint DaoRulesProposalID);
    event BoardMeetingClosed(uint indexed BoardMeetingID, uint FeesGivenBack);
    event ProposalTallied(uint indexed BoardMeetingID);

    /// @dev The constructor function
    function DAO(address _creator) {

        DaoAccountManager = new AccountManager(_creator, address(this), 0, 10);

        DaoRules.minQuorumDivisor = 5;
        DaoRules.minutesSetProposalPeriod = 10;
        DaoRules.minutesExecuteProposalPeriod = 100000;

        BoardMeetings.length = 1; 
        ContractorProposals.length = 1;
        FundingProposals.length = 1;
        DaoRulesProposals.length = 1;

    }
    
    /// @dev Internal function to create a board meeting
    /// @param _ContractorProposalID The index of the proposal if contractor
    /// @param _DaoRulesProposalID The index of the proposal if Dao rules
    /// @param _FundingProposalID The index of the proposal if funding
    /// @param _MinutesDebatingPeriod The duration in minutesof the meeting
    /// @return the index of the board meeting
    function newBoardMeeting(
        uint _ContractorProposalID, 
        uint _DaoRulesProposalID, 
        uint _FundingProposalID, 
        uint _MinutesDebatingPeriod
    ) internal returns (uint) {

        if (msg.value < DaoRules.minBoardMeetingFees
            || _MinutesDebatingPeriod > 100000 
            || _MinutesDebatingPeriod < DaoRules.minMinutesDebatePeriod
            || msg.sender == address(this)) {
            throw;
        }

        uint _BoardMeetingID = BoardMeetings.length++;
        BoardMeeting b = BoardMeetings[_BoardMeetingID];

        b.creator = msg.sender;

        b.ContractorProposalID = _ContractorProposalID;
        b.DaoRulesProposalID = _DaoRulesProposalID;
        b.FundingProposalID = _FundingProposalID;

        b.fees = msg.value;
        
        b.setDeadline = now + (DaoRules.minutesSetProposalPeriod * 1 minutes);        
        b.votingDeadline = b.setDeadline + (_MinutesDebatingPeriod * 1 minutes); 
        b.executionDeadline = b.votingDeadline + (DaoRules.minutesExecuteProposalPeriod * 1 minutes);

        if (b.executionDeadline < now) throw;

        b.open = true; 

        return _BoardMeetingID;

    }

    /// @notice Function to make a proposal to work for the Dao
    /// @param _recipient The beneficiary of the proposal amount
    /// @param _amount The amount (in wei) to be sent if the proposal is approved
    /// @param _description String describing the proposal
    /// @param _hashOfTheDocument The hash of the proposal document
    /// @param _totalAmountForTokenReward Total amount if the proposal foresee to reward tokens to voters (not mandatory)
    /// @param _initialTokenPriceMultiplier The quantity of rewarded contractor tokens will depend on this multiplier (not mandatory)    
    /// @param _inflationRate If 0, the token price doesn't change during the funding (not mandatory)
    /// @param _initialSupply If the recipient ask for an initial supply of contractor tokens (not mandatory)
    /// @param _MinutesDebatingPeriod Proposed period in minutes of the board meeting
    /// @return The index of the proposal
    function newContractorProposal(
        address _recipient,
        uint _amount, 
        string _description, 
        bytes32 _hashOfTheDocument,
        uint _totalAmountForTokenReward,
        uint _initialTokenPriceMultiplier, 
        uint _inflationRate,
        uint256 _initialSupply,
        uint _MinutesDebatingPeriod
    ) payable returns (uint) {

        if (_inflationRate > 1000
            || _recipient == 0
            || _amount <= 0
            || _totalAmountForTokenReward > _amount
            || _recipient == address(DaoAccountManager)
            || _recipient == address(this)) throw;

        uint _ContractorProposalID = ContractorProposals.length++;
        ContractorProposal c = ContractorProposals[_ContractorProposalID];

        c.recipient = _recipient;       
        c.initialSupply = _initialSupply;
        c.amount = _amount;
        c.description = _description;
        c.hashOfTheDocument = _hashOfTheDocument; 
        c.initialTokenPriceMultiplier = _initialTokenPriceMultiplier;
        c.inflationRate = _inflationRate;
        c.totalAmountForTokenReward = _totalAmountForTokenReward;
        
        if (lastRecipientProposalId[c.recipient] != 0) {
            
            if ((msg.sender != c.recipient 
                && !ContractorAccountManager[c.recipient].IsCreator(msg.sender))
                || c.initialSupply != 0) throw;

        } else {

            AccountManager m = new AccountManager(msg.sender, address(this), c.recipient, c.initialSupply) ;
                
            ContractorAccountManager[c.recipient] = m;
            m.TransferAble();
            AccountManagerCreated(c.recipient, address(m));

        }
        lastRecipientProposalId[c.recipient] = _ContractorProposalID;
        
        if (c.totalAmountForTokenReward != 0) {
            
            uint _setDeadLine = now + (DaoRules.minutesSetProposalPeriod * 1 minutes);
            ContractorAccountManager[c.recipient].setFundingRules(address(this), false, 
                c.initialTokenPriceMultiplier, c.totalAmountForTokenReward, 
                _setDeadLine, _MinutesDebatingPeriod, c.inflationRate, _ContractorProposalID);

        }
        
        numberOfRecipientOpenedProposals[c.recipient] += 1;

        c.BoardMeetingID = newBoardMeeting(_ContractorProposalID, 0, 0, _MinutesDebatingPeriod);    

        ContractorProposalAdded(c.BoardMeetingID, _ContractorProposalID, c.recipient, c.amount);
        
        return _ContractorProposalID;
        
    }

    /// @notice Function to make a proposal for a funding of the Dao
    /// @param _publicShareCreation True if crowdfunding
    /// @param _mainPartner The address of the funding contract if private (not mandatory if public)
    /// @param _maxFundingAmount The maximum amount to fund
    /// @param _sharePriceMultiplier The quantity of created tokens will depend on this multiplier
    /// @param _inflationRate If 0, the token price doesn't change during the funding (not mandatory)
    /// @param _startTime The start time of the funding (not mandatory)
    /// @param _minutesFundingPeriod Period in minutes of the funding
    /// @param _contractorProposalID Index of the contractor proposal (not mandatory)
    /// @param _MinutesDebatingPeriod Period in minutes of the board meeting
    /// @return The index of the proposal
    function newFundingProposal(
        bool _publicShareCreation,
        address _mainPartner,
        uint _maxFundingAmount,  
        uint _sharePriceMultiplier,    
        uint _inflationRate,
        uint _startTime,
        uint _minutesFundingPeriod,
        uint _contractorProposalID,
        uint _MinutesDebatingPeriod
    ) payable returns (uint) {

        if (_minutesFundingPeriod > 45000
            || (!_publicShareCreation && _mainPartner == 0)
            || _maxFundingAmount <= 0
            || _minutesFundingPeriod <= 0
            || _mainPartner == address(this)
            || _mainPartner == address(DaoAccountManager)
            || _sharePriceMultiplier <= 0) {
                throw;
            }

        uint _FundingProposalID = FundingProposals.length++;
        FundingProposal f = FundingProposals[_FundingProposalID];

        f.mainPartner = _mainPartner;
        f.publicShareCreation = _publicShareCreation;
        f.fundingAmount = _maxFundingAmount;
        f.sharePriceMultiplier = _sharePriceMultiplier;
        f.inflationRate = _inflationRate;
        f.contractorProposalID = _contractorProposalID;
        f.startTime = _startTime;
        f.minutesFundingPeriod = _minutesFundingPeriod;

        if (_contractorProposalID != 0) {

            ContractorProposal cf = ContractorProposals[_contractorProposalID];
            BoardMeeting b = BoardMeetings[cf.BoardMeetingID];
            if (now > b.setDeadline || b.creator != msg.sender) throw;

            cf.fundingProposalID = _FundingProposalID;

            pendingFeesWithdrawals[b.creator] += b.fees;
            b.fees = 0;

        }
        
        f.BoardMeetingID = newBoardMeeting(0, 0, _FundingProposalID, _MinutesDebatingPeriod);   

        FundingProposalAdded(f.BoardMeetingID, _FundingProposalID, 
            _maxFundingAmount, _contractorProposalID);

        return _FundingProposalID;
        
    }

    /// @notice Function to make a proposal to change the Dao rules 
    /// @param _minQuorumDivisor If 5, the minimum quorum is 20%
    /// @param _minBoardMeetingFees The amount in wei to create o proposal and organize a board meeting
    /// @param _minutesSetProposalPeriod Minimum period in minutes before a board meeting
    /// @param _minMinutesDebatePeriod The minimum period in minutes of the board meetings
    /// @param _minutesExecuteProposalPeriod The period in minutes to execute a decision after a board meeting
    /// @param _transferable True if the Dao tokens are transferable
    /// @param _MinutesDebatingPeriod Period in minutes of the board meeting
    function newDaoRulesProposal(
        uint _minQuorumDivisor, 
        uint _minBoardMeetingFees,
        uint _minutesSetProposalPeriod,
        uint _minMinutesDebatePeriod, 
        uint _minutesExecuteProposalPeriod,
        bool _transferable,
        uint _MinutesDebatingPeriod
    ) payable returns (uint) {
    
        if (_minQuorumDivisor <= 1
            || _minQuorumDivisor > 10
            || _minMinutesDebatePeriod < 10000
            || _minutesSetProposalPeriod + _minMinutesDebatePeriod +  _minutesExecuteProposalPeriod > 150000
            || _minutesExecuteProposalPeriod < 10) throw; 
        
        uint _DaoRulesProposalID = DaoRulesProposals.length++;
        Rules r = DaoRulesProposals[_DaoRulesProposalID];

        r.minQuorumDivisor = _minQuorumDivisor;
        r.minBoardMeetingFees = _minBoardMeetingFees;
        r.minutesSetProposalPeriod = _minutesSetProposalPeriod;
        r.minMinutesDebatePeriod = _minMinutesDebatePeriod;
        r.minutesExecuteProposalPeriod = _minutesExecuteProposalPeriod;
        r.transferable = _transferable;
        
        r.BoardMeetingID = newBoardMeeting(0, _DaoRulesProposalID, 0, _MinutesDebatingPeriod);     

        DaoRulesProposalAdded(r.BoardMeetingID, _DaoRulesProposalID);

        return _DaoRulesProposalID;
        
    }
    
    /// @notice Function to vote during a board meeting
    /// @param _BoardMeetingID The index of the board meeting
    /// @param _supportsProposal True if the proposal is supported
    function vote(
        uint _BoardMeetingID, 
        bool _supportsProposal
    ) onlyTokenholders {
        
        BoardMeeting b = BoardMeetings[_BoardMeetingID];
        if (b.hasVoted[msg.sender] 
            || now < b.setDeadline
            || now > b.votingDeadline 
        ) {
        throw;
        }

        b.hasVoted[msg.sender] = true;
        
        if (_supportsProposal) {
            b.yea += DaoAccountManager.balanceOf(msg.sender);
        } 
        else {
            b.nay += DaoAccountManager.balanceOf(msg.sender); 
        }

        if (b.ContractorProposalID != 0) {
            
            ContractorProposal c = ContractorProposals[b.ContractorProposalID];

            if (c.fundingProposalID != 0) throw;
            
            uint _balance = uint(DaoAccountManager.balanceOf(msg.sender));
            uint _totalSupply = uint(DaoAccountManager.TotalSupply());
            
            if (c.totalAmountForTokenReward > 0) {
                
                uint _amount = c.totalAmountForTokenReward*_balance/_totalSupply;

                AccountManager m = ContractorAccountManager[c.recipient];
                m.rewardToken(msg.sender, _amount, now);

            }

            if (b.fees > 0) {

                uint _rewardedamount = b.fees*_balance/_totalSupply;
                b.totalRewardedAmount += _rewardedamount;
                pendingFeesWithdrawals[msg.sender] += _rewardedamount;

            }

        }

        DaoAccountManager.blockTransfer(msg.sender, b.votingDeadline);

    }

    /// @notice Function to execute a board meeting decision
    /// @param _BoardMeetingID The index of the board meeting
    /// @return Whether the function was executed or not  
    function executeDecision(uint _BoardMeetingID) returns (bool) {

        BoardMeeting b = BoardMeetings[_BoardMeetingID];

        if (now < b.votingDeadline 
            || !b.open
            ) throw;
        
        uint _quorum = b.yea + b.nay;
        uint _feesGivenBack = 0;

        if (b.FundingProposalID != 0 || b.DaoRulesProposalID != 0) {
                if (b.fees > 0 && _quorum >= minQuorum()  
                ) {
                    _feesGivenBack = b.fees;
                    b.fees = 0;
                    pendingFeesWithdrawals[b.creator] += _feesGivenBack;
                }
        }        

        bool _contractorProposalFueled;

        if (b.ContractorProposalID != 0) {
            ContractorProposal c = ContractorProposals[b.ContractorProposalID];
            if (c.fundingProposalID != 0) {
                if (DaoAccountManager.fundingDateForContractor(b.ContractorProposalID) != 0) {
                _contractorProposalFueled = true;    
                }
                if (now < b.executionDeadline 
                    && !_contractorProposalFueled 
                    && BoardMeetings[FundingProposals[c.fundingProposalID].BoardMeetingID].open) {
                    return; 
                }
            }
        }
        
        b.open = false;
        if (b.ContractorProposalID != 0) numberOfRecipientOpenedProposals[c.recipient] -= 1;
        BoardMeetingClosed(_BoardMeetingID, _feesGivenBack);

        if (!takeBoardMeetingFees(_BoardMeetingID)) return;
        
        if (now > b.executionDeadline 
            || ((_quorum < minQuorum() || b.yea <= b.nay) && !_contractorProposalFueled)
            ) {
            return;
        }

        b.dateOfExecution = now;

        if (b.FundingProposalID != 0) {

            FundingProposal f = FundingProposals[b.FundingProposalID];

            DaoAccountManager.setFundingRules(f.mainPartner, f.publicShareCreation, f.sharePriceMultiplier, 
                f.fundingAmount, f.startTime, f.minutesFundingPeriod, f.inflationRate, f.contractorProposalID);

            if (f.contractorProposalID != 0 && !f.publicShareCreation) {
                ContractorProposal cf = ContractorProposals[f.contractorProposalID];
                if (cf.initialTokenPriceMultiplier != 0) {
                    ContractorAccountManager[cf.recipient].setFundingRules(f.mainPartner, false, cf.initialTokenPriceMultiplier, 
                    f.fundingAmount, f.startTime, f.minutesFundingPeriod, cf.inflationRate, f.contractorProposalID);
                }
            }
            
        }
        
        if (b.DaoRulesProposalID != 0) {

            Rules r = DaoRulesProposals[b.DaoRulesProposalID];
            DaoRules.BoardMeetingID = r.BoardMeetingID;

            DaoRules.minQuorumDivisor = r.minQuorumDivisor;
            DaoRules.minMinutesDebatePeriod = r.minMinutesDebatePeriod;
            DaoRules.minBoardMeetingFees = r.minBoardMeetingFees;
            DaoRules.minutesExecuteProposalPeriod = r.minutesExecuteProposalPeriod;
            DaoRules.minutesSetProposalPeriod = r.minutesSetProposalPeriod;

            if (r.transferable) {
                DaoRules.transferable = true;
                DaoAccountManager.TransferAble();
            }
            
        }
            
        if (b.ContractorProposalID != 0) {
            if (!DaoAccountManager.sendTo(c.recipient, c.amount)) throw;
        }

        ProposalTallied(_BoardMeetingID);

        return true;
        
    }
    
    /// @notice Function to withdraw the rewarded board meeting fees 
    /// @return Whether the withdraw was successful or not    
    function withdrawBoardMeetingFees() returns (bool) {

        uint _amount = pendingFeesWithdrawals[msg.sender];
        if (_amount <= 0) return true;
        
        pendingFeesWithdrawals[msg.sender] = 0;
        if (msg.sender.send(_amount)) {
            return true;
        } else {
            pendingFeesWithdrawals[msg.sender] = _amount;
            return false;
        }

    }

    /// @dev internal function to send to the Dao account manager smart contract the board meeting fees balance
    /// @param _boardMeetingID The index of the board meeting
    /// @return Whether the function was successful or not 
    function takeBoardMeetingFees(uint _boardMeetingID) internal returns (bool) {

        BoardMeeting b = BoardMeetings[_boardMeetingID];
        uint _amount = b.fees - b.totalRewardedAmount;
        if (_amount <= 0) return true;

        b.totalRewardedAmount = b.fees;
        if (DaoAccountManager.send(_amount)) {
            return true;
        } else {
            b.totalRewardedAmount = b.fees - _amount;
            return false;
        }

    }
        
    /// @return the number of meetings (passed or current)
    function numberOfMeetings() constant external returns (uint) {
        return BoardMeetings.length - 1;
    }
        
    /// @return The minimum quorum for a proposal to pass 
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
