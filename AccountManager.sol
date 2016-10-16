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
 * The Account Manager smart contract is associated with a recipient 
 * (the Dao for dao shares and the recipient for contractor tokens) 
 * and used for the management of tokens by a client smart contract (the Dao)
*/

/// @title Account Manager smart contract of the Pass Decentralized Autonomous Organisation
contract AccountManager is Token {

    // Rules for the funding of the account manager
    fundingData public FundingRules;
    struct fundingData {
        // The address which manage the funding in case of private funding
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

    // Address of the creator
    address public creator;
    // Address of the Dao    
    address public client;
    // Address of the account manager recipient;
    address public recipient;
    
    // Map The funding dates for contractor proposals
    mapping (uint => uint) fundingDate;
    // If true, the tokens can be transfered
    bool public transferable;

    // Map of addresses blocked during a vote. The address points to the date when the address can be unblocked
    mapping (address => uint) blocked; 

    // Modifier that allows only the cient to manage the account manager
    modifier onlyClient {if (msg.sender != client) throw; _;}
    // Modifier that allows public to buy tokens only in case of crowdfunding
    modifier onlyPublicTokenCreation {if (!FundingRules.publicTokenCreation) throw; _;}

    event TokensCreated(address indexed sender, address indexed tokenHolder, uint quantity);
    event FundingRulesSet(address indexed mainPartner, uint startTime);

    /// @dev The constructor function
    /// @param _creator The creator address
    /// @param _client The Dao address
    /// @param _recipient The recipient address
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
        
        if (_initialSupply > 0) {

            if (_recipient == 0)  _recipient = _creator;
            balances[_recipient] = _initialSupply; 
            totalSupply = _initialSupply;
            TokensCreated(msg.sender, _recipient, _initialSupply);

        }
        
   }

    /// @notice Function to send ethers to the Dao account manager. Tokens are created 
    /// according to the funding rules with `msg.sender` as the beneficiary in case of public funding
    function () payable {

        if (FundingRules.publicTokenCreation 
            && msg.sender != client) {

            if (!createToken(msg.sender, msg.value, now)) throw;

        }

    }

    /// @notice Create tokens with `_tokenHolder` as the beneficiary
    /// @param _tokenHolder the beneficiary of the created tokens
    /// @param _amount the amount funded by the main partner
    /// @param _saleDate in case of presale, the date of the presale
    /// @return Whether the token creation was successful or not
    function buyTokenFor(
        address _tokenHolder,
        uint _amount,
        uint _saleDate
        ) returns (bool _success) {
        
        if (msg.sender != FundingRules.mainPartner) throw;

        return createToken(_tokenHolder, _amount, _saleDate);

    }
     
    /// @notice Function to unblock a tokenHolder address
    /// @param _tokenHolder The address of the tokenHolder
    /// @return Whether the tokenholder address is blocked (not allowed to transfer tokens) or not.
    function unblockAccount(address _tokenHolder) returns (bool) {
    
        uint _deadLine = blocked[_tokenHolder];
        
        if (_deadLine == 0) return false;
        
        if (now > _deadLine) {
            blocked[_tokenHolder] = 0;
            return false;
        } else {
            return true;
        }
        
    }

    /// @return True if the sender is the creator
    function IsCreator(address _sender) constant external returns (bool) {
        if (creator == _sender) return true;
    }

    /// @return The total supply of tokens 
    function TotalSupply() constant external returns (uint256) {
        return totalSupply;
    }
    
    /// @notice Function used by the Dao or a main partner to set a Dao contractor proposal fueled
    /// @param _contractorProposalID The index of the Dao contractor proposal
    function Fueled(uint _contractorProposalID) external {
    
        if (msg.sender != client && msg.sender != FundingRules.mainPartner) {
            throw;
        }

        fundingDate[_contractorProposalID] = now;
        
    }
    
    /// @param _contractorProposalID The index of the Dao contarctor proposal
    /// @return The unix date when the dao is funded
    function fundingDateForContractor(uint _contractorProposalID) constant external returns (uint) {
        return fundingDate[_contractorProposalID];
    }

    /// @return The maximum tokens after the funding
    function MaxTotalSupply() constant external returns (uint) {
        return (FundingRules.maxTotalSupply);
    }

    /// @param _saleDate in case of presale, the date of the presale
    /// @return the token price divisor condidering the sale date and the inflation rate
    function tokenPriceDivisor(uint _saleDate) constant internal returns (uint) {

        uint _date = _saleDate;
        
        if (_saleDate > FundingRules.closingTime && FundingRules.closingTime != 0) {
            _date = FundingRules.closingTime;
        } 
        
        if (_saleDate < FundingRules.startTime) {
            _date = FundingRules.startTime;
            }

        return 100 + 100*FundingRules.inflationRate*(_date - FundingRules.startTime)/(100*365 days);

    }
    
    /// @return the actual token price
    function actualTokenPriceDivisor() constant external returns (uint) {
        return tokenPriceDivisor(now);
    }

    /// @dev Function to set a funding. Can be private or public
    /// @param _mainPartner The address for the managing of a private funding
    /// @param _publicTokenCreation True if public funding
    /// @param _initialTokenPriceMultiplier Price multiplier without considering any inflation rate
    /// @param _maxAmountToFund The maximum amount of the funding
    /// @param _startTime The start time of the funding
    /// @param _closingTime After this date, the funding is closed
    /// @param _inflationRate If 0, the token price doesn't change during the funding
    function setFundingRules(
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
        
        if (_startTime < FundingRules.closingTime) {
            FundingRules.startTime = FundingRules.closingTime;
        } else {
            FundingRules.startTime = _startTime;
        }
        
        FundingRules.closingTime = _closingTime; 
        FundingRules.initialTokenPriceMultiplier = _initialTokenPriceMultiplier;
        FundingRules.maxAmountToFund = _maxAmountToFund;
        FundingRules.maxTotalSupply = totalSupply + _maxAmountToFund*FundingRules.initialTokenPriceMultiplier;
        FundingRules.inflationRate = _inflationRate;  
        
        FundingRulesSet(_mainPartner, _startTime);

    } 
    
    /// @return The maximal amount to fund of the actual funding. 0 if there is not any funding at this moment
    function fundingMaxAmount() constant external returns (uint) {
        
        if ((now > FundingRules.closingTime && FundingRules.closingTime != 0)
            || now < FundingRules.startTime) {
            return 0;   
        } else {
            return FundingRules.maxAmountToFund;
        }
        
    }
    
    /// @dev Function used by the client to send ethers
    /// @param _recipient The address to send to
    /// @param _amount The amount to send
    /// @return Whether the transfer was successful or not
    function sendTo(
        address _recipient, 
        uint _amount
    ) external onlyClient returns (bool _success) {
    
        return _recipient.send(_amount);    

    }
    
    /// @notice Function used by the Dao or a main partner to reward tokens
    /// @param _tokenHolder The address of the token holder
    /// @param _amount The amount in Wei to calculate the quantity to create
    /// @param _date The date to consider for the token price calculation
    /// @return Whether the transfer was successful or not
    function rewardToken(
        address _tokenHolder, 
        uint _amount,
        uint _date
        ) external returns (bool _success) {
        
        if (msg.sender != client && msg.sender != FundingRules.mainPartner) {
            throw;
        }
        
        return createToken(_tokenHolder, _amount, _date);

    }

    /// @param _tokenHolder The address of a token holder
    /// @return When a tokenHolder address can be unblocked
    function blockedAccountDeadLine(address _tokenHolder) constant external returns (uint) {
        
        return blocked[_tokenHolder];

    }
    
    /// @dev Function used by the client to block tokens transfer of from a tokenholder
    /// @param _tokenHolder The address of the token holder
    /// @param _deadLine When the account can be unblocked
    function blockAccount(address _tokenHolder, uint _deadLine) external onlyClient {
        blocked[_tokenHolder] = _deadLine;
    }
    
    /// @dev Function used by the client to able the transfer of tokens
    function TransferAble() external onlyClient {
        transferable = true;
    }

    /// @dev Function used by the client to disable the transfer of tokens
    function TransferDisable() external onlyClient {
        transferable = false;
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

        if ((now > FundingRules.closingTime && FundingRules.closingTime !=0) 
            || _amount <= 0
            || (now < FundingRules.startTime) ) {
            throw;
            }

        uint _quantity = 100*_amount*FundingRules.initialTokenPriceMultiplier/tokenPriceDivisor(_saleDate);
        if (totalSupply + _quantity > FundingRules.maxTotalSupply) return;

        balances[_tokenHolder] += _quantity; 
        totalSupply += _quantity;
        TokensCreated(msg.sender, _tokenHolder, _quantity);
        
        if (totalSupply == FundingRules.maxTotalSupply) {
            FundingRules.closingTime = now;
        }
        
        return true;

    }
   
    // Function to transfer tokens to another address
    function transfer(
        address _to, 
        uint256 _value
        ) returns (bool success) {  

        if (transferable
            && blocked[msg.sender] == 0
            && blocked[_to] == 0
            && _to != address(this)
            && super.transfer(_to, _value)) {
                return true;
            } else {
            throw;
        }

    }

    // Function to transfer tokens from an address to another address
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
        ) returns (bool success) {
        
        if (transferable
            && blocked[_from] == 0
            && blocked[_to] == 0
            && _to != address(this)
            && super.transferFrom(_from, _to, _value)) {
            return true;
        } else {
            throw;
        }
        
    }
    
}    
  
