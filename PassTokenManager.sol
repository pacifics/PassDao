pragma solidity ^0.4.2;

/*
 *
 * This file is part of Pass DAO.
 *
 * The Token Manager smart contract is used for the management of tokens
 * by a client smart contract (the Dao). Defines the functions to set new funding rules,
 * create or reward tokens, check token balances, send tokens and send
 * tokens on behalf of a 3rd party and the corresponding approval process.
 *
*/

/// @title Token Manager smart contract of the Pass Decentralized Autonomous Organisation
contract PassTokenManagerInterface {
    
    // Rules for the funding of the account manager
    fundingData public FundingRules;
    struct fundingData {
        // True if crowdfunding
        bool publicCreation; 
        // The address which create partners and manage the funding in case of private funding
        address mainPartner;
        // The maximum amount (in wei) of the funding
        uint maxAmountToFund;
        // The actual funded amount (in wei)
        uint fundedAmount;
        // A unix timestamp, denoting the start time of the funding
        uint startTime; 
        // A unix timestamp, denoting the closing time of the funding
        uint closingTime;  
        // The price multiplier for a share or a token without considering the inflation rate
        uint initialPriceMultiplier;
        // Rate per year in percentage applied to the share or token price 
        uint inflationRate; 
        // Index of the Dao funding proposal
        uint fundingProposalID;
    } 

    // Address of the Dao    
    address public client;
    
    // The token name for display purpose
    string public name;
    // The quantity of decimals for display purpose
    uint8 public decimals;
    // Total amount of tokens
    uint256 totalSupply;
    // The token name for display purpose

    // Array with all balances
    mapping (address => uint256) balances;
    // Array with all allowances
    mapping (address => mapping (address => uint256)) allowed;

    // Map The result in wei of funding proposals
    mapping (uint => uint) fundedAmount;
    
    // If true, the shares or tokens can be transfered
    bool public transferable;
    // Map of blocked Dao share accounts. Points to the date when the share holder can transfer shares
    mapping (address => uint) public blockedDeadLine; 

    /// @return The total supply of shares or tokens 
    function TotalSupply() constant external returns (uint256);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
     function balanceOf(address _owner) constant external returns (uint256 balance);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Quantity of remaining tokens of _owner that _spender is allowed to spend
    function allowance(address _owner, address _spender) constant external returns (uint256 remaining);

    /// @param _fundingProposalID The index of the Dao funding proposal
    /// @return The result in wei of the funding proposal
    function FundedAmount(uint _fundingProposalID) constant external returns (uint);

    /// @param _saleDate in case of presale, the date of the presale
    /// @return the share or token price divisor condidering the sale date and the inflation rate
    function priceDivisor(uint _saleDate) constant internal returns (uint);
    
    /// @return the actual price divisor of a share or token
    function actualPriceDivisor() constant external returns (uint);

    /// @return The maximal amount a main partner can fund at this moment
    /// @param _mainPartner The address of the main parner
    function fundingMaxAmount(address _mainPartner) constant external returns (uint);

    // Modifier that allows only the client to manage this account manager
    modifier onlyClient {if (msg.sender != client) throw; _;}

    // Modifier that allows only the main partner to manage the actual funding
    modifier onlyMainPartner {if (msg.sender !=  FundingRules.mainPartner) throw; _;}
    
    /// @dev The constructor function
    /// @param _creator The address of the creator of the smart contract
    /// @param _client The address of the Dao
    /// @param _recipient The address of the recipient
    /// @param _initialSupply The initial supply of tokens for the recipient (not mandatory)
    /// @param _tokenName The token name for display purpose
    //function TokenManager(
        //address _creator,
        //address _client,
        //address _recipient,
        //uint256 _initialSupply,
        //string _tokenName
    //);
   
    /// @notice Function to set a funding. Can be private or public
    /// @param _mainPartner The address of the smart contract to manage a private funding
    /// @param _publicCreation True if public funding
    /// @param _initialPriceMultiplier Price multiplier without considering any inflation rate
    /// @param _maxAmountToFund The maximum amount (in wei) of the funding
    /// @param _minutesFundingPeriod Period in minutes of the funding
    /// @param _inflationRate If 0, the token price doesn't change during the funding
    /// @param _fundingProposalID Index of the Dao funding proposal (not mandatory)
    function setFundingRules(
        address _mainPartner,
        bool _publicCreation, 
        uint _initialPriceMultiplier, 
        uint _maxAmountToFund, 
        uint _minutesFundingPeriod, 
        uint _inflationRate,
        uint _fundingProposalID
    ) onlyClient external;
    
    /// @dev Internal function for the creation of shares or tokens
    /// @param _recipient The recipient address of shares or tokens
    /// @param _amount The funded amount (in wei)
    /// @param _saleDate In case of presale, the date of the presale
    /// @return Whether the creation was successful or not
    function createToken(
        address _recipient, 
        uint _amount,
        uint _saleDate
    ) internal returns (bool success);

    /// @notice Function used by the main partner to set the start time of the funding
    /// @param _startTime The unix start date of the funding 
    function setFundingStartTime(uint _startTime) external onlyMainPartner;
    
    /// @notice Function used by the main partner to reward shares or tokens
    /// @param _recipient The address of the recipient of shares or tokens
    /// @param _amount The amount (in Wei) to calculate the quantity of shares or tokens to create
    /// @param _date The unix date to consider for the share or token price calculation
    /// @return Whether the transfer was successful or not
    function rewardToken(
        address _recipient, 
        uint _amount,
        uint _date
        ) external onlyMainPartner;

    /// @dev Internal function to close the actual funding
    function closeFunding() internal;
    
    /// @notice Function used by the main partner to set the funding fueled
    function setFundingFueled() external onlyMainPartner;
    
    /// @notice Function to able the transfer of Dao shares or contractor tokens
    function ableTransfer() external onlyClient;

    /// @notice Function to disable the transfer of Dao shares
    function disableTransfer() external onlyClient;

    /// @notice Function used by the client to block the transfer of shares from and to a share holder
    /// @param _shareHolder The address of the share holder
    /// @param _deadLine When the account will be unblocked
    function blockTransfer(address _shareHolder, uint _deadLine) external onlyClient;
    
    /// @dev Internal function to send `_value` token to `_to` from `_From`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The quantity of shares or tokens to be transferred
    /// @return Whether the function was successful or not 
    function transferFromTo(
        address _from,
        address _to, 
        uint256 _value
        ) internal returns (bool);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The quantity of shares or tokens to be transferred
    function transfer(address _to, uint256 _value);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The quantity of shares or tokens to be transferred
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
        ) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on its behalf
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    event TokensCreated(address indexed Sender, address indexed TokenHolder, uint Quantity);
    event FundingRulesSet(address indexed MainPartner, uint indexed FundingProposalId, uint indexed StartTime, uint ClosingTime);
    event FundingFueled(uint indexed FundingProposalID, uint FundedAmount);
    event TransferAble();
    event TransferDisable();

}    

