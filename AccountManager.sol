//pragma solidity ^0.3.6;

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
 * The Account Manager smart contract is associated with a recipient 
 * (the Dao for dao shares and the recipient for contractor tokens) 
 * and used for the management of tokens by a client smart contract (the Dao)
*/

import "Token.sol";

contract AccountManagerInterface {

    // Rules for the funding
    fundingData public FundingRules;
    struct fundingData {
        // The address which set partners in case of private funding
        address mainPartner;
        // True if crowdfunding
        bool publicTokenCreation; 
        // The maximum amount of the funding
        uint maxAmountToFund;
        // Maximum quantity of tokens to create
        uint256 maxTotalSupply; 
        // Start time of the funding
        uint startTime; 
        // Closing time of the funding
        uint closingTime;  
        // The price multiplier for a token without considering the inflation rate
        uint initialTokenPriceMultiplier;
        // Rate per year applied to the token price 
        uint inflationRate; 
    } 

     // address of the Dao    
    address public client;
    // Address of the recipient
    address public recipient;

    // True if the funding of the Dao contractor proposal is fueled
    mapping (uint => bool) isFueled;
    // If true, the tokens can be transfered
    bool public transferAble;

    // Map of addresses blocked during a vote. The address points to the proposal ID
    mapping (address => uint) blocked; 

    // Modifier that allows only the cient to manage tokens
    modifier onlyClient {if (msg.sender != address(client)) throw; _ }
    // modifier to allow public to fund only in case of crowdfunding
    modifier onlyRecipient {if (msg.sender != address(recipient)) throw; _ }
    // Modifier that allows public to buy tokens only in case of crowdfunding
    modifier onlyPublicTokenCreation {if (!FundingRules.publicTokenCreation) throw; _ }
    // Modifier that allows the main partner to buy tokens only in case of private funding
    modifier onlyPrivateTokenCreation {if (FundingRules.publicTokenCreation) throw; _ }

    event TokensCreated(address indexed sender, address indexed tokenHolder, uint quantity);
    event FundingRulesSet(address indexed mainPartner, uint startTime);
    event AmountSent(address indexed recipient, uint amount);

}

