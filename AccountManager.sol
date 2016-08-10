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
        // Minimum quantity of tokens to create
        uint256 minTokensToCreate; 
        // Maximum quantity of tokens to create
        uint256 maxTokensToCreate; 
        // Start time of the funding
        uint startTime; 
        // Closing time of the funding
        uint closingTime;  
        // The price (in wei) for a token without considering the inflation rate
        uint initialTokenPrice;
        // Rate per year applied to the token price 
        uint inflationRate; 
    } 

    // Information about the recipient
    recipientData public Recipient;
    struct recipientData {
        // Address of the recipient
        address recipient;
        // Identification number given by the recipient
        uint RecipientID; 
        // Name of the recipient
        string RecipientName;  
    }
 
     // address of the Dao    
    address public client;

    // True if the funding is fueled
    bool isFueled;
   // If true, the tokens can be transfered
    bool public transferAble;
    // Total amount funded
    uint weiGivenTotal;

    // Map to allow token holder to refund if the funding didn't succeed
    mapping (address => uint) public weiGiven;
    // Map of addresses blocked during a vote. The address points to the proposal ID
    mapping (address => uint) blocked; 

    // Modifier that allows only the cient to manage tokens
    modifier onlyClient {if (msg.sender != address(client)) throw; _ }
    // modifier to allow public to fund only in case of crowdfunding
    modifier onlyRecipient {if (msg.sender != address(Recipient.recipient)) throw; _ }
    // Modifier that allows public to buy tokens only in case of crowdfunding
    modifier onlyPublicTokenCreation {if (!FundingRules.publicTokenCreation) throw; _ }
    // Modifier that allows the main partner to buy tokens only in case of private funding
    modifier onlyPrivateTokenCreation {if (FundingRules.publicTokenCreation) throw; _ }

    event RecipientChecked(address curator);
    event TokensCreated(address indexed tokenHolder, uint quantity);
    event FuelingToDate(uint value);
    event CreatedToken(address indexed to, uint amount);
    event Refund(address indexed to, uint value);
    event Clientupdated(address newClient);

}

