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
        // The weight of a partner if private funding
        uint weight;
        // True if the partner already funded
        bool hasFunded;
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
    // True if all the partners are set and the funding can start
    bool public allSet;
    // Array of partners which wish to fund 
    Partner[] public partners;
    // The index of the partners
    mapping (address => uint) public partnerID; 
    // The total weight of partners if private funding
    uint public totalWeight;
    // The total funded amount (in wei) if private funding
    uint public totalFunded; 
    
    // Protects users by preventing the execution of method calls that
    // inadvertently also transferred ether
    modifier noEther() {if (msg.value > 0) throw; _}
    // The main partner for private funding is the creator of this contract
    modifier onlyCreator {if (msg.sender != address(creator)) throw; _ }

    event IntentionToFund(address partner, uint amount);
    event AllPartnersSet(uint totalWeight);
    event PartnerSet(address partner, uint weight);
    event Funded(address partner, uint amount);

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

    /// @notice Function to fund the Dao
    function () {

        if (now <= closingTime) {
            intentionToFund(msg.value);
            if (!msg.sender.send(msg.value)) throw;
        }        
        else
        fund();
        
    }

    /// @notice Function to give an intention to fund the Dao
    /// @param _amount The amount you wish to fund
    function intentionToFund(uint256 _amount) noEther {
        
        if (_amount <= 0
            || now < startTime
            || (now > closingTime && closingTime != 0)
            || allSet
        ) throw;
        
        if (_amount>0 && partnerID[msg.sender] == 0) {
            uint _partnerID = partners.length++;
            Partner t = partners[_partnerID];
             
            partnerID[msg.sender] = _partnerID;
             
            t.partnerAddress = msg.sender;
            t.intentionAmount = _amount;
        }
        else {
            partners[partnerID[msg.sender]].intentionAmount = _amount;
        }    
        
        IntentionToFund(msg.sender, _amount);
    }
    
    /// @dev Function used by the creator to set partner
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
        
        uint _amount;
        for (uint i = _from; i < _to; i++) {
            
            Partner t = partners[i];
            if (t.weight > 0) totalWeight -= t.weight;
            _amount = partnerFundLimit(i, amountLimit, divisorBalanceLimit);
            t.weight = _amount; 
            totalWeight += _amount;
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
        
         if (allSet) throw;
         
        amountLimit = _amountLimit;
        divisorBalanceLimit = _divisorBalanceLimit;

    }

    /// @dev Function used by the creator to close the set of partners
    function closeSet() noEther onlyCreator {
        
        if (allSet) throw;

        allSet = true;
        closingTime = now;
        AllPartnersSet(totalWeight);
        
    }

    /// @dev Internal function to fund
    /// @return Whether the funded is successful or not
    function fund() internal returns (bool _success) {
        
        if (!allSet) throw;
        
        Partner t = partners[partnerID[msg.sender]];

        uint _fundingAmount = amountToFund(msg.sender);
        if (t.hasFunded 
        || msg.value > _fundingAmount
        || !OurAccountManager.send(msg.value)) throw;

        if (OurAccountManager.buyTokenFor(msg.sender, msg.value)) {
            t.hasFunded = true;
            Funded(msg.sender, msg.value);
            return true;
        }
        else throw;
        
    }

    /// @dev Allow to calculate the result of the intention procedure
    /// @param _amountLimit Limit in amount a partner can fund
    /// @param _divisorBalanceLimit  The partner can fund 
    /// only under a defined percentage of their ether balance 
    /// @return The maximum amount if all the partners fund
    function MaxFundAmount(uint _amountLimit, uint _divisorBalanceLimit) constant returns (uint) {

        uint _totalWeight;

        for (uint i = 1; i < partners.length; i++) {

            _totalWeight += partnerFundLimit(i, _amountLimit, _divisorBalanceLimit);

        }
        
        return _totalWeight;
        
    }

    /// @param _index The index of the partner
    /// @param _amountLimit Limit in amount a partner can fund
    /// @param _divisorBalanceLimit  The partner can fund 
    /// only under a defined percentage of their ether balance 
    /// @return The maximum amount the partner could fund
    function partnerFundLimit(uint _index, uint _amountLimit, uint _divisorBalanceLimit) constant returns (uint) {

        uint _amount;
        uint _balanceLimit;
        
        Partner t = partners[_index];
            
        if (_divisorBalanceLimit > 0) {
            _balanceLimit = t.partnerAddress.balance/_divisorBalanceLimit;
            if (t.intentionAmount > _balanceLimit) {
                _amount = _balanceLimit;
            }
            else _amount = t.intentionAmount;
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

        return partners[partnerID[_partner]].weight;

    }

}
