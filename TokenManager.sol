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
 * Token Manager contract is used by the DAO for the management of tokens.
 * The tokens can be created by a crowdfunding or by a private funding
*/

import "Token.sol";

contract TokenManagerInterface {

    address creator;
    
    struct fundingData {
        // True if crowdfunding
        bool publicTokenCreation; 
        // Minimum quantity of tokens to create
        uint256 minTokensToCreate; 
        // Maximum quantity of tokens to create
        uint256 maxTokensToCreate; 
        // Start time of the funding
        uint startTime; 
        // Closing time of the funding
        uint closingTime;  
        // The price (in wei) for a token without considering the inflation rate
        uint TokenPrice;
        // Rate per year applied to the token price 
        uint inflationRate; 
        // True if the funding is fueled
        bool isFueled;
    } fundingData public FundingRules;

    // Current total supply
    uint256 public totalSupply;
    // Map to allow token holder to refund if the funding didn't succeed
    mapping (address => uint256) weiGiven;

    // modifier to allow only the creator of the private funding to mint tokens
    modifier onlyCreator {if (msg.sender != address(creator)) throw; _ }
    // modifier to allow public to fund only in case of crowdfunding
    modifier onlyPublicTokenCreation {if (!FundingRules.publicTokenCreation) throw; _ }
    // modifier to allow partners to fund only in case of private funding
    modifier onlyPrivateTokenCreation {if (FundingRules.publicTokenCreation) throw; _ }

    /// @dev The constructor function
    /// @param _creator The contract wich created the token manager
    /// @param _publicTokenCreation True if public
    /// @param _initialTokenPrice Price without considering any inflation rate
    /// @param _minTokensToCreate Minimum quantity of tokens to fuel the funding
    /// @param _maxTokensToCreate If the maximum is reached, the funding is closed
    /// @param _startTime If 0, the start time is the creation date of this contract
    /// @param _closingTime After this date, the funding is closed
    /// @param _inflationRate If 0, the token price doesn't change during the funding
    /// @param _initialSupplyRecipient The address of recipient if there is an initial supply
    /// @param _initialSupply The quantity of tokens created before funding
    function TokenManager(
        address _creator, 
        bool _publicTokenCreation, 
        uint _initialTokenPrice, 
        uint256 _minTokensToCreate, 
        uint256 _maxTokensToCreate, 
        uint _startTime, 
        uint _closingTime,
        uint _inflationRate,
        address _initialSupplyRecipient, 
        uint256 _initialSupply
    );

    /// @notice Function to extent funding. Can be private or public
    /// @param _publicTokenCreation True if public
    /// @param _initialTokenPrice Price without considering any inflation rate
    /// @param _minTokensToCreate Minimum quantity of tokens to fuel the funding
    /// @param _maxTokensToCreate If the maximum is reached, the funding is closed
    /// @param _startTime If 0, the start time is the creation date of this contract
    /// @param _closingTime After this date, the funding is closed
    /// @param _inflationRate If 0, the token price doesn't change during the funding
    function extentFunding(
        bool _publicTokenCreation, 
        uint _initialTokenPrice, 
        uint256 _minTokensToCreate, 
        uint256 _maxTokensToCreate, 
        uint _startTime, 
        uint _closingTime, 
        uint _inflationRate
    ) onlyCreator;

    /// @notice Function to buy tokens in case of crowdfunding
    /// @param _tokenHolder The address of the token holder
    function buyToken(address _tokenHolder) 
    onlyPublicTokenCreation;

    /// @notice In case of private funding the creator can rewards tokens to the funders
    /// @param _tokenHolder The address of the token holder
    /// @param _amount The funded amount (in wei)
    /// @return Whether the token creation was successful
    function rewardToken(address _tokenHolder, uint _amount) 
    onlyCreator external returns (bool success);
    
    //// @notice Internal function to create tokens
    /// @param _tokenHolder The address of the token holder
    /// @param _amount The funded amount (in wei)
    /// @return Whether the token creation was successful
    function createToken(
        address _tokenHolder, 
        uint _amount
        ) internal returns (bool success);    

    /// @notice Function to allow token holders to refund if the funding didn't succeed    
    function refund();

    /// @notice Internal function to get the actual token price    
    /// @return The actual token price considering the inflation rate 
    function tokenPrice() internal returns (uint tokenPrice);
    
    event TokensCreated(address indexed tokenHolder, uint quantity);
    event FuelingToDate(uint value);
    event CreatedToken(address indexed to, uint amount);
    event Refund(address indexed to, uint value);
    
}

