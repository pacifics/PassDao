import "PassDao.sol";
import "PassTokenManager.sol";

pragma solidity ^0.4.6;

/*
 *
 * This file is part of Pass DAO.
 *
 * The Manager smart contract is used for the management of the Dao account, shares and tokens.
 *
*/

/// @title Manager smart contract of the Pass Decentralized Autonomous Organisation
contract PassManager is PassTokenManager {
    
    struct order {
        address buyer;
        uint weiGiven;
    }
    // Orders to buy tokens
    order[] public orders;
    // Number or orders to buy tokens
    uint numberOfOrders;
    
    function PassManager(
        PassDao _passDao,
        address _clonedFrom,
        string _tokenName,
        string _tokenSymbol,
        uint8 _tokenDecimals,
        bool _transferableToken,
        uint _initialPriceMultiplier,
        uint _inflationRate) 
        PassTokenManager( _passDao, _clonedFrom, _tokenName, _tokenSymbol, _tokenDecimals, 
            _transferableToken, _initialPriceMultiplier, _inflationRate) { }
    
    /// @notice Function to receive payments
    function () payable onlyShareManager { }
    
    /// @notice Function used by the client to send ethers from the Dao manager
    /// @param _recipient The address to send to
    /// @param _amount The amount (in wei) to send
    /// @return Whether the transfer was successful or not
    function sendTo(
        address _recipient,
        uint _amount
    ) external onlyClient returns (bool) {

        if (_recipient.send(_amount)) return true;
        else return false;
    }

    /// @dev Internal function to buy tokens and promote a proposal 
    /// @param _proposalID The index of the proposal
    /// @param _buyer The address of the buyer (not mandatory, msg.sender if 0)
    /// @param _date The unix date to consider for the share or token price calculation
    /// @param _presale True if presale
    /// @return Whether the function was successful or not 
    function buyTokensFor(
        uint _proposalID,
        address _buyer, 
        uint _date,
        bool _presale) internal returns (bool) {

        if (!sale(_proposalID, _buyer, msg.value, _date, _presale)) throw;

        fundings[_proposalID].totalWeiGiven += msg.value;        
        if (fundings[_proposalID].totalWeiGiven == fundings[_proposalID].amountToFund) closeFunding(_proposalID);

        Given[_proposalID][_buyer].weiAmount += msg.value;
        
        return true;
    }
    
    /// @notice Function to buy tokens and promote a proposal 
    /// @param _proposalID The index of the proposal
    /// @param _buyer The address of the buyer (not mandatory, msg.sender if 0)
    /// @return Whether the function was successful or not 
    function buyTokensForProposal(
        uint _proposalID, 
        address _buyer) payable returns (bool) {

        if (_buyer == 0) _buyer = msg.sender;

        if (fundings[_proposalID].moderator != 0) throw;

        return buyTokensFor(_proposalID, _buyer, now, true);
    }

    /// @notice Function used by the moderator to buy shares or tokens
    /// @param _proposalID Index of the client proposal
    /// @param _buyer The address of the recipient of shares or tokens
    /// @param _date The unix date to consider for the share or token price calculation
    /// @param _presale True if presale
    /// @return Whether the function was successful or not 
    function buyTokenFromModerator(
        uint _proposalID,
        address _buyer, 
        uint _date,
        bool _presale) payable external returns (bool){

        if (msg.sender != fundings[_proposalID].moderator) throw;

        return buyTokensFor(_proposalID, _buyer, _date, _presale);
    }

    /// @notice Function to create orders to buy tokens
    /// @return Whether the function was successful or not
    function buyTokens() payable returns (bool) {

        if (!transferable || msg.value < 100 finney) throw;
        
        uint i;
        numberOfOrders += 1;

        if (numberOfOrders > orders.length) i = orders.length++;
        else i = numberOfOrders - 1;
        
        orders[i].buyer = msg.sender;
        orders[i].weiGiven = msg.value;
        
        return true;
    }
    
    /// @dev Internal function to remove the first order
    function removeOrder() internal {
        
        uint o;
        
        numberOfOrders -= 1;
        if (numberOfOrders > 0) {
            for (o = 0; o <= numberOfOrders - 1; o++) {
                orders[o].buyer = orders[o+1].buyer;
                orders[o].weiGiven = orders[o+1].weiGiven;
            }
        }
        orders[numberOfOrders].buyer = 0;
        orders[numberOfOrders].weiGiven = 0;
    }
    
    /// @notice Function to sell tokens
    /// @param _tokenAmount in tokens to sell
    /// @return the revenue in wei
    function sellTokens(uint _tokenAmount) returns (uint) {

        if (!transferable 
            || uint(balances[msg.sender]) < _amount 
            || numberOfOrders == 0) throw;
        
        uint _tokenAmount0;
        uint _amount;
        uint _totalAmount;
        int i = 0;
        uint o;
        
        
        while (i++ < 10) {
            
            if (numberOfOrders > 0 && _tokenAmount > 0) {

                _tokenAmount0 = TokenAmount(orders[0].weiGiven, priceMultiplier(0), actualPriceDivisor(0));

                if (_tokenAmount >= _tokenAmount0 && orders[0].buyer != msg.sender) {

                    _tokenAmount -= _tokenAmount0;
                    
                    transfer(orders[0].buyer, _tokenAmount0); 
                    _totalAmount += orders[0].weiGiven;

                    removeOrder();
                }
            }
        }
        
        if (numberOfOrders > 0 && _tokenAmount > 0) {

            _tokenAmount0 = TokenAmount(orders[0].weiGiven, priceMultiplier(0), actualPriceDivisor(0));

            if (_tokenAmount0 > _tokenAmount && orders[0].buyer != msg.sender) {
                _amount = weiAmount(_tokenAmount, priceMultiplier(0), actualPriceDivisor(0));

                orders[0].weiGiven -= _amount;
                
                transfer(orders[0].buyer, _tokenAmount); 
                _totalAmount += _amount;
            }
        }

        if (!msg.sender.send(_totalAmount)) throw;
        else return _totalAmount;
    }    

    /// @notice Function to remove your orders and refund
    /// @return Whether the function was successful or not
    function removeOrders() returns (bool) {

        uint _totalAmount;
        int i = 0;
        uint o;

        while (i++ < 10) {

            if (numberOfOrders > 0 && orders[0].buyer == msg.sender) {
                
                _totalAmount += orders[0].weiGiven;
                removeOrder();
            }
        }

        if (!msg.sender.send(_totalAmount)) throw;
        else return true;
    }

}    
