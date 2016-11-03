pragma solidity ^0.4.2;

/*
 * This file is part of Pass DAO.
 
 * The Token Manager smart contract is used for the management of tokens
 * by a client smart contract (the Dao). Defines the functions to set new funding rules,
 * create or reward tokens, check token balances, send tokens and send
 * tokens on behalf of a 3rd party and the corresponding approval process.
*/

/// @title Token Manager smart contract of the Pass Decentralized Autonomous Organisation
contract TokenManager {
    
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
    
    /* Array with all balances */
    mapping (address => uint256) balances;
    /* Array with all allowances */
    mapping (address => mapping (address => uint256)) allowed;
    /* Total amount of tokens */
    uint256 totalSupply;
    /* Amount of decimals for token display purposes */
    uint8 public decimals;

    // Map The result in wei of funding proposals
    mapping (uint => uint) fundedAmount;
    
    // If true, the shares or tokens can be transfered
    bool public transferable;
    // Map of blocked Dao share accounts. Points to the date when the share holder can transfer shares
    mapping (address => uint) public blockedDeadLine; 

    // Modifier that allows only the cient to manage this account manager
    modifier onlyClient {if (msg.sender != client) throw; _;}

    event TokensCreated(address indexed Sender, address indexed TokenHolder, uint Quantity);
    event FundingRulesSet(address indexed MainPartner, uint indexed FundingProposalId, uint indexed StartTime, uint ClosingTime);
    event FundingFueled(uint indexed FundingProposalID, uint FundedAmount);
    event TokenTransferable();

    /// @return The total supply of shares or tokens 
    function TotalSupply() constant external returns (uint256) {
        return totalSupply;
    }

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
     function balanceOf(address _owner) constant external returns (uint256 balance) {
        return balances[_owner];
     }

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Quantity of remaining tokens of _owner that _spender is allowed to spend
    function allowance(address _owner, address _spender) constant external returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /// @param _fundingProposalID The index of the Dao funding proposal
    /// @return The result in wei of the funding proposal
    function FundedAmount(uint _fundingProposalID) constant external returns (uint) {
        return fundedAmount[_fundingProposalID];
    }

    /// @param _saleDate in case of presale, the date of the presale
    /// @return the share or token price divisor condidering the sale date and the inflation rate
    function priceDivisor(uint _saleDate) constant internal returns (uint) {

        uint _date = _saleDate;
        
        if (_saleDate > FundingRules.closingTime) {
            _date = FundingRules.closingTime;
        } 
        
        if (_saleDate < FundingRules.startTime) {
            _date = FundingRules.startTime;
            }

        return 100 + 100*FundingRules.inflationRate*(_date - FundingRules.startTime)/(100*365 days);

    }
    
    /// @return the actual price divisor of a share or token
    function actualPriceDivisor() constant external returns (uint) {
        return priceDivisor(now);
    }

    /// @return The maximal amount 'msg.sender' can fund with his partners
    function fundingMaxAmount() constant external returns (uint) {
        
        if (now > FundingRules.closingTime
            || now < FundingRules.startTime
            || msg.sender != FundingRules.mainPartner) {
            return 0;   
        } else {
            return FundingRules.maxAmountToFund;
        }
        
    }

    /// @dev The constructor function
    /// @param _creator The address of the creator of the smart contract
    /// @param _client The address of the Dao
    /// @param _recipient The address of the recipient
    /// @param _initialSupply The initial supply of tokens for the recipient (not mandatory)
    function TokenManager(
        address _creator,
        address _client,
        address _recipient,
        uint256 _initialSupply
    ) {
        
        client = _client;
        
        decimals = 18;
        
        if (_initialSupply > 0) {

            if (_recipient == 0)  _recipient = _creator;
            balances[_recipient] = _initialSupply; 
            totalSupply = _initialSupply;
            TokensCreated(msg.sender, _recipient, _initialSupply);

        }
        
   }
   
    /// @dev Function to set a funding. Can be private or public
    /// @param _mainPartner The address of the smart contract to manage a private funding
    /// @param _publicCreation True if public funding
    /// @param _initialPriceMultiplier Price multiplier without considering any inflation rate
    /// @param _maxAmountToFund The maximum amount (in wei) of the funding
    /// @param _startTime  A unix timestamp, denoting the start time of the funding (not mandatory)
    /// @param _minutesFundingPeriod Period in minutes of the funding
    /// @param _inflationRate If 0, the token price doesn't change during the funding
    /// @param _fundingProposalID Index of the Dao funding proposal (not mandatory)
    function setFundingRules(
        address _mainPartner,
        bool _publicCreation, 
        uint _initialPriceMultiplier, 
        uint256 _maxAmountToFund, 
        uint _startTime, 
        uint _minutesFundingPeriod, 
        uint _inflationRate,
        uint _fundingProposalID
    ) external onlyClient {

        if (now < FundingRules.closingTime) throw;

        FundingRules.startTime = _startTime;
        FundingRules.closingTime = FundingRules.startTime + (_minutesFundingPeriod * 1 minutes);
 
        FundingRules.mainPartner = _mainPartner;
        FundingRules.publicCreation = _publicCreation;
        
        FundingRules.initialPriceMultiplier = _initialPriceMultiplier;
        FundingRules.inflationRate = _inflationRate;  

        FundingRules.fundedAmount = 0;
        FundingRules.maxAmountToFund = _maxAmountToFund;

        FundingRules.fundingProposalID = _fundingProposalID;

        FundingRulesSet(_mainPartner, _fundingProposalID, FundingRules.startTime, FundingRules.closingTime);

    } 
    
    /// @dev Internal function for the creation of shares or tokens
    /// @param _recipient The recipient address of shares or tokens
    /// @param _amount The funded amount (in wei)
    /// @param _saleDate In case of presale, the date of the presale
    /// @return Whether the creation was successful or not
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

    /// @notice Function used by the Dao or a main partner to reward shares or tokens
    /// @param _recipient The address of the recipient of shares or tokens
    /// @param _amount The amount (in Wei) to calculate the quantity of shares or tokens to create
    /// @param _date The date to consider for the share or token price calculation
    /// @return Whether the transfer was successful or not
    function rewardToken(
        address _recipient, 
        uint _amount,
        uint _date
        ) external {
        
        if (msg.sender != client && msg.sender != FundingRules.mainPartner) {
            throw;
        }
        
        if (!createToken(_recipient, _amount, _date)) throw;

    }

    /// @notice Internal function to close the actual funding
    function closeFunding() internal {
        
        fundedAmount[FundingRules.fundingProposalID] = FundingRules.fundedAmount;
        FundingRules.closingTime = now;

    }
    
    /// @notice Function used by the main partner to set the funding fueled
    function Fueled() external {
        if (msg.sender != FundingRules.mainPartner || now > FundingRules.closingTime) throw;
        closeFunding();
        FundingFueled(FundingRules.fundingProposalID, FundingRules.fundedAmount);
    }
    
    /// @dev Function used by the client to able the transfer of Dao shares or contractor tokens
    function TransferAble() external onlyClient {
        transferable = true;
        TokenTransferable();
    }

    /// @dev Function used by the client to block the transfer of shares from and to a share holder
    /// @param _shareHolder The address of the share holder
    /// @param _deadLine When the account will be unblocked
    function blockTransfer(address _shareHolder, uint _deadLine) external onlyClient {
        if (_deadLine > blockedDeadLine[_shareHolder]) {
            blockedDeadLine[_shareHolder] = _deadLine;
        }
    }
    
    /// @dev Internal function to send `_value` token to `_to` from `_From`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The quantity of shares or tokens to be transferred
    /// @return Whether the function was successful or not 
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

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The quantity of shares or tokens to be transferred
    function transfer(address _to, uint256 _value) {  
        if (!transferFromTo(msg.sender, _to, _value)) throw;
    }

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The quantity of shares or tokens to be transferred
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
        ) returns (bool success) { 
        
        if (allowed[_from][msg.sender] < _value
            || !transferFromTo(_from, _to, _value)) throw;
            
        allowed[_from][msg.sender] -= _value;

    }

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on its behalf
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        return true;
    }

}    
  
