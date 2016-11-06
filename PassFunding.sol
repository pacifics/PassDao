import "PassManager.sol";

pragma solidity ^0.4.2;

/*
 *
 * This file is part of the DAO.
 *
 * Smart contract used for the funding of Pass Dao.
 *
*/

/// @title Funding smart contract for the Pass Decentralized Autonomous Organisation
contract PassFundingInterface {

    struct Partner {
        // The address of the partner
        address partnerAddress; 
        // The amount (in wei) that the partner wish to fund
        uint presaleAmount;
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
    // The manager smart contract to fund
    PassManager public DaoManager;
    // Address of the manager smart contract for the reward of contractor tokens
    address public contractorManager;
    // Minimum amount (in wei) to fund
    uint public minFundingAmount;
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
    /// The partner can fund below the minimum amount limit or a set percentage of his shares balance in the Dao
    uint multiplierSharesLimit;
    /// The partner can fund below the minimum amount limit or a set percentage of his shares balance in the Dao 
    uint divisorSharesLimit;
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
    
    // To allow the creator to pause during the presale
    uint pauseClosingTime;
    // To allow the creator to abort the funding before the closing time
    bool IsfundingAborted;
    
    // To allow the set of partners in several times
    uint setFromPartner;
    // To allow the refund for partners in several times
    uint refundFromPartner;

    // The manager of this funding is the creator of this contract
    modifier onlyCreator {if (msg.sender != creator) throw; _ ;}

    /// @dev Constructor function
    /// @param _creator The creator of the smart contract
    /// @param _DaoManager The Dao manager smart contract
    /// @param _contractorManager The address of the contractor manager smart contract  
    /// for the reward of tokens (not mandatory)
    /// @param _minAmount Minimum amount (in wei) of the funding to be fueled 
    /// @param _startTime The unix start time of the presale
    /// @param _closingTime The unix closing time of the funding
    //function PassFunding (
        //address _creator,
        //address _DaoManager,
        //address _contractorManager,
        //uint _minAmount,
        //uint _startTime,
        //uint _closingTime
    //);

    /// @notice Function used by the creator to set the presale limits
    /// @param _minPresaleAmount Minimum amount (in wei) that partners can send
    /// @param _maxPresaleAmount Maximum amount (in wei) that partners can send
    function SetPresaleAmountLimits(
        uint _minPresaleAmount,
        uint _maxPresaleAmount
        );

    /// @dev Fallback function
    function () payable;

    /// @notice Function to participate in the presale of the funding
    /// @return Whether the presale was successful or not
    function presale() payable returns (bool);
    
    /// @notice Function used by the creator to set addresses that can fund the dao
    /// @param _valid True if the address can fund the Dao
    /// @param _from The index of the first partner to set
    /// @param _to The index of the last partner to set
    function setValidPartners(
            bool _valid,
            uint _from,
            uint _to
        );

    /// @notice Function used by the creator to set the addresses of Dao share holders
    /// @param _valid True if the address can fund the Dao
    /// @param _from The index of the first partner to set
    /// @param _to The index of the last partner to set
    function setShareHolders(
            bool _valid,
            uint _from,
            uint _to
        );
    
    /// @notice Function used by the creator to set the funding limits for the funding
    /// @param _minAmountLimit The amount below this limit (in wei) can fund the dao
    /// @param _maxAmountLimit Maximum amount (in wei) a partner can fund
    /// @param _divisorBalanceLimit The creator can set a limit in percentage of Eth balance (not mandatory)
    /// @param _multiplierSharesLimit The creator can set a limit in percentage of shares balance in the Dao (not mandatory)
    /// @param _divisorSharesLimit The creator can set a limit in percentage of shares balance in the Dao (not mandatory) 
    function setLimits(
            uint _minAmountLimit,
            uint _maxAmountLimit, 
            uint _divisorBalanceLimit,
            uint _multiplierSharesLimit,
            uint _divisorSharesLimit
    );

    /// @notice Function used to set the funding limits for partners
    /// @param _to The index of the last partner to set
    /// @return Whether the set was successful or not
    function setFunding(uint _to) returns (bool _success);

    /// @notice Function for the funding of the Dao by a group of partners
    /// @param _from The index of the first partner
    /// @param _to The index of the last partner
    /// @return Whether the Dao was funded or not
    function fundDaoFor(
            uint _from,
            uint _to
        ) returns (bool);
    
    /// @notice Function to fund the Dao with 'msg.sender' as 'beneficiary'
    /// @return Whether the Dao was funded or not 
    function fundDao() returns (bool);
    
    /// @notice Function To allow the creator to pause during the presale
    function pause(uint _pauseClosingTime) onlyCreator {
        pauseClosingTime = _pauseClosingTime;
    }

    /// @notice Function to allow the creator to abort the funding before the closing time
    function abortFunding() onlyCreator;
    
    /// @notice Function to refund for a partner
    /// @param _partnerID The index of the partner
    /// @return Whether the refund was successful or not 
    function refundFor(uint _partnerID) internal returns (bool);

    /// @notice Function to refund for valid partners before the closing time
    /// @param _to The index of the last partner
    function refundForValidPartners(uint _to);

    /// @notice Function to refund for a group of partners after the closing time
    /// @param _from The index of the first partner
    /// @param _to The index of the last partner
    function refundForAll(
        uint _from,
        uint _to);

    /// @notice Function to refund after the closing time with 'msg.sender' as 'beneficiary'
    function refund();

    /// @param _minAmountLimit The amount (in wei) below this limit can fund the dao
    /// @param _maxAmountLimit Maximum amount (in wei) a partner can fund
    /// @param _divisorBalanceLimit The partner can fund 
    /// only under a defined percentage of his ether balance
    /// @param _multiplierSharesLimit The partner can fund 
    /// only under a defined percentage of his shares balance in the Dao 
    /// @param _divisorSharesLimit The partner can fund 
    /// only under a defined percentage of his shares balance in the Dao 
    /// @param _from The index of the first partner
    /// @param _to The index of the last partner
    /// @return The result of the funding procedure (in wei) at present time
    function estimatedFundingAmount(
        uint _minAmountLimit,
        uint _maxAmountLimit, 
        uint _divisorBalanceLimit,
        uint _multiplierSharesLimit,
        uint _divisorSharesLimit,
        uint _from,
        uint _to
        ) constant external returns (uint);

    /// @param _index The index of the partner
    /// @param _minAmountLimit The amount (in wei) below this limit can fund the dao
    /// @param _maxAmountLimit Maximum amount (in wei) a partner can fund
    /// @param _divisorBalanceLimit The partner can fund 
    /// only under a defined percentage of his ether balance 
    /// @param _multiplierSharesLimit The partner can fund 
    /// only under a defined percentage of his shares balance in the Dao 
    /// @param _divisorSharesLimit The partner can fund 
    /// only under a defined percentage of his shares balance in the Dao 
    /// @return The maximum amount (in wei) a partner can fund
    function partnerFundingLimit(
        uint _index, 
        uint _minAmountLimit,
        uint _maxAmountLimit, 
        uint _divisorBalanceLimit,
        uint _multiplierSharesLimit,
        uint _divisorSharesLimit
        ) internal returns (uint);
        
    /// @return the number of partners
    function numberOfPartners() constant external returns (uint);
    
    /// @param _from The index of the first partner
    /// @param _to The index of the last partner
    /// @return The number of valid partners
    function numberOfValidPartners(
        uint _from,
        uint _to
        ) constant external returns (uint);

    event IntentionToFund(address indexed partner, uint amount);
    event Fund(address indexed partner, uint amount);
    event Refund(address indexed partner, uint amount);
    event LimitSet(uint minAmountLimit, uint maxAmountLimit, uint divisorBalanceLimit, 
        uint _multiplierSharesLimit, uint divisorSharesLimit);
    event PartnersNotSet(uint sumOfFundingAmountLimits);
    event AllPartnersSet(uint fundingAmount);
    event Fueled();
    event FundingClosed();
    
}

contract PassFunding is PassFundingInterface {

    function PassFunding (
        address _creator,
        address _DaoManager,
        address _contractorManager,
        uint _minFundingAmount,
        uint _startTime,
        uint _closingTime
        ) {

        if (_creator == _DaoManager
            || _creator == 0
            || _creator == _contractorManager
            || _DaoManager == 0
            || _contractorManager == _DaoManager
            || (_startTime < now && _startTime != 0)) throw;
            
        creator = _creator;
        DaoManager = PassManager(_DaoManager);
        contractorManager = _contractorManager;

        minFundingAmount = _minFundingAmount;

        if (_startTime == 0) {startTime = now;} else {startTime = _startTime;}

        if (_closingTime <= startTime) throw;
        closingTime = _closingTime;
        
        setFromPartner = 1;
        refundFromPartner = 1;

        partners.length = 1; 
        
        }

    function SetPresaleAmountLimits(
        uint _minPresaleAmount,
        uint _maxPresaleAmount
        ) onlyCreator {

        if (limitSet) throw;
        
        minPresaleAmount = _minPresaleAmount;
        maxPresaleAmount = _maxPresaleAmount;

        }

    function () payable {
        if (!presale()) throw;
    }

    function presale() payable returns (bool) {

        if (msg.value <= 0
            || now < startTime
            || now > closingTime
            || now < pauseClosingTime
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
        
        return true;
        
    }
    
    function setValidPartners(
            bool _valid,
            uint _from,
            uint _to
        ) onlyCreator {

        if (limitSet) throw;
        
        if (_from < 1 || _to > partners.length - 1) throw;
        
        for (uint i = _from; i <= _to; i++) {
            Partner t = partners[i];
            t.valid = _valid;
        }
        
    }

    function setShareHolders(
            bool _valid,
            uint _from,
            uint _to
        ) onlyCreator {

        if (limitSet
            ||_from < 1 
            || _to > partners.length - 1) throw;
        
        for (uint i = _from; i <= _to; i++) {
            Partner t = partners[i];
            if (DaoManager.balanceOf(t.partnerAddress) != 0) t.valid = _valid;
        }
        
    }
    
    function abortFunding() onlyCreator {
        limitSet = true;
        maxPresaleAmount = 0;
        IsfundingAborted = true; 
    }
    
    function pause(uint _pauseClosingTime) onlyCreator {
        pauseClosingTime = _pauseClosingTime;
    }
    
    function setLimits(
            uint _minAmountLimit,
            uint _maxAmountLimit, 
            uint _divisorBalanceLimit,
            uint _multiplierSharesLimit,
            uint _divisorSharesLimit
    ) onlyCreator {
        
        if (limitSet) throw;
        
        minAmountLimit = _minAmountLimit;
        maxAmountLimit = _maxAmountLimit;
        divisorBalanceLimit = _divisorBalanceLimit;
        multiplierSharesLimit = _multiplierSharesLimit;
        divisorSharesLimit = _divisorSharesLimit;

        limitSet = true;
        
        LimitSet(_minAmountLimit, _maxAmountLimit, _divisorBalanceLimit, _multiplierSharesLimit, _divisorSharesLimit);
    
    }

    function setFunding(uint _to) onlyCreator returns (bool _success) {
        
        if (!limitSet 
            || DaoManager.fundingMaxAmount(address(this)) < minFundingAmount
            || setFromPartner > _to 
            || _to > partners.length - 1) throw;
            
        DaoManager.setFundingStartTime(startTime);
        if (contractorManager != 0) PassManager(contractorManager).setFundingStartTime(startTime);
        
        if (setFromPartner == 1) sumOfFundingAmountLimits = 0;
        
        for (uint i = setFromPartner; i <= _to; i++) {

            partners[i].fundingAmountLimit = partnerFundingLimit(i, minAmountLimit, maxAmountLimit, 
                divisorBalanceLimit, multiplierSharesLimit, divisorSharesLimit);

            sumOfFundingAmountLimits += partners[i].fundingAmountLimit;

        }
        
        setFromPartner = _to + 1;
        
        if (setFromPartner >= partners.length) {

            setFromPartner = 1;

            if (sumOfFundingAmountLimits < minFundingAmount 
                || sumOfFundingAmountLimits > DaoManager.fundingMaxAmount(address(this))) {

                maxPresaleAmount = 0;
                IsfundingAborted = true; 
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

    function fundDaoFor(
            uint _from,
            uint _to
        ) returns (bool) {

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

                DaoManager.rewardToken(_partner, _amountToFund, partners[i].presaleDate);

                if (contractorManager != 0) {
                    PassManager(contractorManager).rewardToken(_partner, _amountToFund, partners[i].presaleDate);
                }

            }

        }

        if (_sumAmountToFund == 0) return;
        
        if (!DaoManager.send(_sumAmountToFund)) throw;

        totalFunded += _sumAmountToFund;

        if (totalFunded >= sumOfFundingAmountLimits) {
            DaoManager.setFundingFueled(); 
            if (contractorManager != 0) PassManager(contractorManager).setFundingFueled(); 
            Fueled();
        }
        
        return true;

    }
    
    function fundDao() returns (bool) {
        return fundDaoFor(partnerID[msg.sender], partnerID[msg.sender]);
    }

    function refundFor(uint _partnerID) internal returns (bool) {

        Partner t = partners[_partnerID];
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

    function refundForValidPartners(uint _to) {

        if (refundFromPartner > _to || _to > partners.length - 1) throw;
        
        for (uint i = refundFromPartner; i <= _to; i++) {
            if (partners[i].valid) {
                if (!refundFor(i)) throw;
            }
        }

        refundFromPartner = _to + 1;
        
        if (refundFromPartner >= partners.length) {
            refundFromPartner = 1;

            if ((totalFunded >= sumOfFundingAmountLimits && allSet && closingTime > now)
                || IsfundingAborted) {

                closingTime = now; 
                FundingClosed(); 

            }
        }
        
    }

    function refundForAll(
        uint _from,
        uint _to) {

        if (_from < 1 || _to > partners.length - 1) throw;
        
        for (uint i = _from; i <= _to; i++) {
            if (!refundFor(i)) throw;
        }

    }

    function refund() {
        refundForAll(partnerID[msg.sender], partnerID[msg.sender]);
    }

    function estimatedFundingAmount(
        uint _minAmountLimit,
        uint _maxAmountLimit, 
        uint _divisorBalanceLimit,
        uint _multiplierSharesLimit,
        uint _divisorSharesLimit,
        uint _from,
        uint _to
        ) constant external returns (uint) {

        if (_from < 1 || _to > partners.length - 1) throw;

        uint _total = 0;
        
        for (uint i = _from; i <= _to; i++) {
            _total += partnerFundingLimit(i, _minAmountLimit, _maxAmountLimit, 
                _divisorBalanceLimit, _multiplierSharesLimit, _divisorSharesLimit);
        }

        return _total;

    }

    function partnerFundingLimit(
        uint _index, 
        uint _minAmountLimit,
        uint _maxAmountLimit, 
        uint _divisorBalanceLimit,
        uint _multiplierSharesLimit,
        uint _divisorSharesLimit
        ) internal returns (uint) {

        uint _amount;
        uint _amount1;

        Partner t = partners[_index];
            
        if (t.valid) {

            _amount = t.presaleAmount;
            
            if (_divisorBalanceLimit > 0) {
                _amount1 = uint(t.partnerAddress.balance)/uint(_divisorBalanceLimit);
                if (_amount > _amount1) _amount = _amount1; 
                }

            if (_divisorSharesLimit > 0) {
                _amount1 = uint(DaoManager.balanceOf(t.partnerAddress))*_multiplierSharesLimit/_divisorSharesLimit;
                if (_amount > _amount1) _amount = _amount1; 
                }

            if (_amount > _maxAmountLimit) _amount = _maxAmountLimit;
            
            if (_amount < _minAmountLimit) _amount = _minAmountLimit;

            if (_amount > t.presaleAmount) _amount = t.presaleAmount;
            
        }
        
        return _amount;
        
    }

    function numberOfPartners() constant external returns (uint) {
        return partners.length - 1;
    }
    
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
    event NewFunding(address creator, address DaoAccountManager, address ContractorAccountManager,
        uint MinFundingAmount, uint StartTime, uint ClosingTime, address FundingContractAddress);
    function createFunding(
        address _DaoAccountManager,
        address _contractorAccountManager,
        uint _minFundingAmount,
        uint _startTime,
        uint _closingTime
        ) returns (PassFunding) {
        PassFunding _newFunding = new PassFunding(
            msg.sender,
            _DaoAccountManager,
            _contractorAccountManager,        
            _minFundingAmount,
            _startTime,
            _closingTime
        );
        NewFunding(msg.sender, _DaoAccountManager, _contractorAccountManager, 
            _minFundingAmount, _startTime, _closingTime, address(_newFunding));
        return _newFunding;
    }
}
