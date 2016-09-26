/*
Basic, standardized Token contract with no "premine". Defines the functions to
check token balances, send tokens, send tokens on behalf of a 3rd party and the
corresponding approval process.
*/

contract TokenInterface {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    /// Total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);
    
    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    
    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    /// its behalf
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _amount) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    /// to spend
    function allowance(
        address _owner,
        address _spender
    ) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
    );
}

contract Token is TokenInterface {
    
    // Protects users by preventing the execution of method calls that
    // inadvertently also transferred ether
    modifier noEther() {if (msg.value > 0) throw; _}

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) noEther returns (bool success) {
        if (balances[msg.sender] >= _amount && _amount > 0) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
           return false;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) noEther returns (bool success) {

        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0) {

            balances[_to] += _amount;
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

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
    mapping (address => uint256) weiGiven;
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
    function () {
        if (FundingRules.publicTokenCreation) {
            buyToken(msg.sender, msg.value);
        }
    }

    /// @notice Create Token with `_tokenHolder` as the beneficiary
    /// @param _tokenHolder the beneficiary of the created tokens
    /// @param _amount the amount funded
    /// @return Whether the transfer was successful or not
    function buyTokenFor(
        address _tokenHolder,
        uint _amount
        ) onlyPrivateTokenCreation returns (bool _succes) {
        
        if (msg.sender != FundingRules.mainPartner) throw;

        return buyToken(_tokenHolder, _amount);

    }
     
    /// @notice Create Token with `_tokenHolder` as the beneficiary
    /// @param _tokenHolder the beneficiary of the created tokens
    /// @param _amount the amount funded
    /// @return Whether the transfer was successful or not
    function buyToken(
        address _tokenHolder,
        uint _amount) internal returns (bool _succes) {
        
        if (createToken(_tokenHolder, _amount)) {
            weiGiven[_tokenHolder] += _amount;
            weiGivenTotal += _amount;
            return true;
        }
        else throw;

    }
    
    /// @notice Refund in case the funding is not fueled
    function refund() noEther {
        
        if (!isFueled && now > FundingRules.closingTime) {
 
            uint amount = weiGiven[msg.sender];
            weiGiven[msg.sender] = 0;
            if (msg.sender.send(amount)) {
                Refund(msg.sender, amount);
                totalSupply -= balances[msg.sender];
                balances[msg.sender] = 0; 
            }
            else weiGiven[msg.sender] = amount;

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

    function setMinTokensToCreate(uint256 _minTokensToCreate) external returns (uint) {
        FundingRules.minTokensToCreate = _minTokensToCreate; 
    }
        
    /// @dev Function used by the client
    /// @return The maximum tokens after the funding
    function MaxTokensToCreate() external returns (uint) {
        return (FundingRules.maxTokensToCreate);
    }
    
    /// @dev Function used by the client
    /// @return the actual token price condidering the inflation rate
    function tokenPrice() constant returns (uint) {
        return FundingRules.initialTokenPrice 
            + FundingRules.initialTokenPrice*(FundingRules.inflationRate)*(now - FundingRules.startTime)/(100*365 days);
    }

    /// @dev Function to extent funding. Can be private or public
    /// @param _publicTokenCreation True if public
    /// @param _initialTokenPrice Price without considering any inflation rate
    /// @param _maxTokensToCreate If the maximum is reached, the funding is closed
    /// @param _startTime If 0, the start time is the creation date of this contract
    /// @param _closingTime After this date, the funding is closed
    /// @param _inflationRate If 0, the token price doesn't change during the funding
    function extentFunding(
        address _mainPartner,
        bool _publicTokenCreation, 
        uint _initialTokenPrice, 
        uint256 _maxTokensToCreate, 
        uint _startTime, 
        uint _closingTime, 
        uint _inflationRate
    ) external onlyClient {

        FundingRules.mainPartner = _mainPartner;
        FundingRules.publicTokenCreation = _publicTokenCreation;
        FundingRules.startTime = _startTime;
        FundingRules.closingTime = _closingTime; 
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
    /// @return Whether the transfer was successful or not
    function rewardToken(
        address _tokenHolder, 
        uint _amount
        ) external  onlyClient returns (bool _success) {
        
        if (createToken(_tokenHolder, _amount)) return true;
        else throw;

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
    /// @return Whether the transfer was successful or not
    function createToken(
        address _tokenHolder, 
        uint _amount
    ) internal returns (bool _success) {

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
        
        return true;
        
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
