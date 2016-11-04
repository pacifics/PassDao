import "PassAccountManager.sol";

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
contract PassDAOInterface {

    struct BoardMeeting {        
        // Address who created the board meeting for a proposal
        address creator;  
        // Index to identify the proposal to pay a contractor
        uint contractorProposalID;
        // Index to identify the proposal to update the Dao rules 
        uint daoRulesProposalID; 
        // Index to identify the proposal for a funding of the Dao
        uint fundingProposalID;
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

    struct ContractorProposal {
        // Index to identify the board meeting of the proposal
        uint boardMeetingID;
        // The address of the recipient where the `amount` will go to if the proposal is accepted
        address recipient;
        // The amount (in wei) to transfer to `recipient` if the proposal is accepted.
        uint amount; 
        // A description of the proposal
        string description;
        // The hash of the proposal's document
        bytes32 hashOfTheDocument;
        // The initial price multiplier of the contractor token
        uint initialTokenPriceMultiplier;
        // The inflation rate to calculate the actual contractor token price
        uint inflationRate;
        // The initial supply of contractor tokens for the recipient
        uint256 initialSupply;
        // The index of the funding proposal if linked to the contractor proposal
        uint fundingProposalID;
    }
    
    struct FundingProposal {
        // Index to identify the board meeting of the proposal
        uint boardMeetingID;
        // True if crowdfunding
        bool publicShareCreation; 
        // The address which set partners and manage the funding in case of private funding
        address mainPartner;
        // The maximum amount (in wei) to fund
        uint maxFundingAmount; 
        // The initial price multiplier of Dao shares
        uint initialSharePriceMultiplier; 
        // The inflation rate to calculate the actual contractor share price
        uint inflationRate;
        // A unix timestamp, denoting the start time of the funding
        uint minutesFundingPeriod;
        // Index of the contractor proposal if linked to the funding proposal
        uint contractorProposalID;
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
        // True if the dao rules allow the transfer of shares
        bool transferable;
    } 

    // The minimum periods in minutes 
    uint public minMinutesPeriods;
    // The maximum period in minutes for proposals (set+debate)
    uint public maxMinutesProposalPeriod;
    // The maximum funding period in minutes for funding proposals
    uint public maxMinutesFundingPeriod;
    // The maximum inflation rate for contractor and funding proposals
    uint public maxInflationRate;

    // The Dao account manager smart contract
    PassAccountManager public daoAccountManager;
    
    // Map to allow the share holders to withdraw board meeting fees
    mapping (address => uint) public pendingFeesWithdrawals;
    // Map to get the account management smart contract of contractors
    mapping (address => address) public accountManagerAddress; 

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
    
    event ContractorProposalAdded(uint indexed ContractorProposalID, address indexed AccountManagerAddress, uint ProposalAmount);
    event FundingProposalAdded(uint indexed FundingProposalID, uint ContractorProposalID, uint MaxFundingAmount);
    event DaoRulesProposalAdded(uint indexed DaoRulesProposalID);
    event SentToContractor(address indexed AccountManagerAddress, uint AmountSent);
    event BoardMeetingClosed(uint indexed BoardMeetingID, uint FeesGivenBack, bool Executed);

    /// @dev The constructor function
    /// @param _creator The creator of the Dao
    /// @param _maxInflationRate The maximum inflation rate for contractor and funding proposals
    /// @param _minMinutesPeriods The minimum periods in minutes
    /// @param _maxMinutesFundingPeriod The maximum funding period in minutes for funding proposals
    /// @param _maxMinutesProposalPeriod The maximum period in minutes for proposals (set+debate)
    //function PassDAO(
        //address _creator,
        //uint _maxInflationRate,
        //uint _minMinutesPeriods,
        //uint _maxMinutesFundingPeriod,
        //uint _maxMinutesProposalPeriod
    //);
    
    /// @dev Internal function to create a board meeting
    /// @param _contractorProposalID The index of the proposal if contractor
    /// @param _daoRulesProposalID The index of the proposal if Dao rules
    /// @param _fundingProposalID The index of the proposal if funding
    /// @param _minutesDebatingPeriod The duration in minutes of the meeting
    /// @return the index of the board meeting
    function newBoardMeeting(
        uint _contractorProposalID, 
        uint _daoRulesProposalID, 
        uint _fundingProposalID, 
        uint _minutesDebatingPeriod
    ) internal returns (uint);
    
    /// @notice Function to make a proposal to work for the Dao
    /// @param _recipient The beneficiary of the proposal amount
    /// @param _amount The amount (in wei) to be sent if the proposal is approved
    /// @param _description String describing the proposal
    /// @param _hashOfTheDocument The hash of the proposal document
    /// @param _initialTokenPriceMultiplier The initial price multiplier of contractor tokens (not mandatory)    
    /// @param _inflationRate If 0, the contractor token price doesn't change during the funding (not mandatory)
    /// @param _initialSupply If the contractor asks for an initial supply of contractor tokens (not mandatory)
    /// @param _minutesDebatingPeriod Proposed period in minutes of the board meeting to vote on the proposal
    /// @return The index of the proposal
    function newContractorProposal(
        address _recipient,
        uint _amount, 
        string _description, 
        bytes32 _hashOfTheDocument,
        uint _initialTokenPriceMultiplier, 
        uint _inflationRate,
        uint256 _initialSupply,
        uint _minutesDebatingPeriod
    ) payable returns (uint);

    /// @notice Function to make a proposal for a funding of the Dao
    /// @param _publicShareCreation True if crowdfunding
    /// @param _mainPartner The address of the funding contract if private (not mandatory if public)
    /// @param _maxFundingAmount The maximum amount to fund
    /// @param _initialSharePriceMultiplier The initial price multiplier of shares
    /// @param _inflationRate If 0, the share price doesn't change during the funding (not mandatory)
    /// @param _minutesFundingPeriod Period in minutes of the funding
    /// @param _contractorProposalID Index of the contractor proposal if linked to this funding proposal (not mandatory)
    /// @param _minutesDebatingPeriod Period in minutes of the board meeting to vote on the proposal
    /// @return The index of the proposal
    function newFundingProposal(
        bool _publicShareCreation,
        address _mainPartner,
        uint _maxFundingAmount,  
        uint _initialSharePriceMultiplier,    
        uint _inflationRate,
        uint _minutesFundingPeriod,
        uint _contractorProposalID,
        uint _minutesDebatingPeriod
    ) payable returns (uint);

    /// @notice Function to make a proposal to change the Dao rules 
    /// @param _minQuorumDivisor If 5, the minimum quorum is 20%
    /// @param _minBoardMeetingFees The amount (in wei) to make a proposal and ask for a board meeting
    /// @param _minutesSetProposalPeriod Minimum period in minutes before a board meeting
    /// @param _minMinutesDebatePeriod The minimum period in minutes of the board meetings
    /// @param _transferable True if the proposal foresee to allow the transfer of Dao shares
    /// @param _minutesDebatingPeriod Period in minutes of the board meeting to vote on the proposal
    function newDaoRulesProposal(
        uint _minQuorumDivisor, 
        uint _minBoardMeetingFees,
        uint _minutesSetProposalPeriod,
        uint _minMinutesDebatePeriod, 
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
    
    /// @notice Function to withdraw the rewarded board meeting fees
    /// @return Whether the withdraw was successful or not    
    function withdrawBoardMeetingFees() returns (bool);

    /// @dev Internal function to send to the Dao account manager the board meeting fees balance
    /// @param _boardMeetingID The index of the board meeting
    /// @return Whether the function was successful or not 
    function takeBoardMeetingFees(uint _boardMeetingID) internal returns (bool);

    /// @return The minimum quorum for proposals to pass 
    function minQuorum() constant returns (uint);

}

contract PassDAO is PassDAOInterface {

    function PassDAO(
        address _creator,
        uint _maxInflationRate,
        uint _minMinutesPeriods,
        uint _maxMinutesFundingPeriod,
        uint _maxMinutesProposalPeriod
        ) {

        daoAccountManager = new PassAccountManager(_creator, address(this), 0, 10);

        maxInflationRate = _maxInflationRate;
        minMinutesPeriods = _minMinutesPeriods;
        maxMinutesFundingPeriod = _maxMinutesFundingPeriod;
        maxMinutesProposalPeriod = _maxMinutesProposalPeriod;
        
        DaoRules.minQuorumDivisor = 5;

        BoardMeetings.length = 1; 
        ContractorProposals.length = 1;
        FundingProposals.length = 1;
        DaoRulesProposals.length = 1;
        
    }
    
    function newBoardMeeting(
        uint _contractorProposalID, 
        uint _daoRulesProposalID, 
        uint _fundingProposalID, 
        uint _minutesDebatingPeriod
    ) internal returns (uint) {

        if (msg.value < DaoRules.minBoardMeetingFees
            || DaoRules.minutesSetProposalPeriod + _minutesDebatingPeriod > maxMinutesProposalPeriod
            || _minutesDebatingPeriod < DaoRules.minMinutesDebatePeriod
            || msg.sender == address(this)) {
            throw;
        }

        uint _boardMeetingID = BoardMeetings.length++;
        BoardMeeting b = BoardMeetings[_boardMeetingID];

        b.creator = msg.sender;

        b.contractorProposalID = _contractorProposalID;
        b.daoRulesProposalID = _daoRulesProposalID;
        b.fundingProposalID = _fundingProposalID;

        b.fees = msg.value;
        
        b.setDeadline = now + (DaoRules.minutesSetProposalPeriod * 1 minutes);        
        b.votingDeadline = b.setDeadline + (_minutesDebatingPeriod * 1 minutes); 

        if (b.votingDeadline < now) throw;

        b.open = true; 

        return _boardMeetingID;

    }

    function newContractorProposal(
        address _recipient,
        uint _amount, 
        string _description, 
        bytes32 _hashOfTheDocument,
        uint _initialTokenPriceMultiplier, 
        uint _inflationRate,
        uint256 _initialSupply,
        uint _minutesDebatingPeriod
    ) payable returns (uint) {

        if (_inflationRate > maxInflationRate
            || _recipient == 0
            || _recipient == address(this)
            || _recipient == address(daoAccountManager)
            || _amount == 0
            || (accountManagerAddress[_recipient] != 0 
                && ((msg.sender != _recipient && !PassAccountManager(accountManagerAddress[_recipient]).IsCreator(msg.sender))
                    || _initialSupply != 0))
            ) throw;

        uint _contractorProposalID = ContractorProposals.length++;
        ContractorProposal c = ContractorProposals[_contractorProposalID];

        c.recipient = _recipient;       
        c.initialSupply = _initialSupply;
        c.amount = _amount;
        c.description = _description;
        c.hashOfTheDocument = _hashOfTheDocument; 
        c.initialTokenPriceMultiplier = _initialTokenPriceMultiplier;
        c.inflationRate = _inflationRate;
        
        if (accountManagerAddress[_recipient] == 0) {
            PassAccountManager m = new PassAccountManager(msg.sender, address(this), _recipient, _initialSupply) ;
            accountManagerAddress[_recipient] = address(m);
        }

        c.boardMeetingID = newBoardMeeting(_contractorProposalID, 0, 0, _minutesDebatingPeriod);    

        ContractorProposalAdded(_contractorProposalID, accountManagerAddress[c.recipient], c.amount);
        
        return _contractorProposalID;
        
    }

    function newFundingProposal(
        bool _publicShareCreation,
        address _mainPartner,
        uint _maxFundingAmount,  
        uint _initialSharePriceMultiplier,    
        uint _inflationRate,
        uint _minutesFundingPeriod,
        uint _contractorProposalID,
        uint _minutesDebatingPeriod
    ) payable returns (uint) {

        if (_inflationRate > maxInflationRate
            || _minutesFundingPeriod < minMinutesPeriods
            || _minutesFundingPeriod > maxMinutesFundingPeriod
            || (!_publicShareCreation && _mainPartner == 0)
            || _mainPartner == address(this)
            || _mainPartner == address(daoAccountManager)
            || (_contractorProposalID == 0 && _maxFundingAmount == 0)
            || (_contractorProposalID != 0 && _maxFundingAmount != 0)
            || _initialSharePriceMultiplier == 0
            ) {
                throw;
            }

        uint _fundingProposalID = FundingProposals.length++;
        FundingProposal f = FundingProposals[_fundingProposalID];

        f.mainPartner = _mainPartner;
        f.publicShareCreation = _publicShareCreation;
        f.maxFundingAmount = _maxFundingAmount;
        f.initialSharePriceMultiplier = _initialSharePriceMultiplier;
        f.inflationRate = _inflationRate;
        f.contractorProposalID = _contractorProposalID;
        f.minutesFundingPeriod = _minutesFundingPeriod;

        if (_contractorProposalID != 0) {

            ContractorProposal cf = ContractorProposals[_contractorProposalID];
            BoardMeeting b = BoardMeetings[cf.boardMeetingID];
            if (now > b.setDeadline || b.creator != msg.sender) throw;

            cf.fundingProposalID = _fundingProposalID;
            
            f.maxFundingAmount = cf.amount;

            uint _fees = b.fees;
            b.fees = 0;
            pendingFeesWithdrawals[b.creator] += _fees;
            
        }
        
        f.boardMeetingID = newBoardMeeting(0, 0, _fundingProposalID, _minutesDebatingPeriod);   

        FundingProposalAdded(_fundingProposalID, _contractorProposalID, f.maxFundingAmount);

        return _fundingProposalID;
        
    }

    function newDaoRulesProposal(
        uint _minQuorumDivisor, 
        uint _minBoardMeetingFees,
        uint _minutesSetProposalPeriod,
        uint _minMinutesDebatePeriod, 
        bool _transferable,
        uint _minutesDebatingPeriod
    ) payable returns (uint) {
    
        if (_minQuorumDivisor <= 1
            || _minQuorumDivisor > 10
            || _minutesSetProposalPeriod < minMinutesPeriods
            || _minMinutesDebatePeriod < minMinutesPeriods
            || _minutesSetProposalPeriod + _minMinutesDebatePeriod > maxMinutesProposalPeriod
            ) throw; 
        
        uint _DaoRulesProposalID = DaoRulesProposals.length++;
        Rules r = DaoRulesProposals[_DaoRulesProposalID];

        r.minQuorumDivisor = _minQuorumDivisor;
        r.minBoardMeetingFees = _minBoardMeetingFees;
        r.minutesSetProposalPeriod = _minutesSetProposalPeriod;
        r.minMinutesDebatePeriod = _minMinutesDebatePeriod;
        r.transferable = _transferable;
        
        r.boardMeetingID = newBoardMeeting(0, _DaoRulesProposalID, 0, _minutesDebatingPeriod);     

        DaoRulesProposalAdded(_DaoRulesProposalID);

        return _DaoRulesProposalID;
        
    }
    
    function vote(
        uint _boardMeetingID, 
        bool _supportsProposal
    ) {
        
        BoardMeeting b = BoardMeetings[_boardMeetingID];
        if (
            daoAccountManager.balanceOf(msg.sender) == 0|| 
            b.hasVoted[msg.sender] 
            || now < b.setDeadline
            || now > b.votingDeadline) throw;

        b.hasVoted[msg.sender] = true;
        
        if (_supportsProposal) {
            b.yea += daoAccountManager.balanceOf(msg.sender);
        } 
        else {
            b.nay += daoAccountManager.balanceOf(msg.sender); 
        }

        if (b.contractorProposalID != 0) {
            
            ContractorProposal c = ContractorProposals[b.contractorProposalID];

            if (c.fundingProposalID != 0) throw;
            
            if (b.fees > 0) {

                uint _rewardedamount = b.fees*uint(daoAccountManager.balanceOf(msg.sender))/uint(daoAccountManager.TotalSupply());
                
                b.totalRewardedAmount += _rewardedamount;
                pendingFeesWithdrawals[msg.sender] += _rewardedamount;

            }

        }

        daoAccountManager.blockTransfer(msg.sender, b.votingDeadline);

    }

    function executeDecision(uint _boardMeetingID) returns (bool) {

        BoardMeeting b = BoardMeetings[_boardMeetingID];

        if (now < b.votingDeadline 
            || !b.open
            ) throw;
        
        uint _fees;
        uint _fundedAmount;

        if (b.fundingProposalID != 0 || b.daoRulesProposalID != 0) {
                if (b.fees > 0 && b.yea + b.nay >= minQuorum()) {
                    _fees = b.fees;
                    b.fees = 0;
                    pendingFeesWithdrawals[b.creator] += _fees;
                }
        }        
        else {
            
            ContractorProposal c = ContractorProposals[b.contractorProposalID];
            
            if (c.fundingProposalID != 0) {

                _fundedAmount = daoAccountManager.FundedAmount(c.fundingProposalID);
                
                if (_fundedAmount < c.amount 
                    && (BoardMeetings[FundingProposals[c.fundingProposalID].boardMeetingID].open
                        || (BoardMeetings[FundingProposals[c.fundingProposalID].boardMeetingID].dateOfExecution != 0
                            && now < BoardMeetings[FundingProposals[c.fundingProposalID].boardMeetingID].dateOfExecution 
                            + (FundingProposals[c.fundingProposalID].minutesFundingPeriod * 1 minutes)))) {
                    return;
                }
                            
            }
            
        }

        if (!takeBoardMeetingFees(_boardMeetingID)) throw;
        
        b.open = false;

        if ((b.yea + b.nay < minQuorum() || b.yea <= b.nay) && (_fundedAmount < c.amount || c.fundingProposalID == 0)) {
            BoardMeetingClosed(_boardMeetingID, _fees, false);
            return;
        }

        b.dateOfExecution = now;

        if (b.fundingProposalID != 0) {

            FundingProposal f = FundingProposals[b.fundingProposalID];

            daoAccountManager.setFundingRules(f.mainPartner, f.publicShareCreation, f.initialSharePriceMultiplier, 
                f.maxFundingAmount, now, f.minutesFundingPeriod, f.inflationRate, b.fundingProposalID);

            if (f.contractorProposalID != 0 && !f.publicShareCreation) {
                ContractorProposal cf = ContractorProposals[f.contractorProposalID];
                
                if (cf.initialTokenPriceMultiplier != 0) {
                    PassAccountManager(accountManagerAddress[cf.recipient]).setFundingRules(f.mainPartner, false, cf.initialTokenPriceMultiplier, 
                    f.maxFundingAmount, now, f.minutesFundingPeriod, cf.inflationRate, b.fundingProposalID);
                }
            }
            
        }
        
        if (b.daoRulesProposalID != 0) {

            Rules r = DaoRulesProposals[b.daoRulesProposalID];
            DaoRules.boardMeetingID = r.boardMeetingID;

            DaoRules.minQuorumDivisor = r.minQuorumDivisor;
            DaoRules.minMinutesDebatePeriod = r.minMinutesDebatePeriod;
            DaoRules.minBoardMeetingFees = r.minBoardMeetingFees;
            DaoRules.minutesSetProposalPeriod = r.minutesSetProposalPeriod;

            if (r.transferable) {
                DaoRules.transferable = true;
                daoAccountManager.TransferAble();
            }
            
        }
            
        if (b.contractorProposalID != 0) {

            if (c.fundingProposalID == 0) _fundedAmount == c.amount;
            if (!daoAccountManager.sendTo(PassAccountManager(accountManagerAddress[c.recipient]), _fundedAmount)) throw;
            SentToContractor(accountManagerAddress[c.recipient], _fundedAmount);

        }

        BoardMeetingClosed(_boardMeetingID, _fees, true);

        return true;
        
    }
    
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

    function takeBoardMeetingFees(uint _boardMeetingID) internal returns (bool) {

        BoardMeeting b = BoardMeetings[_boardMeetingID];
        uint _amount = b.fees - b.totalRewardedAmount;
        if (_amount <= 0) return true;

        b.totalRewardedAmount = b.fees;
        if (daoAccountManager.send(_amount)) {
            return true;
        } else {
            b.totalRewardedAmount = b.fees - _amount;
            return false;
        }

    }

    function minQuorum() constant returns (uint) {
        uint(daoAccountManager.TotalSupply()) / DaoRules.minQuorumDivisor;
    }
    
}

contract PassDAOCreator {
    event NewPassDao(address creator, address newPassDao);
    function createDAO(
        uint _maxInflationRate,
        uint _minMinutesPeriods,
        uint _maxMinutesFundingPeriod,
        uint _maxMinutesProposalPeriod
        ) returns (PassDAO) {
        PassDAO _newPassDao = new PassDAO(
            msg.sender,
            _maxInflationRate,
            _minMinutesPeriods,
            _maxMinutesFundingPeriod,
            _maxMinutesProposalPeriod
        );
        NewPassDao(msg.sender, address(_newPassDao));
        return _newPassDao;
    }
}
