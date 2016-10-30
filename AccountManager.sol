import "Token.sol";

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
 * The Account Manager smart contract, associated with a recipient for contractor tokens,
 * is used for the management of tokens by a client smart contract (the Dao)
 * or for the funding and creation of tokens by a funding smart contract 
*/

/// @title Account Manager smart contract of the Pass Decentralized Autonomous Organisation
contract AccountManager is Token {
    
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

    // Address of the creator or this smart contract
    address public creator;
    // Address of the Dao    
    address public client;
    // Address of the account manager recipient;
    address public recipient;
    
    // Map The funding dates for funding proposals
    mapping (uint => uint) fundingDate;
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

    /// @dev The constructor function
    /// @param _creator The address of the creator
    /// @param _client The address of the Dao
    /// @param _recipient The address of the recipient. 0 for the Dao.
    /// @param _initialSupply The initial supply of tokens for the recipient (not mandatory)
    function AccountManager(
        address _creator,
        address _client,
        address _recipient,
        uint256 _initialSupply
    ) {
        
        creator = _creator;
        client = _client;
        recipient = _recipient;
        
        decimals = 18;
        
        if (_initialSupply > 0) {

            if (_recipient == 0)  _recipient = _creator;
            balances[_recipient] = _initialSupply; 
            totalSupply = _initialSupply;
            TokensCreated(msg.sender, _recipient, _initialSupply);

        }
        
   }

    /// @notice Function to send ethers to the Dao account manager. 
    function () payable {
        if (recipient != 0) throw;
    }

    /// @notice Function to buy Dao shares according to the funding rules 
    /// with `msg.sender` as the beneficiary
    function buyShares() payable {
        buySharesFor(msg.sender);
    } 
    
    /// @notice Function to buy Dao shares according to the funding rules 
    /// @param _recipient The beneficiary of the created shares
    function buySharesFor(address _recipient) payable {
        
        if (recipient != 0
            || !FundingRules.publicCreation 
            || !createToken(_recipient, msg.value, now)) {
            throw;
        }

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
     
    /// @return True if the sender is the creator of this account manager
    function IsCreator(address _sender) constant external returns (bool) {
        if (creator == _sender) return true;
    }

    /// @return The total supply of shares or tokens 
    function TotalSupply() constant external returns (uint256) {
        return totalSupply;
    }

    /// @notice Internal function to set the actual funding fueled
    function setFundingFueled() internal {
        
        fundingDate[FundingRules.fundingProposalID] = now;
        FundingRules.closingTime = now;
        FundingFueled(FundingRules.fundingProposalID, FundingRules.fundedAmount);

    }
    
    /// @notice Function used by the main partner to set the funding fueled
    function Fueled() external {
        if (msg.sender != FundingRules.mainPartner || now > FundingRules.closingTime) throw;
        setFundingFueled();
    }
    
    /// @param _fundingProposalID The index of the Dao funding proposal
    /// @return The unix date when the funding was fueled. 0 if not fueled.
    function FundingDate(uint _fundingProposalID) constant external returns (uint) {
        return fundingDate[_fundingProposalID];
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
    
    /// @return The maximal amount to fund of the actual funding. 0 if there is not any funding at this moment
    function fundingMaxAmount() constant returns (uint) {
        
        if ((now > FundingRules.closingTime)
            || now < FundingRules.startTime) {
            return 0;   
        } else {
            return FundingRules.maxAmountToFund;
        }
        
    }
    
    /// @dev Function used by the client to send ethers
    /// @param _recipient The address to send to
    /// @param _amount The amount (in wei) to send
    /// @return Whether the transfer was successful or not
    function sendTo(
        address _recipient, 
        uint _amount
    ) external onlyClient returns (bool _success) {
    
        if (_amount >0) return _recipient.send(_amount);    

    }

    /// @dev Function used by the client to block the transfer of shares from and to a share holder
    /// @param _shareHolder The address of the share holder
    /// @param _deadLine When the account will be unblocked
    function blockTransfer(address _shareHolder, uint _deadLine) external onlyClient {
        if (_deadLine > blockedDeadLine[_shareHolder]) {
            blockedDeadLine[_shareHolder] = _deadLine;
        }
    }
    
    /// @dev Function used by the client to able the transfer of Dao shares or contractor tokens
    function TransferAble() external onlyClient {
        transferable = true;
        TokenTransferable();
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
    ) internal returns (bool) {

        if (FundingRules.fundedAmount + _amount > fundingMaxAmount()) return;

        uint _quantity = 100*_amount*FundingRules.initialPriceMultiplier/priceDivisor(_saleDate);
        if (totalSupply + _quantity <= totalSupply) return;

        balances[_recipient] += _quantity;
        totalSupply += _quantity;
        FundingRules.fundedAmount += _amount;

        TokensCreated(msg.sender, _recipient, _quantity);
        
        if (FundingRules.fundedAmount == FundingRules.maxAmountToFund) setFundingFueled();
        
        return true;

    }
   
    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The quantity of shares or tokens to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(
        address _to, 
        uint256 _value
        ) returns (bool success) {  

        if (transferable
            && (blockedDeadLine[msg.sender] < now)
            && (blockedDeadLine[_to] < now)
            && _to != address(this)
            && super.transfer(_to, _value)) {
                return true;
            } else {
            throw;
        }

    }

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The quantity of shares or tokens to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
        ) returns (bool success) {
        
        if (transferable
            && ( blockedDeadLine[_from] < now)
            && (blockedDeadLine[_to] < now)
            && _to != address(this)
            && super.transferFrom(_from, _to, _value)) {
            return true;
        } else {
            throw;
        }
        
    }
    
}    
  
