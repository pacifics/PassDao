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
 * Smart contract used for the funding of the Dao.
*/

/// @title Funding smart contract for the Pass Decentralized Autonomous Organisation
contract PassFunding {

    struct Partner {
        // The address of the partner
        address partnerAddress; 
        // The amount (in wei) that the partner wish to fund
        uint256 presaleAmount;
        // The unix timestamp denoting the average date of the presale of the partner 
        uint presaleDate;
        // The funding amount (in wei) according to the set limits
        uint fundingAmountLimit;
        // The amount (in wei) that the partner funded to the Dao
        uint fundedAmount;
        // True if the partner can fund the dao
        bool valid;
    }

    // Address of the creator of this contract
    address public creator;
    // The account manager smart contract to fund
    AccountManager public DaoAccountManager;
    // Address of the account manager smart contract for the reward of contractor tokens
    address public contractorAccountManager;
    // Minimum amount (in wei) to fund
    uint public minAmount;
    // Maximum amount (in wei) to fund
    uint public maxAmount;
    // Minimum amount (in wei) that partners can send to this smart contract
    uint public minPresaleAmount;
    // Maximum amount (in wei) that partners can send to this smart contract
    uint public maxPresaleAmount;
    // The unix start time of the presale
    uint public startTime;
    // The unix closing time of the funding
    uint public closingTime;
    /// The amount (in wei) below this limit can fund the dao
    uint minAmountLimit;
    /// Maximum amount (in wei) a partner can fund
    uint maxAmountLimit; 
    /// The partner can fund below the minimum amount limit or a set percentage of his ether balance 
    uint divisorBalanceLimit;
    // True if the amount and divisor balance limits for the funding are set
    bool public limitSet;
    // True if all the partners are set by the creator and the funding can be completed 
    bool public allSet;
    // Array of partners who wish to fund the dao
    Partner[] public partners;
    // Map with the indexes of the partners
    mapping (address => uint) public partnerID; 
    // The total funded amount (in wei)
    uint public totalFunded; 
    // The calculated sum of funding amout limits (in wei) according to the set limits
    uint sumOfFundingAmountLimits;
    
    // To allow the set of partners in several times
    uint setFromPartner;
    // To allow the refund for partners in several times
    uint refundFromPartner;

    // The manager of this funding is the creator of this contract
    modifier onlyCreator {if (msg.sender != creator) throw; _ ;}

    event IntentionToFund(address partner, uint amount);
    event Fund(address partner, uint amount);
    event Refund(address partner, uint amount);
    event LimitSet(uint minAmountLimit, uint maxAmountLimit, uint divisorBalanceLimit);
    event PartnersNotSet(uint sumOfFundingAmountLimits);
    event AllPartnersSet(uint fundingAmount);
    event Fueled();
    event FundingClosed();

    /// @dev Constructor function
    /// @param _creator The creator of the smart contract
    /// @param _DaoAccountManager The Dao account manager smart contract
    /// @param _contractorAccountManager The address of the contractor account manager smart contract  
    /// for the reward of tokens (not mandatory)
    /// @param _minAmount Minimum amount (in wei) of the funding to be fueled 
    /// @param _startTime The unix start time of the presale
    /// @param _closingTime The unix closing time of the funding
    function PassFunding (
        address _creator,
        address _DaoAccountManager,
        address _contractorAccountManager,
        uint _minAmount,
        uint _startTime,
        uint _closingTime
        ) {
            
        creator = _creator;
        DaoAccountManager = AccountManager(_DaoAccountManager);
        contractorAccountManager = _contractorAccountManager;

        minAmount = _minAmount;

        if (_startTime == 0) {startTime = now;} else {startTime = _startTime;}
        closingTime = _closingTime;
        setFromPartner = 1;
        refundFromPartner = 1;
        partners.length = 1; 
        
        }

    /// @notice Function used by the creator to set the presale limits
    /// @param _minAmount Minimum amount (in wei) that partners can send
    /// @param _maxAmount Maximum amount (in wei) that partners can send
    function SetPresaleAmountLimits(
        uint _minAmount,
        uint _maxAmount
        ) onlyCreator {

        minPresaleAmount = _minAmount;
        maxPresaleAmount = _maxAmount;

        }

    /// @notice Function to participate in the presale of the funding
    function () payable {
        
        if (msg.value <= 0
            || now < startTime
            || (now > closingTime && closingTime != 0)
            || limitSet
            || msg.value < minPresaleAmount
            || msg.value > maxPresaleAmount
            || msg.sender == creator
        ) throw;
        
        if (partnerID[msg.sender] == 0) {

            uint _partnerID = partners.length++;
            Partner t = partners[_partnerID];
             
            partnerID[msg.sender] = _partnerID;
            t.partnerAddress = msg.sender;
            
            t.presaleAmount += msg.value;
            t.presaleDate = now;

        } else {

            Partner p = partners[partnerID[msg.sender]];
            if (p.presaleAmount + msg.value > maxPresaleAmount) throw;

            p.presaleDate = (p.presaleDate*p.presaleAmount + now*msg.value)/(p.presaleAmount + msg.value);
            p.presaleAmount += msg.value;

        }    
        
        IntentionToFund(msg.sender, msg.value);
    }
    
    /// @notice Function used by the creator to set addresses that can fund the dao
    /// @param _valid True if the address can fund the Dao
    /// @param _from The index of the first partner to set
    /// @param _to The index of the last partner to set
    function setValidPartners(
            bool _valid,
            uint _from,
            uint _to
        ) onlyCreator {

        if (allSet) throw;
        
        if (_from < 1 || _to > partners.length - 1) throw;
        
        for (uint i = _from; i <= _to; i++) {
            Partner t = partners[i];
            t.valid = _valid;
        }
        
    }

    /// @notice Function used by the creator to set the funding limits for the funding
    /// @param _minAmountLimit The amount below this limit (in wei) can fund the dao
    /// @param _maxAmountLimit Maximum amount (in wei) a partner can fund
    /// @param _divisorBalanceLimit The creator can set a limit in percentage of Eth balance (not mandatory) 
    function setFundingLimits(
            uint _minAmountLimit,
            uint _maxAmountLimit, 
            uint _divisorBalanceLimit
    ) onlyCreator {
        
        if (limitSet) throw;
        
        maxAmount = DaoAccountManager.fundingMaxAmount();
        minAmountLimit = _minAmountLimit;
        maxAmountLimit = _maxAmountLimit;
        divisorBalanceLimit = _divisorBalanceLimit;

        limitSet = true;
        
        LimitSet(_minAmountLimit, _maxAmountLimit, _divisorBalanceLimit);
    
    }

    /// @notice Function used by the creator to set the funding limits for partners
    /// @param _to The index of the last partner to set
    /// @return Whether the set was successful or not
    function setPartnersFundingLimits(uint _to) onlyCreator returns (bool _success) {
        
        if (!limitSet) throw;

        if (setFromPartner > _to || _to > partners.length - 1) throw;
        
        if (setFromPartner == 1) sumOfFundingAmountLimits = 0;
        
        for (uint i = setFromPartner; i <= _to; i++) {
            partners[i].fundingAmountLimit = partnerFundingLimit(i, minAmountLimit, maxAmountLimit, divisorBalanceLimit);
            sumOfFundingAmountLimits += partners[i].fundingAmountLimit;
        }
        
        setFromPartner = _to + 1;
        
        if (setFromPartner >= partners.length) {
            setFromPartner = 1;
            if (sumOfFundingAmountLimits < minAmount || sumOfFundingAmountLimits > maxAmount) {
                limitSet = false;
                PartnersNotSet(sumOfFundingAmountLimits);
                return;
            }
            else {
                allSet = true;
                AllPartnersSet(sumOfFundingAmountLimits);
                return true;
            }
        }

    }

    /// @notice Function for the funding of the Dao by a group of partners
    /// @param _from The index of the first partner
    /// @param _to The index of the last partner
    function fundDaoFor(
            uint _from,
            uint _to
        ) {

        if (!allSet) throw;
        
        if (_from < 1 || _to > partners.length - 1) throw;
        
        address _partner;
        uint _amountToFund;
        uint _sumAmountToFund = 0;

        for (uint i = _from; i <= _to; i++) {
            
            _partner = partners[i].partnerAddress;
            _amountToFund = partners[i].fundingAmountLimit - partners[i].fundedAmount;
        
            if (_amountToFund > 0) {

                partners[i].fundedAmount += _amountToFund;
                _sumAmountToFund += _amountToFund;

                DaoAccountManager.rewardToken(_partner, _amountToFund, partners[i].presaleDate);

                if (contractorAccountManager != 0) {
                    AccountManager(contractorAccountManager).rewardToken(_partner, _amountToFund, 
                        partners[i].presaleDate);
                }

            }

        }

        if (!DaoAccountManager.send(_sumAmountToFund)) throw;

        totalFunded += _sumAmountToFund;

        if (totalFunded >= sumOfFundingAmountLimits) {
            
            DaoAccountManager.Fueled(); 
            if (contractorAccountManager != 0) AccountManager(contractorAccountManager).Fueled(); 

            Fueled();

        }

    }

    /// @notice Function to refund for a partner
    /// @param _index The index of the partner
    /// @return Whether the refund was successful or not 
    function refundFor(uint _index) internal returns (bool) {

        Partner t = partners[_index];
        uint _amountnotToRefund = t.presaleAmount;
        uint _amountToRefund;
        
        if (t.presaleAmount > maxPresaleAmount && t.valid) {
            _amountnotToRefund = maxPresaleAmount;
        }
        
        if (t.fundedAmount > 0 || now > closingTime) {
            _amountnotToRefund = t.fundedAmount;
        }

        _amountToRefund = t.presaleAmount - _amountnotToRefund;
        if (_amountToRefund <= 0) return true;

        t.presaleAmount = _amountnotToRefund;
        if (t.partnerAddress.send(_amountToRefund)) {
            Refund(t.partnerAddress, _amountToRefund);
            return true;
        } else {
            t.presaleAmount = _amountnotToRefund + _amountToRefund;
            return false;
        }

    }

    /// @notice Function to refund with 'msg.sender' as 'beneficiary'
    /// @return Whether the refund was successful or not 
    function refund() returns (bool) {
        return refundFor(partnerID[msg.sender]);
    }

    /// @notice Function to refund for valid partners
    /// @param _to The index of the last partner
    function refundForPartners(uint _to) {

        if (refundFromPartner > _to || _to > partners.length - 1) throw;
        
        for (uint i = refundFromPartner; i <= _to; i++) {
            if (partners[i].valid) {
                if (!refundFor(i)) throw;
            }
        }

        refundFromPartner = _to + 1;
        
        if (refundFromPartner >= partners.length) {
            refundFromPartner = 1;
            if (totalFunded >= sumOfFundingAmountLimits && allSet) {
                closingTime = now; 
                FundingClosed(); 
            }
        }
        
    }

    
    /// @param _minAmountLimit The amount (in wei) below this limit can fund the dao
    /// @param _maxAmountLimit Maximum amount (in wei) a partner can fund
    /// @param _divisorBalanceLimit The partner can fund 
    /// only under a defined percentage of his ether balance 
    /// @param _from The index of the first partner
    /// @param _to The index of the last partner
    /// @return The result of the funding procedure (in wei) at present time
    function estimatedFundingAmount(
        uint _minAmountLimit,
        uint _maxAmountLimit, 
        uint _divisorBalanceLimit,
        uint _from,
        uint _to
        ) constant external returns (uint) {

        if (_from < 1 || _to > partners.length - 1) throw;

        uint _total = 0;
        
        for (uint i = _from; i <= _to; i++) {
            _total += partnerFundingLimit(i, _minAmountLimit, _maxAmountLimit, _divisorBalanceLimit);
        }

        return _total;

    }

    /// @param _index The index of the partner
    /// @param _minAmountLimit The amount (in wei) below this limit can fund the dao
    /// @param _maxAmountLimit Maximum amount (in wei) a partner can fund
    /// @param _divisorBalanceLimit The partner can fund 
    /// only under a defined percentage of his ether balance 
    /// @return The maximum amount (in wei) a partner can fund
    function partnerFundingLimit(
        uint _index, 
        uint _minAmountLimit,
        uint _maxAmountLimit, 
        uint _divisorBalanceLimit
        ) internal returns (uint) {

        uint _amount = 0;

        Partner t = partners[_index];
            
        if (t.valid) {

            if (_divisorBalanceLimit > 0) {
                _amount = uint(t.partnerAddress.balance)/uint(_divisorBalanceLimit);
                }

            if (_amount > _maxAmountLimit) _amount = _maxAmountLimit;
            
            if (_amount < _minAmountLimit) _amount = _minAmountLimit;

            if (_amount > t.presaleAmount) _amount = t.presaleAmount;
            
        }
        
        return _amount;
        
    }

    /// @return the number of partners
    function numberOfPartners() constant external returns (uint) {
        return partners.length - 1;
    }
    
    /// @param _from The index of the first partner
    /// @param _to The index of the last partner
    /// @return The number of valid partners
    function numberOfValidPartners(
        uint _from,
        uint _to
        ) constant external returns (uint) {
        
        if (_from < 1 || _to > partners.length-1) throw;

        uint _total = 0;
        
        for (uint i = _from; i <= _to; i++) {
            if (partners[i].valid) _total += 1;
        }

        return _total;
        
    }

}

contract PassFundingCreator {
    event NewFunding(address creator, address newFunding);
    function createFunding(
        address _DaoAccountManager,
        address _contractorAccountManager,
        uint _minAmount,
        uint _startTime,
        uint _closingTime
        ) returns (PassFunding) {
        PassFunding _newFunding = new PassFunding(
            msg.sender,
            _DaoAccountManager,
            _contractorAccountManager,        
            _minAmount,
            _startTime,
            _closingTime
        );
        NewFunding(msg.sender, address(_newFunding));
        return _newFunding;
    }
}
