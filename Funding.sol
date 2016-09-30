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
 * Standard smart contract used for the funding of the Dao.
*/

//import "AccountManager.sol";

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
    AccountManager public OurAccountManager;
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
    // The total of amount limits of all partners
    uint public sumOfLimits;
    // The total funded amount (in wei) if private funding
    uint public totalFunded; 
    
    // Protects users by preventing the execution of method calls that
    // inadvertently also transferred ether
    modifier noEther() {if (msg.value > 0) throw; _}
    // The main partner for private funding is the creator of this contract
    modifier onlyCreator {if (msg.sender != address(creator)) throw; _ }

    event IntentionToFund(address partner, uint amount);

    /// @dev Constructor function with setting
    /// @param _ourAccountManager The Dao account manager
    /// @param _startTime The start time to intend to fund
    /// @param _closingTime The closing time to intend to fund
    function Funding (
        address _ourAccountManager,
        uint _startTime,
        uint _closingTime
        ) {
            
        creator = msg.sender;
        OurAccountManager = AccountManager(_ourAccountManager);
        if (_startTime == 0) {startTime = now;} else {startTime = startTime;}
        closingTime = _closingTime;
        partners.length = 1; 
        
        }

    /// @notice Function to give an intention to fund the Dao
    function () {
        
        if (msg.value <= 0
            || now < startTime
            || (now > closingTime && closingTime != 0)
            || allSet
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
    /// @param _from The index of the first partner to set
    /// @param _to The index of the last partner to set
    function setPartners(
            uint _from,
            uint _to
        ) noEther onlyCreator {

        if (now < closingTime 
            || allSet) {
                throw;
        }
        
        limitSet = true;
        for (uint i = _from; i <= _to; i++) {
            Partner t = partners[i];
            t.valid = true;
            t.limit = partnerFundingLimit(i, amountLimit, divisorBalanceLimit);
            sumOfLimits += t.limit;
        }
        
    }

    /// @dev Function used by the creator to close the set of partners
    function closeSet() noEther onlyCreator {
        
        if (allSet) throw;

        allSet = true;
        closingTime = now;

    }

    /// @notice Function to fund the Dao
    function fundDao() noEther {

        uint _index = partnerID[msg.sender];
        Partner t = partners[_index];
        
        if (!t.valid || _index == 0) throw;
        
        uint _amountToFund;
        
        if (t.intentionAmount < t.limit) {
            _amountToFund = t.intentionAmount - t.fundedAmount;
        }
        else {
            _amountToFund = t.limit - t.fundedAmount;
        }
        
        if (_amountToFund > 0 && OurAccountManager.buyTokenFor(msg.sender, _amountToFund)) {
            t.fundedAmount += _amountToFund;
            if (!OurAccountManager.send(_amountToFund)) throw;
        }
        
    }

    /// @notice Function to allow the refund of wei above limit
    function refund() noEther {

        uint _index = partnerID[msg.sender];
        if (_index == 0) throw;
        
        Partner t = partners[_index];

        uint _amountToRefund = msg.value + t.intentionAmount - t.fundedAmount;

        t.intentionAmount = t.fundedAmount;
        if (_amountToRefund == 0 || !msg.sender.send(_amountToRefund)) throw;

        }

    /// @dev Allow to calculate the result of the funding procedure at present time
    /// @param _amountLimit Limit in amount a partner can fund
    /// @param _divisorBalanceLimit  The partner can fund 
    /// only under a defined percentage of their ether balance 
    /// @return The maximum amount if all the addresses are valid partners 
    /// and fund according to their limit
    function maxTotalFundingAmount(uint _amountLimit, uint _divisorBalanceLimit) constant returns (uint) {

        uint _total;
        uint _amount;
        uint _balanceLimit;

        for (uint i = 1; i < partners.length; i++) {

            Partner t = partners[i];

            if (_divisorBalanceLimit > 0) {
                _balanceLimit = t.partnerAddress.balance/_divisorBalanceLimit;
                _amount = _balanceLimit;
                }

            if (_amount > _amountLimit) _amount = _amountLimit;

            _total += _amount;

        }
        
        return _total;
        
    }

    /// @param _index The index of the partner
    /// @param _amountLimit Limit in amount a partner can fund
    /// @param _divisorBalanceLimit  The partner can fund 
    /// only under a defined percentage of their ether balance 
    /// @return The maximum amount the partner can fund
    function partnerFundingLimit(uint _index, uint _amountLimit, uint _divisorBalanceLimit) internal returns (uint) {

        uint _amount;
        uint _balanceLimit;
        
        Partner t = partners[_index];
            
        if (_divisorBalanceLimit > 0) {
            _balanceLimit = t.partnerAddress.balance/_divisorBalanceLimit;
            _amount = _balanceLimit;
            }

        if (_amount > _amountLimit) _amount = _amountLimit;
        
        return _amount;
        
    }

    /// @return the number of partners who wish to fund
    function numberOfPartners() constant returns (uint) {
        return partners.length - 1;
    }
    
    /// @param _partner The address of the partner who wish to fund
    /// @return the amount to fund
    function amountToFund(address _partner) constant returns (uint) {

        return partners[partnerID[_partner]].limit;

    }

}