/// @title Account Manager smart contract of the Pass Decentralized Autonomous Organisation
contract AccountManager is Token, AccountManagerInterface {


    // Modifier that allows only shareholders to vote and create new proposals
    modifier onlyTokenholders {if (balances[msg.sender] == 0) throw; _ }

    /// @dev Constructor setting the Client, Recipient and initial Supply
    /// @param _client The Dao address
    /// @param _recipient The recipient address
    /// @param _initialSupply The initial supply of tokens for the recipient
    function AccountManager(
        address _client,
        address _recipient,
        uint256 _initialSupply
    ) {
    
        client = _client;
        recipient = _recipient;

        balances[_recipient] = _initialSupply; 
        totalSupply =_initialSupply;
        TokensCreated(msg.sender, _recipient, _initialSupply);
        
   }

    /// @notice Create Token with `msg.sender` as the beneficiary in case of public funding
    function () {
        if (FundingRules.publicTokenCreation) {
            buyToken(msg.sender, msg.value, now);
        }
    }

    /// @notice Create Token with `_tokenHolder` as the beneficiary
    /// @param _tokenHolder the beneficiary of the created tokens
    /// @param _amount the amount funded
    /// @param _saleDate in case of presale, the date of the presale
    /// @return Whether the transfer was successful or not
    function buyTokenFor(
        address _tokenHolder,
        uint _amount,
        uint _saleDate
        ) onlyPrivateTokenCreation returns (bool _succes) {
        
        if (msg.sender != FundingRules.mainPartner) throw;

        return buyToken(_tokenHolder, _amount, _saleDate);

    }
     
    /// @notice Create Token with `_tokenHolder` as the beneficiary
    /// @param _tokenHolder the beneficiary of the created tokens
    /// @param _amount the amount funded
    /// @param _saleDate in case of presale, the date of the presale
    /// @return Whether the transfer was successful or not
    function buyToken(
        address _tokenHolder,
        uint _amount,
        uint _saleDate) internal returns (bool _succes) {
        
        if (createToken(_tokenHolder, _amount, _saleDate)) {
            return true;
        }
        else throw;

    }
    
    /// @notice If the tokenholder account is blocked by a proposal whose voting deadline
    /// has exprired then unblock him.
    /// @param _account The address of the tokenHolder
    /// @return Whether the account is blocked (not allowed to transfer tokens) or not.
    function unblockAccount(address _account) noEther returns (bool) {
    
        uint _deadLine = blocked[_account];
        
        if (_deadLine == 0) return false;
        
        if (now > _deadLine) {
            blocked[_account] = 0;
            return false;
        } else {
            return true;
        }
        
    }

    /// @dev Function used by the client
    /// @return The total supply of tokens 
    function TotalSupply() external returns (uint256) {
        return totalSupply;
    }
    
    /// @dev Function used by the main partner to set the funding fueled
    /// @param _contractorProposalID The index of the Dao proposal
    /// @param _isFueled Whether the funding is fueled or not
    function Fueled(uint _contractorProposalID, bool _isFueled) external {
    
        if (msg.sender != address(client) && msg.sender != FundingRules.mainPartner) {
            throw;
        }

        isFueled[_contractorProposalID] = _isFueled;
        
    }
    
    /// @notice Function to know if the funding is fueled
    /// @param _contractorProposalID The index of the Dao proposal
    /// @return Whether the funding is fueled or not
    function IsFueled(uint _contractorProposalID) constant external returns (bool) {
        return isFueled[_contractorProposalID];
    }

    /// @dev Function used by the client
    /// @return The maximum tokens after the funding
    function MaxTotalSupply() external returns (uint) {
        return (FundingRules.maxTotalSupply);
    }

    /// @dev Function used by the client
    /// @param _saleDate in case of presale, the date of the presale
    /// @return the token price divisor condidering the sale date and the inflation rate
    function tokenPriceDivisor(uint _saleDate) internal returns (uint) {

        uint _date;
        
        if (_saleDate > FundingRules.closingTime && FundingRules.closingTime != 0) {
            _date = FundingRules.closingTime;
        }
        
        if (_saleDate < FundingRules.startTime) {
            _date = FundingRules.startTime;
            }
        else {
            _date = _saleDate;
        }
        
        return 100 + 100*FundingRules.inflationRate*(_date - FundingRules.startTime)/(100*365 days);

    }
    
    /// @return the actual token price
    function actualTokenPriceDivisor() constant returns (uint) {
        
        return tokenPriceDivisor(now);

    }

    /// @dev Function to extent funding. Can be private or public
    /// @param _mainPartner The address for the managing of the funding
    /// @param _publicTokenCreation True if public
    /// @param _initialTokenPriceMultiplier Price multiplier without considering any inflation rate
    /// @param _maxAmountToFund If the maximum is reached, the funding is closed
    /// @param _startTime If 0, the start time is the creation date of this contract
    /// @param _closingTime After this date, the funding is closed
    /// @param _inflationRate If 0, the token price doesn't change during the funding
    function extentFunding(
        address _mainPartner,
        bool _publicTokenCreation, 
        uint _initialTokenPriceMultiplier, 
        uint256 _maxAmountToFund, 
        uint _startTime, 
        uint _closingTime, 
        uint _inflationRate
    ) external onlyClient {

        FundingRules.mainPartner = _mainPartner;
        FundingRules.publicTokenCreation = _publicTokenCreation;
        
        if (_startTime < FundingRules.closingTime) FundingRules.startTime = FundingRules.closingTime;
        else FundingRules.startTime = _startTime;

        FundingRules.closingTime = _closingTime; 
        FundingRules.initialTokenPriceMultiplier = _initialTokenPriceMultiplier;
        FundingRules.maxAmountToFund = _maxAmountToFund;
        FundingRules.maxTotalSupply = totalSupply + _maxAmountToFund*FundingRules.initialTokenPriceMultiplier;
        FundingRules.inflationRate = _inflationRate;  
        
        FundingRulesSet(_mainPartner, _startTime);

    } 
    
    /// @return the maximal amount to fund if funding and 0 unless
    function fundingMaxAmount() constant returns (uint) {
        
        if ((now > FundingRules.closingTime && FundingRules.closingTime != 0)
            || now < FundingRules.startTime) {
            return 0;   
        } else return FundingRules.maxAmountToFund;

    }
    
    /// @dev Function used by the client to send ethers
    /// @param _recipient The address to send to
    /// @param _amount The amount to send
    function sendTo(
        address _recipient, 
        uint _amount
    ) external onlyClient {
    
        if (!_recipient.send(_amount)) throw;    
        AmountSent(_recipient, _amount);

}
    
    /// @dev Function used by the Dao to reward of tokens
    /// @param _tokenHolder The address of the token holder
    /// @param _amount The amount in Wei
    /// @param _date The date to consider for the token price calculation
    /// @return Whether the transfer was successful or not
    function rewardToken(
        address _tokenHolder, 
        uint _amount,
        uint _date
        ) external returns (bool _success) {
        
        if (msg.sender != address(client) && msg.sender != FundingRules.mainPartner) {
            throw;
        }
        
        if (createToken(_tokenHolder, _amount, _date)) return true;
        else throw;

    }

    /// @notice Function to know when a tokenholder account can be unblocked
    /// @param _account The address of the tokenHolder
    /// @return When the account can be unblocked
    function blockedAccountDeadLine(address _account) external constant returns (uint) {
        
        return blocked[_account];

    }
    
    /// @dev Function used by the client to block tokens transfer of from a tokenholder
    /// @param _account The address of the tokenHolder
    /// @param _deadLine When the account can be unblocked
    function blockAccount(address _account, uint _deadLine) external onlyClient {
        blocked[_account] = _deadLine;
    }
    
    /// @dev Function used by the client to able the transfer of tokens
    function TransferAble() external onlyClient {
        transferAble = true;
    }

    /// @dev Internal function for the creation of tokens
    /// @param _tokenHolder The address of the token holder
    /// @param _amount The funded amount (in wei)
    /// @param _saleDate in case of presale, the date of the presale
    /// @return Whether the token creation was successful or not
    function createToken(
        address _tokenHolder, 
        uint _amount,
        uint _saleDate
    ) internal returns (bool _success) {

        if ((totalSupply + _quantity > FundingRules.maxTotalSupply)
            || (now > FundingRules.closingTime && FundingRules.closingTime !=0) 
            || _amount <= 0
            || (now < FundingRules.startTime) ) {
            throw;
            }

        uint _quantity = 100*_amount*FundingRules.initialTokenPriceMultiplier/tokenPriceDivisor(_saleDate);

        if (totalSupply + _quantity > FundingRules.maxTotalSupply) throw;

        balances[_tokenHolder] += _quantity; 
        totalSupply += _quantity;
        TokensCreated(msg.sender, _tokenHolder, _quantity);
        
        if (totalSupply == FundingRules.maxTotalSupply) {
            FundingRules.closingTime = now;
        }

        return true;
        
    }
   
    // Function transfer only if the funding is not fueled and the account is not blocked
    function transfer(
        address _to, 
        uint256 _value
        ) returns (bool success) {  

        if (transferAble
            && blocked[msg.sender] == 0
            && blocked[_to] == 0
            && _to != address(this)
            && now > FundingRules.closingTime
            && super.transfer(_to, _value)) {
                return true;
            } else {
            throw;
        }

    }

    // Function transferFrom only if the funding is not fueled and the account is not blocked
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
        ) returns (bool success) {
        
        if (transferAble
            && blocked[_from] == 0
            && blocked[_to] == 0
            && _to != address(this)
            && now > FundingRules.closingTime 
            && super.transferFrom(_from, _to, _value)) {
            return true;
        } else {
            throw;
        }
        
    }
    
}    
  
