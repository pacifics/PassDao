import "PassManager.sol";

pragma solidity ^0.4.2;

/*
This file is part of Pass DAO.

Pass DAO is free software: you can redistribute it and/or modify
it under the terms of the GNU lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Pass DAO is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with Pass DAO.  If not, see <http://www.gnu.org/licenses/>.
*/

/*
Smart contract for a Decentralized Autonomous Organization (DAO)
to automate organizational governance and decision-making.
*/

/// @title Pass Decentralized Autonomous Organisation
contract PassDaoInterface {

    struct BoardMeeting {        
        // Address who created the board meeting for a proposal
        address creator;  
        // Index to identify the proposal to pay a contractor or fund the Dao
        uint proposalID;
        // Index to identify the proposal to update the Dao rules 
        uint daoRulesProposalID; 
        // unix timestamp, denoting the end of the set period of a proposal before the board meeting 
        uint setDeadline;
        // Fees (in wei) paid by the creator of the board meeting
        uint fees;
        // Total of fees (in wei) rewarded to the voters or to the Dao account manager for the balance
        uint totalRewardedAmount;
        // A unix timestamp, denoting the end of the voting period
        uint votingDeadline;
        // True if the proposal's votes have yet to be counted, otherwise False
        bool open; 
        // A unix timestamp, denoting the date of the execution of the approved proposal
        uint dateOfExecution;
        // Number of shares in favor of the proposal
        uint yea; 
        // Number of shares opposed to the proposal
        uint nay; 
        // mapping to indicate if a shareholder has voted
        mapping (address => bool) hasVoted;  
    }

    struct Proposal {
        // Index to identify the board meeting of the proposal
        uint boardMeetingID;
        // The contractor manager smart contract
        PassManager contractorManager;
        // The index of the contractor proposal
        uint contractorProposalID;
        // The amount (in wei) of the proposal
        uint amount; 
        // True if the proposal foresee a contractor token creation
        bool tokenCreation;
        // True if crowdfunding
        bool publicShareCreation; 
        // The address which set partners and manage the funding in case of private funding
        address mainPartner;
        // The initial price multiplier of Dao shares
        uint initialSharePriceMultiplier; 
        // The inflation rate to calculate the actual contractor share price
        uint inflationRate;
        // A unix timestamp, denoting the start time of the funding
        uint minutesFundingPeriod;
        // True if the proposal is closed
        bool open; 
    }

    struct Rules {
        // Index to identify the board meeting that decided to apply the rules
        uint boardMeetingID;  
        // The quorum needed for each proposal is calculated by totalSupply / minQuorumDivisor
        uint minQuorumDivisor;  
        // Minimum fees (in wei) to create a proposal
        uint minBoardMeetingFees; 
        // Period in minutes to consider or set a proposal before the voting procedure
        uint minutesSetProposalPeriod; 
        // The minimum debate period in minutes that a generic proposal can have
        uint minMinutesDebatePeriod;
        // The inflation rate to calculate the reward of fees to voters during a board meeting 
        uint feesRewardInflationRate;
        // True if the dao rules allow the transfer of shares
        bool transferable;
    } 

    // The creator of the Dao
    address public creator;
    // The minimum periods in minutes 
    uint public minMinutesPeriods;
    // The maximum period in minutes for proposals (set+debate)
    uint public maxMinutesProposalPeriod;
    // The maximum funding period in minutes for funding proposals
    uint public maxMinutesFundingPeriod;
    // The maximum inflation rate for contractor and funding proposals
    uint public maxInflationRate;

    // The Dao manager smart contract
    PassManager public daoManager;
    
    // Map to allow the share holders to withdraw board meeting fees
    mapping (address => uint) public pendingFeesWithdrawals;

    // Board meetings to vote for or against a proposal
    BoardMeeting[] public BoardMeetings; 
    // Proposals to pay a contractor
    Proposal[] public Proposals;
    // Proposals to pay a contractor or for fund the Dao
    Rules[] public DaoRulesProposals;
    // The current Dao rules
    Rules public DaoRules; 
    
    /// @dev The constructor function
    //function PassDao();

    /// @dev Function to initialize the Dao
    /// @param _daoManager Address of the Dao manager smart contract
    /// @param _maxInflationRate The maximum inflation rate for contractor and funding proposals
    /// @param _minMinutesPeriods The minimum periods in minutes
    /// @param _maxMinutesFundingPeriod The maximum funding period in minutes for funding proposals
    /// @param _maxMinutesProposalPeriod The maximum period in minutes for proposals (set+debate)
    /// @param _minQuorumDivisor The initial minimum quorum divisor for the proposals
    /// @param _minBoardMeetingFees The amount (in wei) to make a proposal and ask for a board meeting
    /// @param _minutesSetProposalPeriod Minimum period in minutes before a board meeting
    /// @param _minMinutesDebatePeriod The minimum period in minutes of the board meetings
    /// @param _feesRewardInflationRate The inflation rate to calculate the reward of fees to voters during a board meeting
    function initDao(
        address _daoManager,
        uint _maxInflationRate,
        uint _minMinutesPeriods,
        uint _maxMinutesFundingPeriod,
        uint _maxMinutesProposalPeriod,
        uint _minQuorumDivisor,
        uint _minBoardMeetingFees,
        uint _minutesSetProposalPeriod,
        uint _minMinutesDebatePeriod,
        uint _feesRewardInflationRate
        );
    
    /// @dev Internal function to create a board meeting
    /// @param _proposalID The index of the proposal if contractor
    /// @param _daoRulesProposalID The index of the proposal if Dao rules
    /// @param _minutesDebatingPeriod The duration in minutes of the meeting
    /// @return the index of the board meeting
    function newBoardMeeting(
        uint _proposalID, 
        uint _daoRulesProposalID, 
        uint _minutesDebatingPeriod
    ) internal returns (uint);
    
    /// @notice Function to make a proposal to pay a contractor or fund the Dao
    /// @param _contractorManager Address of the contractor manager smart contract
    /// @param _contractorProposalID Index of the contractor proposal
    /// @param _amount The amount (in wei) of the proposal
    /// @param _publicShareCreation True if crowdfunding
    /// @param _mainPartner The address of the funding contract if private (not mandatory if public)
    /// @param _initialSharePriceMultiplier The initial price multiplier of shares
    /// @param _inflationRate If 0, the share price doesn't change during the funding (not mandatory)
    /// @param _minutesFundingPeriod Period in minutes of the funding
    /// @param _minutesDebatingPeriod Period in minutes of the board meeting to vote on the proposal
    /// @return The index of the proposal
    function newProposal(
        address _contractorManager,
        uint _contractorProposalID,
        uint _amount, 
        bool _publicShareCreation,
        address _mainPartner,
        uint _initialSharePriceMultiplier, 
        uint _inflationRate,
        uint _minutesFundingPeriod,
        uint _minutesDebatingPeriod
    ) payable returns (uint);

    /// @notice Function to make a proposal to change the Dao rules 
    /// @param _minQuorumDivisor If 5, the minimum quorum is 20%
    /// @param _minBoardMeetingFees The amount (in wei) to make a proposal and ask for a board meeting
    /// @param _minutesSetProposalPeriod Minimum period in minutes before a board meeting
    /// @param _minMinutesDebatePeriod The minimum period in minutes of the board meetings
    /// @param _feesRewardInflationRate The inflation rate to calculate the reward of fees to voters during a board meeting
    /// @param _transferable True if the proposal foresee to allow the transfer of Dao shares
    /// @param _minutesDebatingPeriod Period in minutes of the board meeting to vote on the proposal    function newDaoRulesProposal(
    function newDaoRulesProposal(
        uint _minQuorumDivisor, 
        uint _minBoardMeetingFees,
        uint _minutesSetProposalPeriod,
        uint _minMinutesDebatePeriod,
        uint _feesRewardInflationRate,
        bool _transferable,
        uint _minutesDebatingPeriod
    ) payable returns (uint);
    
    /// @notice Function to vote during a board meeting
    /// @param _boardMeetingID The index of the board meeting
    /// @param _supportsProposal True if the proposal is supported
    function vote(
        uint _boardMeetingID, 
        bool _supportsProposal
    );

    /// @notice Function to execute a board meeting decision and close the board meeting
    /// @param _boardMeetingID The index of the board meeting
    /// @return Whether the proposal was executed or not
    function executeDecision(uint _boardMeetingID) returns (bool);
    
    /// @notice Function to order a contractor proposal
    /// @param _proposalID The index of the proposal
    /// @return Whether the proposal was ordered and the proposal amount sent or not
    function orderContractorProposal(uint _proposalID) returns (bool);   

    /// @notice Function to withdraw the rewarded board meeting fees
    /// @return Whether the withdraw was successful or not    
    function withdrawBoardMeetingFees() returns (bool);

    /// @return The minimum quorum for proposals to pass 
    function minQuorum() constant returns (uint);
    
    event ProposalAdded(uint indexed ProposalID, address indexed ContractorManager, uint ContractorProposalID, 
        uint amount, address indexed MainPartner, uint InitialSharePriceMultiplier, uint MinutesFundingPeriod);
    event DaoRulesProposalAdded(uint indexed DaoRulesProposalID, uint MinQuorumDivisor, uint MinBoardMeetingFees, 
            uint MinutesSetProposalPeriod, uint MinMinutesDebatePeriod, uint FeesRewardInflationRate, bool Transferable);
    event SentToContractor(uint indexed ContractorProposalID, address indexed ContractorManagerAddress, uint AmountSent);
    event BoardMeetingClosed(uint indexed BoardMeetingID, uint FeesGivenBack, bool ProposalExecuted);
    
}