///@title Token Manager contract is used by the DAO for the management of tokens
contract AccountManager is Token, AccountManagerInterface {


    // Modifier that allows only shareholders to vote and create new proposals
    modifier onlyTokenholders {if (balances[msg.sender] == 0) throw; _ }

    /// @dev Constructor setting the Client, Curator and Recipient
    /// @param _client The Dao address
    /// @param _recipient The recipient address
    /// @param _RecipientID Identification number given by the recipient
    /// @param _RecipientName Name of the recipient
    /// @param _initialSupply The initial supply of tokens for the recipient
    function AccountManager(
        address _client,
        address _recipient,
        uint _RecipientID,
        string _RecipientName,
        uint256 _initialSupply
    ) {
        client = _client;

        Recipient.recipient = _recipient;
        Recipient.RecipientID = _RecipientID;
        Recipient.RecipientName = _RecipientName;

        balances[_recipient] = _initialSupply; 
        totalSupply =_initialSupply;
        TokensCreated(_recipient, _initialSupply);
        
   }

    /// @notice Create Token with `msg.sender` as the beneficiary in case of public funding
    /// @dev Allow funding from partners if private funding
    /// @return Whether tokens are created or not
    function () returns (bool) {
        if (msg.sender == address(client) || msg.sender == FundingRules.mainPartner) {
            return; }
        else {
            createToken(msg.sender, msg.value);
            weiGiven[msg.sender] += msg.value;
            weiGivenTotal += msg.value;
            return true;
        }
    }

    /// @notice Create Token with `_tokenHolder` as the beneficiary
    /// @param _tokenHolder the beneficiary of the created tokens
    /// @param _amount the amount funded
    function buyTokenFor(
        address _tokenHolder,
        uint _amount
        ) onlyPrivateTokenCreation {
        
        if (msg.sender != FundingRules.mainPartner) throw;

        createToken(_tokenHolder, _amount);
        weiGiven[_tokenHolder] += _amount;
        weiGivenTotal += _amount;

    }

    /// @notice Refund in case the funding id not fueled
    // @return Whether ethers are refund or not
    function refund() noEther returns (bool) {
        
        if (!isFueled && now > FundingRules.closingTime) {
        
            uint _amount = weiGiven[msg.sender]*uint(this.balance)/weiGivenTotal;
            if (_amount >0 && msg.sender.call.value(_amount)()) {
                Refund(msg.sender, weiGiven[msg.sender]);
                totalSupply -= balances[msg.sender];
                balances[msg.sender] = 0; 
                weiGiven[msg.sender] = 0;
                return true;
            }

        }
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
    
    /// @dev Function used by the client
    /// @return Whether the funding is fueled or not
    function IsFueled() external constant returns (bool) {
        return isFueled;
    }

    /// @dev Function used by the client
    /// @return The maximum tokens after the funding
    function MaxTokensToCreate() external returns (uint) {
        return (FundingRules.maxTokensToCreate);
    }
    
    /// @dev Function used by the client
    /// @return the actual token price condidering the inflation rate
    function tokenPrice() constant returns (uint) {
        return (1 + (FundingRules.inflationRate) * (now - FundingRules.startTime)/(100*365 days)) * FundingRules.initialTokenPrice;
    }

    /// @dev Function to extent funding. Can be private or public
    /// @param _publicTokenCreation True if public
    /// @param _initialTokenPrice Price without considering any inflation rate
    /// @param _minTokensToCreate Minimum quantity of tokens to fuel the funding
    /// @param _maxTokensToCreate If the maximum is reached, the funding is closed
    /// @param _startTime If 0, the start time is the creation date of this contract
    /// @param _closingTime After this date, the funding is closed
    /// @param _inflationRate If 0, the token price doesn't change during the funding
    function extentFunding(
        address _mainPartner,
        bool _publicTokenCreation, 
        uint _initialTokenPrice, 
        uint256 _minTokensToCreate, 
        uint256 _maxTokensToCreate, 
        uint _startTime, 
        uint _closingTime, 
        uint _inflationRate
    ) external onlyClient {

        FundingRules.mainPartner = _mainPartner;
        FundingRules.publicTokenCreation = _publicTokenCreation;
        FundingRules.startTime = _startTime;
        FundingRules.closingTime = _closingTime; 
        FundingRules.minTokensToCreate = totalSupply + _minTokensToCreate; 
        FundingRules.maxTokensToCreate = totalSupply + _maxTokensToCreate;
        FundingRules.initialTokenPrice = _initialTokenPrice; 
        FundingRules.inflationRate = _inflationRate;  
        
    } 
        
    /// @dev Function used by the client to send ethers
    /// @param _recipient The address to send to
    /// @param _amount The amount to send
    function sendTo(
        address _recipient, 
        uint _amount
    ) external onlyClient {
        if (!_recipient.send(_amount)) throw;    
    }
    
    /// @dev Function used by the Dao to reward of tokens
    /// @param _tokenHolder The address of the token holder
    /// @param _amount The amount in Wei
    function rewardToken(
        address _tokenHolder, 
        uint _amount
        ) external  onlyClient {
        
        createToken(_tokenHolder, _amount);

    }

    /// @dev Function used by the client to block tokens transfer of from a tokenholder
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
    
    /// @dev Function used by the client to able or disable the refund of tokens
    /// @param _transferAble Whether the client want to able to refund or not
    function TransferAble(bool _transferAble) external onlyClient {
        transferAble = _transferAble;
    }

    /// @dev Internal function for the creation of tokens
    /// @param _tokenHolder The address of the token holder
    /// @param _amount The funded amount (in wei)
    function createToken(
        address _tokenHolder, 
        uint _amount
    ) internal {

        uint _tokenholderID;
        uint _quantity = _amount/tokenPrice();

        if ((totalSupply + _quantity > FundingRules.maxTokensToCreate)
            || (now > FundingRules.closingTime && FundingRules.closingTime !=0) 
            || _amount <= 0
            || (now < FundingRules.startTime) ) {
            throw;
            }

        balances[_tokenHolder] += _quantity; 
        totalSupply += _quantity;
        TokensCreated(_tokenHolder, _quantity);
        
        if (totalSupply == FundingRules.maxTokensToCreate) {
            FundingRules.closingTime = now;
        }

        if (totalSupply >= FundingRules.minTokensToCreate 
        && !isFueled) {
            isFueled = true; 
            FuelingToDate(totalSupply);
        }

    }
   
    // Function transfer only if the funding is not fueled and the account is not blocked
    function transfer(
        address _to, 
        uint256 _value
        ) returns (bool success) {  

        if (isFueled
            && transferAble
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
        
        if (isFueled
            && transferAble
            && blocked[_from] == 0
            && blocked[_to] == 0
            && _to != address(this)
            && now > FundingRules.closingTime 
            && super.transfer(_to, _value)) {
            return true;
        } else {
            throw;
        }
        
    }
    
}    
  
