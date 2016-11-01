import "TokenManager.sol";

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
 * The Account Manager smart contract is used for the management of ethers accounts.
 * The contract derives to the Token Manager smart contract used for
 * the management of tokens by a client smart contract (the Dao).
 * Allows to receive or withdraw ethers and to buy Dao shares.
 * Recipient is 0 for the Dao account manager and the address of
 * contractor's recipient for the account managers of contractors.
 *  
*/

/// @title Account Manager smart contract of the Pass Decentralized Autonomous Organisation
contract AccountManager is TokenManager {
    
    // Address of the creator or this smart contract
    address public creator;

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
    ) TokenManager(
        _creator,
        _client,
        _recipient,
        _initialSupply) {
        
        creator = _creator;

   }

     /// @return True if the sender is the creator of this account manager
    function IsCreator(address _sender) constant external returns (bool) {
        if (creator == _sender) return true;
    }

    /// @notice Fallback function to allow sending ethers to the account manager
    function () payable {
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

    /// @dev Function used by the client to send ethers from the Dao account manager
    /// @param _recipient The address to send to
    /// @param _amount The amount (in wei) to send
    /// @return Whether the transfer was successful or not
    function sendTo(
        address _recipient, 
        uint _amount
    ) external onlyClient returns (bool _success) {
    
        if (_amount > 0 && recipient == 0) return _recipient.send(_amount);    

    }

    /// @notice Function to allow contractors to withdraw ethers from their account manager
    /// @param _amount The amount (in wei) to withdraw
    function withdraw(uint _amount) {
        if (msg.sender != recipient
            || recipient == 0
            || !recipient.send(_amount)) throw;
    }
    
}    
  