contract PassDao is PassDaoInterface {

    function PassDao() {}
    
    function initDao(
        address _daoManager,
        uint _maxInflationRate,
        uint _minMinutesPeriods,
        uint _maxMinutesFundingPeriod,
        uint _maxMinutesProposalPeriod,
        uint _minQuorumDivisor,
        uint _minBoardMeetingFees,
        uint _minutesSetProposalPeriod,
        uint _minMinutesDebatePeriod,
        uint _feesRewardInflationRate
        ) {
            
        
        if (DaoRules.minQuorumDivisor != 0) throw;

        daoManager = PassManager(_daoManager);

        maxInflationRate = _maxInflationRate;
        minMinutesPeriods = _minMinutesPeriods;
        maxMinutesFundingPeriod = _maxMinutesFundingPeriod;
        maxMinutesProposalPeriod = _maxMinutesProposalPeriod;
        
        DaoRules.minQuorumDivisor = _minQuorumDivisor;
        DaoRules.minBoardMeetingFees = _minBoardMeetingFees;
        DaoRules.minutesSetProposalPeriod = _minutesSetProposalPeriod;
        DaoRules.minMinutesDebatePeriod = _minMinutesDebatePeriod;
        DaoRules.feesRewardInflationRate = _feesRewardInflationRate;

        BoardMeetings.length = 1; 
        Proposals.length = 1;
        DaoRulesProposals.length = 1;
        
    }
    
    function newBoardMeeting(
        uint _proposalID, 
        uint _daoRulesProposalID, 
        uint _minutesDebatingPeriod
    ) internal returns (uint) {

        if (msg.value < DaoRules.minBoardMeetingFees
            || DaoRules.minutesSetProposalPeriod + _minutesDebatingPeriod > maxMinutesProposalPeriod
            || now + ((DaoRules.minutesSetProposalPeriod + _minutesDebatingPeriod) * 1 minutes) < now
            || _minutesDebatingPeriod < DaoRules.minMinutesDebatePeriod
            || msg.sender == address(this)) throw;

        uint _boardMeetingID = BoardMeetings.length++;
        BoardMeeting b = BoardMeetings[_boardMeetingID];

        b.creator = msg.sender;

        b.proposalID = _proposalID;
        b.daoRulesProposalID = _daoRulesProposalID;

        b.fees = msg.value;
        
        b.setDeadline = now + (DaoRules.minutesSetProposalPeriod * 1 minutes);        
        b.votingDeadline = b.setDeadline + (_minutesDebatingPeriod * 1 minutes); 

        b.open = true; 

        return _boardMeetingID;

    }

    function newProposal(
        address _contractorManager,
        uint _contractorProposalID,
        uint _amount, 
        bool _publicShareCreation,
        address _mainPartner,
        uint _initialSharePriceMultiplier, 
        uint _inflationRate,
        uint _minutesFundingPeriod,
        uint _minutesDebatingPeriod
    ) payable returns (uint) {

        if ((_contractorManager != 0 && _contractorProposalID == 0)
            || (_contractorManager == 0 
                && (_initialSharePriceMultiplier == 0
                    || _contractorProposalID != 0)
            || (_initialSharePriceMultiplier != 0
                && (_minutesFundingPeriod < minMinutesPeriods
                    || _inflationRate > maxInflationRate
                    || _minutesFundingPeriod > maxMinutesFundingPeriod)))) throw;

        uint _proposalID = Proposals.length++;
        Proposal p = Proposals[_proposalID];

        p.contractorManager = PassManager(_contractorManager);
        p.contractorProposalID = _contractorProposalID;
        
        p.amount = _amount;

        p.publicShareCreation = _publicShareCreation;
        p.mainPartner = _mainPartner;
        p.initialSharePriceMultiplier = _initialSharePriceMultiplier;
        p.inflationRate = _inflationRate;
        p.minutesFundingPeriod = _minutesFundingPeriod;

        p.boardMeetingID = newBoardMeeting(_proposalID, 0, _minutesDebatingPeriod);   

        p.open = true;
        
        ProposalAdded(_proposalID, p.contractorManager, p.contractorProposalID, p.amount, p.mainPartner, 
            p.initialSharePriceMultiplier, _minutesFundingPeriod);

        return _proposalID;
        
    }

    function newDaoRulesProposal(
        uint _minQuorumDivisor, 
        uint _minBoardMeetingFees,
        uint _minutesSetProposalPeriod,
        uint _minMinutesDebatePeriod,
        uint _feesRewardInflationRate,
        bool _transferable,
        uint _minutesDebatingPeriod
    ) payable returns (uint) {
    
        if (_minQuorumDivisor <= 1
            || _minQuorumDivisor > 10
            || _minutesSetProposalPeriod < minMinutesPeriods
            || _minMinutesDebatePeriod < minMinutesPeriods
            || _minutesSetProposalPeriod + _minMinutesDebatePeriod > maxMinutesProposalPeriod
            || _feesRewardInflationRate > maxInflationRate
            ) throw; 
        
        uint _DaoRulesProposalID = DaoRulesProposals.length++;
        Rules r = DaoRulesProposals[_DaoRulesProposalID];

        r.minQuorumDivisor = _minQuorumDivisor;
        r.minBoardMeetingFees = _minBoardMeetingFees;
        r.minutesSetProposalPeriod = _minutesSetProposalPeriod;
        r.minMinutesDebatePeriod = _minMinutesDebatePeriod;
        r.feesRewardInflationRate = _feesRewardInflationRate;
        r.transferable = _transferable;
        
        r.boardMeetingID = newBoardMeeting(0, _DaoRulesProposalID, _minutesDebatingPeriod);     

        DaoRulesProposalAdded(_DaoRulesProposalID, _minQuorumDivisor, _minBoardMeetingFees, 
            _minutesSetProposalPeriod, _minMinutesDebatePeriod, _feesRewardInflationRate ,_transferable);

        return _DaoRulesProposalID;
        
    }
    
    function vote(
        uint _boardMeetingID, 
        bool _supportsProposal
    ) {
        
        BoardMeeting b = BoardMeetings[_boardMeetingID];

        if (b.hasVoted[msg.sender] 
            || now < b.setDeadline
            || now > b.votingDeadline) throw;

        uint _balance = uint(daoManager.balanceOf(msg.sender));
        if (_balance == 0) throw;
        
        b.hasVoted[msg.sender] = true;

        if (_supportsProposal) b.yea += _balance;
        else b.nay += _balance; 

        if (b.fees > 0 && b.proposalID != 0 && Proposals[b.proposalID].contractorProposalID != 0) {

            uint _rewardedamount = b.fees * (100*_balance/uint(daoManager.TotalSupply())) / 
                (100 + 100*DaoRules.feesRewardInflationRate*(now - b.setDeadline)/(100*365 days));

            if (b.totalRewardedAmount + _rewardedamount > b.fees) _rewardedamount = b.fees - b.totalRewardedAmount;
            b.totalRewardedAmount += _rewardedamount;
            pendingFeesWithdrawals[msg.sender] += _rewardedamount;
        }

        daoManager.blockTransfer(msg.sender, b.votingDeadline);

    }

    function executeDecision(uint _boardMeetingID) returns (bool) {

        BoardMeeting b = BoardMeetings[_boardMeetingID];

        if (now < b.votingDeadline || !b.open) throw;
        
        b.open = false;
        if (Proposals[b.proposalID].contractorProposalID == 0) p.open = false;

        uint _fees;
        uint _minQuorum = minQuorum();

        if (b.fees > 0
            && (b.proposalID == 0 || Proposals[b.proposalID].contractorProposalID == 0)
            && b.yea + b.nay >= _minQuorum) {
                    _fees = b.fees;
                    b.fees = 0;
                    pendingFeesWithdrawals[b.creator] += _fees;
        }        

        if (b.fees - b.totalRewardedAmount > 0) {
            if (!daoManager.send(b.fees - b.totalRewardedAmount)) throw;
        }
        
        if (b.yea + b.nay < _minQuorum || b.yea <= b.nay) {
            p.open = false;
            BoardMeetingClosed(_boardMeetingID, _fees, false);
            return;
        }

        b.dateOfExecution = now;

        if (b.proposalID != 0) {

            Proposal p = Proposals[b.proposalID];
            
            if (p.initialSharePriceMultiplier != 0) {

                daoManager.setFundingRules(p.mainPartner, p.publicShareCreation, p.initialSharePriceMultiplier, 
                    p.amount, p.minutesFundingPeriod, p.inflationRate, b.proposalID);

                if (p.contractorProposalID != 0) {
                    p.contractorManager.setFundingRules(p.mainPartner, p.publicShareCreation, 0, 
                        p.amount, p.minutesFundingPeriod, maxInflationRate, b.proposalID);
                }

            }

        } else {

            Rules r = DaoRulesProposals[b.daoRulesProposalID];
            DaoRules.boardMeetingID = r.boardMeetingID;

            DaoRules.minQuorumDivisor = r.minQuorumDivisor;
            DaoRules.minMinutesDebatePeriod = r.minMinutesDebatePeriod; 
            DaoRules.minBoardMeetingFees = r.minBoardMeetingFees;
            DaoRules.minutesSetProposalPeriod = r.minutesSetProposalPeriod;
            DaoRules.feesRewardInflationRate = r.feesRewardInflationRate;

            DaoRules.transferable = r.transferable;
            if (r.transferable) daoManager.ableTransfer();
            else daoManager.disableTransfer();
        }
            
        BoardMeetingClosed(_boardMeetingID, _fees, true);

        return true;
        
    }
    
    function orderContractorProposal(uint _proposalID) returns (bool) {
        
        Proposal p = Proposals[_proposalID];
        BoardMeeting b = BoardMeetings[p.boardMeetingID];

        if (b.open || !p.open) throw;
        
        uint _amount = p.amount;

        if (p.initialSharePriceMultiplier != 0) {
            _amount = daoManager.FundedAmount(b.proposalID);
            if (_amount == 0 && now < b.dateOfExecution + (p.minutesFundingPeriod * 1 minutes)) return;
        }
        
        p.open = false;   

        if (_amount == 0 || !p.contractorManager.order(p.contractorProposalID, _amount)) return;
        
        if (!daoManager.sendTo(p.contractorManager, _amount)) throw;
        SentToContractor(p.contractorProposalID, address(p.contractorManager), _amount);
        
        return true;

    }
    
    function withdrawBoardMeetingFees() returns (bool) {

        uint _amount = pendingFeesWithdrawals[msg.sender];

        pendingFeesWithdrawals[msg.sender] = 0;

        if (msg.sender.send(_amount)) {
            return true;
        } else {
            pendingFeesWithdrawals[msg.sender] = _amount;
            return false;
        }

    }

    function minQuorum() constant returns (uint) {
        return (uint(daoManager.TotalSupply()) / DaoRules.minQuorumDivisor);
    }
    
}