contract TokenManager is Token, TokenManagerInterface {

// Modifier that allows only shareholders to vote and create new proposals
modifier onlyTokenholders {if (balances[msg.sender] == 0) throw; _ }

    function TokenManager(
        address _creator, 
        bool _publicTokenCreation, 
        uint _initialTokenPrice, 
        uint256 _minTokensToCreate, 
        uint256 _maxTokensToCreate, 
        uint _startTime, 
        uint _closingTime,
        uint _inflationRate,
        address _initialSupplyRecipient, 
        uint256 _initialSupply
    ) {
        creator = _creator;

        if (_maxTokensToCreate == 0 || _closingTime == 0) {
            throw;
        }

        if (_startTime == 0) {
            FundingRules.startTime = now;
        }
        else {
            FundingRules.startTime = _startTime;
        }
        
        FundingRules.publicTokenCreation = _publicTokenCreation;
        FundingRules.closingTime = _closingTime; 
        
        FundingRules.minTokensToCreate = _minTokensToCreate; 
        FundingRules.maxTokensToCreate = _maxTokensToCreate;
        FundingRules.TokenPrice = _initialTokenPrice; 
        FundingRules.inflationRate = _inflationRate;  

        if (_initialSupply > 0) {
            balances[_initialSupplyRecipient]=_initialSupply; 
            totalSupply=_initialSupply;
        } 
    }


    function extentFunding(
        bool _publicTokenCreation, 
        uint _initialTokenPrice, 
        uint256 _minTokensToCreate, 
        uint256 _maxTokensToCreate, 
        uint _startTime, 
        uint _closingTime, 
        uint _inflationRate
    ) onlyCreator noEther {

        FundingRules.publicTokenCreation = _publicTokenCreation;
        if (_startTime == 0) {
            if (now > FundingRules.closingTime) {
            FundingRules.startTime = _startTime;}
            else {
                FundingRules.startTime = now;
            }
        }
        FundingRules.closingTime = _closingTime; 
        FundingRules.minTokensToCreate = totalSupply + _minTokensToCreate; 
        FundingRules.maxTokensToCreate = totalSupply + _maxTokensToCreate;
        FundingRules.TokenPrice = _initialTokenPrice; 
        FundingRules.inflationRate = _inflationRate;  
    }


    function buyToken(address _tokenHolder) 
    onlyPublicTokenCreation {
        
        if (msg.value < 0 || !createToken(_tokenHolder, msg.value)) throw;
        weiGiven[_tokenHolder] += msg.value;

    }

    
    function rewardToken(
        address _tokenHolder, 
        uint _amount
        ) onlyCreator noEther external returns (bool success) {
        
        return createToken(_tokenHolder, _amount);

    }


    function createToken(
        address _tokenHolder, 
        uint _amount
        ) internal returns (bool success) {

        uint quantity = _amount/tokenPrice();

        if ((totalSupply + quantity > FundingRules.maxTokensToCreate)
            || (now > FundingRules.closingTime) 
            || _amount <= 0
            || (now < FundingRules.startTime) ) {
            throw;
            }

        balances[_tokenHolder] += quantity; 
        totalSupply += quantity;
        TokensCreated(_tokenHolder, quantity);
        
        if (totalSupply == FundingRules.maxTokensToCreate) {
            FundingRules.closingTime = now;
        }

        if (totalSupply >= FundingRules.minTokensToCreate && !FundingRules.isFueled) {
            FundingRules.isFueled = true; 
            FuelingToDate(totalSupply);
        }

        return true;
    }
    

    function refund() onlyTokenholders noEther {
        if (!FundingRules.isFueled && now > FundingRules.closingTime) {
            if (msg.sender.call.value(weiGiven[msg.sender])()) {
                 Refund(msg.sender, weiGiven[msg.sender]);
                totalSupply -= balances[msg.sender];
                balances[msg.sender] = 0; weiGiven[msg.sender] = 0;
            }
        }
        else throw;
    }
    

    function tokenPrice() internal returns (uint tokenPrice) {
        return (1 + (FundingRules.inflationRate) * (now - FundingRules.startTime)/(365 days)) * FundingRules.TokenPrice;
    }
}    
  