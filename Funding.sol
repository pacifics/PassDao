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
 * Standard smart contract used for the funding of the Dao.
*/

import "AccountManager.sol";

contract Funding {

    struct Partner {
        // The address of the partner
        address partnerAddress; 
        // The amount that the partner wish to fund
        uint256 intentionAmount;
        // The date of the intentionamount
        uint presaleDate;
        // The funding amount according to set limits
        uint fundingAmountLimit;
        // the amount that the partner funded to the Dao
        uint fundedAmount;
        // True if the partner is in the mailing list
        bool valid;
    }

    // Address of the creator of this contract
    address public creator;
    // The account manager to fund
    AccountManager public DaoAccountManager;
    // The account manager for the reward of contractor tokens
    AccountManager public ContractorAccountManager;
    // Minimal amount to fund
    uint public minAmount;
    // Maximal amount to fund
    uint public maxAmount;
    // The start time to intend to fund
    uint public startTime;
    // The closing time to intend to fund
    uint public closingTime;
    /// Limit in amount a partner can fund
    uint public amountLimit; 
    /// The partner can fund only under a defined percentage of their ether balance 
    uint public divisorBalanceLimit;
    // True if the limits for funding are set
    bool public limitSet;
    // True if all the partners are set and the funding can start
    bool public allSet;
    // Array of partners which wish to fund 
    Partner[] public partners;
    // The index of the partners
    mapping (address => uint) public partnerID; 
    // The total funded amount (in wei) if private funding
    uint public totalFunded; 
    // The callculated sum of funding amout limits
    uint public sumOfFundingAmountLimits;
    
    // To allow the set of partners in several times
    uint fromPartner;
    // Mutex
    bool mutex;
    
    // Protects users by preventing the execution of method calls that
    // inadvertently also transferred ether
    modifier noEther() {if (msg.value > 0) throw; _}
    // The main partner for private funding is the creator of this contract
    modifier onlyCreator {if (msg.sender != address(creator)) throw; _ }

    event IntentionToFund(address partner, uint amount);
    event Fund(address partner, uint amount);
    event Refund(address partner, uint amount);
    event LimitSet();
    event AllSet();
    event Fueled();

    /// @dev Constructor function with setting
    /// @param _DaoAccountManager The Dao account manager
    /// @param _contractorAccountManager The contractor account manager for the reward of tokens
    /// @param _minAmount Minimal amount to fund
    /// @param _maxAmount Maximal amount to fund
    /// @param _startTime The start time to intend to fund
    /// @param _closingTime The closing time to intend to fund
    function Funding (
        address _creator,
        address _DaoAccountManager,
        address _contractorAccountManager,
        uint _minAmount,
        uint _maxAmount,
        uint _startTime,
        uint _closingTime
        ) {
            
        creator = _creator;
        DaoAccountManager = AccountManager(_DaoAccountManager);
        ContractorAccountManager = AccountManager(_contractorAccountManager);
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        if (_startTime == 0) {startTime = now;} else {startTime = startTime;}
        closingTime = _closingTime;
        fromPartner = 1;
        partners.length = 1; 
        
        }

    /// @notice Function to give an intention to fund the Dao
    function () {
        
        if (msg.value <= 0
            || now < startTime
            || (now > closingTime && closingTime != 0)
            || limitSet
        ) throw;
        
        if (partnerID[msg.sender] == 0) {
            uint _partnerID = partners.length++;
            Partner t = partners[_partnerID];
             
            partnerID[msg.sender] = _partnerID;
             
            t.partnerAddress = msg.sender;
            t.intentionAmount += msg.value;
            t.presaleDate = now;
        }
        else {
            partners[partnerID[msg.sender]].intentionAmount += msg.value;
            t.presaleDate = now;
        }    
        
        IntentionToFund(msg.sender, msg.value);
    }
    
    /// @dev Function used by the creator to set partners
    /// @param _valid True if the address can fund the Dao
    /// @param _from The index of the first partner to set
    /// @param _to The index of the last partner to set
    function setPartners(
            bool _valid,
            uint _from,
            uint _to
        ) noEther onlyCreator {

        if (allSet) throw;
        
        for (uint i = _from; i <= _to; i++) {
            Partner t = partners[i];
            t.valid = _valid;
        }
        
    }

    /// @dev Function used by the creator to set the funding limits
    /// @param _amountLimit Limit in amount a partner can fund
    /// @param _divisorBalanceLimit  The partner can fund 
    /// only under a defined percentage of their ether balance 
    function setLimits(
            uint _amountLimit, 
            uint _divisorBalanceLimit
    ) noEther onlyCreator {
        
        if (limitSet) throw;
         
        amountLimit = _amountLimit;
        divisorBalanceLimit = _divisorBalanceLimit;

        limitSet = true;
        
        LimitSet();
    
    }

    /// @dev Function used by the creator to close the set of limits and partners
    /// @param _to The index of the last partner
    function setFundingLimits(uint _to) noEther onlyCreator returns (bool _success) {
        
        if (!limitSet) throw;

        if (fromPartner > _to || _to > partners.length-1) throw;
        
        for (uint i = fromPartner; i <= _to; i++) {
            sumOfFundingAmountLimits -= partners[i].fundingAmountLimit;
            partners[i].fundingAmountLimit = partnerFundingLimit(i, amountLimit, divisorBalanceLimit);
            sumOfFundingAmountLimits += partners[i].fundingAmountLimit;
        }
        
        fromPartner = _to + 1;
        
        if (fromPartner >= partners.length) {
            if (sumOfFundingAmountLimits < minAmount || sumOfFundingAmountLimits > maxAmount) {
                fromPartner = 1;
                limitSet = false;
                return;
            }
            else {
                allSet = true;
                return true;
                AllSet();
            }
        }

    }

    /// @notice Function used to fund the Dao
    /// @param _from The index of the first partner
    /// @param _to The index of the last partner
    function fundDaoFor(
            uint _from,
            uint _to
        ) noEther {

        if (!allSet) throw;
        
        if (_from < 1 || _to > partners.length-1) throw;
        
        address _partner;
        uint _amountToFund;

        for (uint i = _from; i <= _to; i++) {
            
            _partner = partners[i].partnerAddress;
            _amountToFund = partners[i].fundingAmountLimit - partners[i].fundedAmount;
        
            if (_amountToFund > 0 && DaoAccountManager.buyTokenFor(_partner, _amountToFund, partners[i].presaleDate)) {
                partners[i].fundedAmount += _amountToFund;
                ContractorAccountManager.rewardToken(_partner, _amountToFund, partners[i].presaleDate);
                if (!DaoAccountManager.send(_amountToFund)) throw;
                totalFunded += _amountToFund;
            }

        }

        if (totalFunded >= minAmount && !ContractorAccountManager.IsFueled()) {
            DaoAccountManager.Fueled(true);
            ContractorAccountManager.Fueled(true); 
            Fueled();
        }

    }

    /// @notice Function used to refund the amounts above limit
    /// @param _from The index of the first partner
    /// @param _to The index of the last partner
    function refundFor(
            uint _from,
            uint _to
        ) noEther {

        if (mutex) { throw; }
        mutex = true;

        if (_from < 1 || _to > partners.length-1) throw;
        
        uint i;
        uint _amountToRefund;

        for (i = _from; i <= _to; i++) {
            if (partners[i].fundedAmount > 0 || !partners[i].valid || now > closingTime) {
                _amountToRefund = partners[i].intentionAmount - partners[i].fundedAmount;
                partners[i].intentionAmount = partners[i].fundedAmount;
                if (_amountToRefund != 0) {
                    if (!partners[i].partnerAddress.send(_amountToRefund)) throw;
                }
            }
        }

        mutex = false;
        
    }
    
    /// @dev Allow to calculate the result of the funding procedure at present time
    /// @param _amountLimit Limit in amount a partner can fund
    /// @param _divisorBalanceLimit  The partner can fund 
    /// only under a defined percentage of their ether balance 
    /// @param _from The index of the first partner
    /// @param _to The index of the last partner
    /// @return The maximum amount if all the addresses are valid partners 
    /// and fund according to their limit
    function fundingAmount(
        uint _amountLimit, 
        uint _divisorBalanceLimit,
        uint _from,
        uint _to
        ) constant returns (uint _total) {

        if (_from < 1 || _to > partners.length-1) throw;

        for (uint i = _from; i <= _to; i++) {
            _total += partnerFundingLimit(i, _amountLimit, _divisorBalanceLimit);
        }

    }

    /// @param _index The index of the partner
    /// @param _amountLimit Limit in amount a partner can fund
    /// @param _divisorBalanceLimit  The partner can fund 
    /// only under a defined percentage of their ether balance 
    /// @return The maximum amount the partner can fund
    function partnerFundingLimit(
        uint _index, 
        uint _amountLimit, 
        uint _divisorBalanceLimit
        ) internal returns (uint) {

        uint _amount = 0;
        uint _balanceLimit;
        
        Partner t = partners[_index];
            
        if (t.valid) {

            if (_divisorBalanceLimit > 0) {
                _balanceLimit = t.partnerAddress.balance/_divisorBalanceLimit;
                _amount = _balanceLimit;
                }

            if (_amount > _amountLimit) _amount = _amountLimit;
            
            if (_amount > t.intentionAmount) _amount = t.intentionAmount;
            
        }
        
        return _amount;
        
    }

    /// @return the number of partners who wish to fund
    function numberOfPartners() constant returns (uint) {
        return partners.length - 1;
    }

}

contract FundingCreator {
    event NewFunding(address creator, address newFunding);
    function createFunding(
        address _DaoAccountManager,
        address _contractorAccountManager,
        uint _minAmount,
        uint _maxAmount,
        uint _startTime,
        uint _closingTime
        ) returns (Funding) {
        Funding _newFunding = new Funding(
            msg.sender,
            _DaoAccountManager,
            _contractorAccountManager,
            _minAmount,
            _maxAmount,
            _startTime,
            _closingTime
        );
        NewFunding(msg.sender, address(_newFunding));
        return _newFunding;
    }
}