contract PassTokenManager is PassTokenManagerInterface {
    
    function TotalSupply() constant external returns (uint256) {
        return totalSupply;
    }

     function balanceOf(address _owner) constant external returns (uint256 balance) {
        return balances[_owner];
     }

    function allowance(address _owner, address _spender) constant external returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function FundedAmount(uint _fundingProposalID) constant external returns (uint) {
        return fundedAmount[_fundingProposalID];
    }

    function priceDivisor(uint _saleDate) constant internal returns (uint) {
        uint _date = _saleDate;
        
        if (_saleDate > FundingRules.closingTime) _date = FundingRules.closingTime;
        if (_saleDate < FundingRules.startTime) _date = FundingRules.startTime;

        return 100 + 100*FundingRules.inflationRate*(_date - FundingRules.startTime)/(100*365 days);
    }
    
    function actualPriceDivisor() constant external returns (uint) {
        return priceDivisor(now);
    }

    function fundingMaxAmount(address _mainPartner) constant external returns (uint) {
        
        if (now > FundingRules.closingTime
            || now < FundingRules.startTime
            || _mainPartner != FundingRules.mainPartner) {
            return 0;   
        } else {
            return FundingRules.maxAmountToFund;
        }
        
    }

    function PassTokenManager(
        address _creator,
        address _client,
        address _recipient,
        uint256 _initialSupply,
        string _tokenName
    ) {
        
        if (_client == 0 || _recipient == address(this)) throw;

        name = _tokenName;
        decimals = 18;

        client = _client;

        if (_recipient != 0) {
            transferable = true;
            TransferAble();
        }

        if (_initialSupply > 0) {
            if (_recipient == 0 && _creator != 0)  _recipient = _creator;
            balances[_recipient] = _initialSupply; 
            totalSupply = _initialSupply;
            TokensCreated(msg.sender, _recipient, _initialSupply);
        }
        
   }
   
    function setFundingRules(
        address _mainPartner,
        bool _publicCreation, 
        uint _initialPriceMultiplier,
        uint _maxAmountToFund, 
        uint _minutesFundingPeriod, 
        uint _inflationRate,
        uint _fundingProposalID
    ) external onlyClient {

        if (now < FundingRules.closingTime
            || _mainPartner == address(this)
            || (!_publicCreation && _mainPartner == 0)
            || (_publicCreation && _mainPartner != 0)
            || _initialPriceMultiplier == 0
            || _maxAmountToFund <= 0
            || _minutesFundingPeriod <= 0
            ) throw;

        FundingRules.startTime = now;
        FundingRules.closingTime = now + _minutesFundingPeriod * 1 minutes;
 
        FundingRules.mainPartner = _mainPartner;
        FundingRules.publicCreation = _publicCreation;
        
        FundingRules.initialPriceMultiplier = _initialPriceMultiplier;
        FundingRules.inflationRate = _inflationRate;  

        FundingRules.fundedAmount = 0;
        FundingRules.maxAmountToFund = _maxAmountToFund;

        FundingRules.fundingProposalID = _fundingProposalID;

        FundingRulesSet(_mainPartner, _fundingProposalID, FundingRules.startTime, FundingRules.closingTime);

    } 
    
    function createToken(
        address _recipient, 
        uint _amount,
        uint _saleDate
    ) internal returns (bool success) {

        if (now > FundingRules.closingTime
            || now < FundingRules.startTime
            || FundingRules.fundedAmount + _amount > FundingRules.maxAmountToFund) return;

        uint _quantity = 100*_amount*FundingRules.initialPriceMultiplier/priceDivisor(_saleDate);
        if (totalSupply + _quantity <= totalSupply) return;

        balances[_recipient] += _quantity;
        totalSupply += _quantity;
        FundingRules.fundedAmount += _amount;

        TokensCreated(msg.sender, _recipient, _quantity);
        
        if (FundingRules.fundedAmount == FundingRules.maxAmountToFund) closeFunding();
        
        return true;

    }

    function setFundingStartTime(uint _startTime) external onlyMainPartner {
        if (now > FundingRules.closingTime) throw;
        FundingRules.startTime = _startTime;
    }
    
    function rewardToken(
        address _recipient, 
        uint _amount,
        uint _date
        ) external onlyMainPartner {

        uint _saleDate;
        if (_date == 0) _saleDate = now; else _saleDate = _date;

        if (!createToken(_recipient, _amount, _saleDate)) throw;

    }

    function closeFunding() internal {
        fundedAmount[FundingRules.fundingProposalID] += FundingRules.fundedAmount;
        FundingRules.closingTime = now;
    }
    
    function setFundingFueled() external onlyMainPartner {
        if (now > FundingRules.closingTime) throw;
        closeFunding();
        FundingFueled(FundingRules.fundingProposalID, FundingRules.fundedAmount);
    }
    
    function ableTransfer() external onlyClient {
        if (!transferable) {
            transferable = true;
            TransferAble();
        }
    }

    function disableTransfer() external onlyClient {
        if (transferable) {
            transferable = false;
            TransferDisable();
        }
    }
    
    function blockTransfer(address _shareHolder, uint _deadLine) external onlyClient {
        if (_deadLine > blockedDeadLine[_shareHolder]) {
            blockedDeadLine[_shareHolder] = _deadLine;
        }
    }
    
    function transferFromTo(
        address _from,
        address _to, 
        uint256 _value
        ) internal returns (bool) {  

        if (transferable
            && now > blockedDeadLine[_from]
            && now > blockedDeadLine[_to]
            && _to != address(this)
            && balances[_from] >= _value
            && balances[_to] + _value > balances[_to]
        ) {
            balances[_from] -= _value;
            balances[_to] += _value;
            return true;
        } else {
            return false;
        }
        
    }

    function transfer(address _to, uint256 _value) {  
        if (!transferFromTo(msg.sender, _to, _value)) throw;
    }

    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
        ) returns (bool success) { 
        
        if (allowed[_from][msg.sender] < _value
            || !transferFromTo(_from, _to, _value)) throw;
            
        allowed[_from][msg.sender] -= _value;

    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        return true;
    }

}    
  
