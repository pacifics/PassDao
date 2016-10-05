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
        // The limit a partner can fund
        uint limit;
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
    
    bool mutex;
    
    // Protects users by preventing the execution of method calls that
    // inadvertently also transferred ether
    modifier noEther() {if (msg.value > 0) throw; _}
    // The main partner for private funding is the creator of this contract
    modifier onlyCreator {if (msg.sender != address(creator)) throw; _ }

    event IntentionToFund(address partner, uint amount);
    event Fund(address partner, uint amount);
    event Refund(address partner, uint amount);

    /// @dev Constructor function with setting
    /// @param _DaoAccountManager The Dao account manager
    /// @param _contractorAccountManager The contractor account manager for the reward of tokens
    /// @param _startTime The start time to intend to fund
    /// @param _closingTime The closing time to intend to fund
    function Funding (
        address _DaoAccountManager,
        address _contractorAccountManager,
        uint _startTime,
        uint _closingTime
        ) {
            
        creator = msg.sender;
        DaoAccountManager = AccountManager(_DaoAccountManager);
        if (_startTime == 0) {startTime = now;} else {startTime = startTime;}
        closingTime = _closingTime;
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
        }
        else {
            partners[partnerID[msg.sender]].intentionAmount += msg.value;
        }    
        
        IntentionToFund(msg.sender, msg.value);
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

    /// @notice Function to fund the Dao
    /// @param _index index of the partner
    function fundDao(uint _index) internal {

        Partner t = partners[_index];
        address _partner = t.partnerAddress;
        
        t.limit = partnerFundingLimit(_index, amountLimit, divisorBalanceLimit);
        
        uint _amountToFund = t.limit - t.fundedAmount;
        
        if (_amountToFund > 0 && DaoAccountManager.buyTokenFor(_partner, _amountToFund)) {
            t.fundedAmount += _amountToFund;
            ContractorAccountManager.rewardToken(_partner, _amountToFund);
            if (!DaoAccountManager.send(_amountToFund)) throw;
            Fund(_partner, _amountToFund);
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

        limitSet = true;

        for (uint i = _from; i <= _to; i++) {
            Partner t = partners[i];
            if (t.valid) fundDao(i);
        }
        
    }

    /// @dev Function used by the creator to close the set of partners
    function closeSet() noEther onlyCreator {
        
        if (allSet) throw;

        allSet = true;

    }

    /// @notice Function to allow the refund of wei above limit
    /// @param _index index of the partner
    function refund(uint _index) internal {
        
        Partner t = partners[_index];
        address _partner = t.partnerAddress;
        
        uint _amountToRefund = t.intentionAmount - t.fundedAmount;

        t.intentionAmount = t.fundedAmount;
        if (_amountToRefund == 0 || !_partner.send(_amountToRefund)) throw;
        
        Refund(_partner, _amountToRefund);

        }


    /// @notice Function used to refund the amounts above limit
    /// @param _from The index of the first partner
    /// @param _to The index of the last partner
    function refundFor(
            uint _from,
            uint _to
        ) noEther {

        if (!allSet && now < closingTime) throw;
        
        if (mutex) { throw; }
        mutex = true;
        
        uint i;
        Partner memory t;
        
        if (now < closingTime) {
            for (i = _from; i <= _to; i++) {
                t = partners[i];
                if (t.fundedAmount > 0 || !t.valid) refund(i);
            }
        }
        else {
            for (i = _from; i <= _to; i++) {
                refund(i);
            }
        }

        mutex = false;
        
    }
    
    /// @dev Allow to calculate the result of the funding procedure at present time
    /// @param _amountLimit Limit in amount a partner can fund
    /// @param _divisorBalanceLimit  The partner can fund 
    /// only under a defined percentage of their ether balance 
    /// @return The maximum amount if all the addresses are valid partners 
    /// and fund according to their limit
    function fundingAmount(uint _amountLimit, uint _divisorBalanceLimit) constant returns (uint _total) {

        for (uint i = 1; i < partners.length; i++) {
            _total += partnerFundingLimit(i, _amountLimit, _divisorBalanceLimit);
            }

    }

    /// @param _index The index of the partner
    /// @param _amountLimit Limit in amount a partner can fund
    /// @param _divisorBalanceLimit  The partner can fund 
    /// only under a defined percentage of their ether balance 
    /// @return The maximum amount the partner can fund
    function partnerFundingLimit(uint _index, uint _amountLimit, uint _divisorBalanceLimit) internal returns (uint) {

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
