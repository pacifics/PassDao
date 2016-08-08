# Our Decentralized Autonomous Organization

=

### Project : A PEER-TO-PEER C2C TRANSPORTATION SYSTEM OF OBJECTS

Website : http://pacifics.org/

=

## Overview
This DAO is open source and used to put together a transparent organization where governance and decision making system are immutably programmed in the Blockchain. One of the many advantages of having a "robot" run our organization is that it is immune to any outside influence as it’s guaranteed to execute only what it was programmed to. 
Note: Although the word "contract" is used in The DAO’s code, the term is a programming convention and is not being used as a legal term of art. 

=

## Short description
The smart contract have the next main functions: 

 - Fund: everyone from the ether Community who wants to join our Community and get shares can fund sending ethers. This crowdfunding will last one month. The main goal of this funding is to set Community partners in a decentralized way. After this first stage, the shareholders can vote for a new crowdfunding or a private funding. 

 - Set a contractor proposal: every contractor can offer the DAO to sell products or execute services and ask for a voting process called board meeting. To make a new proposal and organize a board meeting will cost minimum 10 ethers (to avoid useless proposals, minimum can be updated by voting). The fees go to the voters according to their share in Dao. This will incentive the Community members to be active members. 
 
 - Approve a contractor proposal: shareholders can vote for or against a contractor proposal during a board meeting which can last from two to eight weeks (can be updated by voting). If the quorum is more than 20% (minimal quorum can be updated by voting) and the positive votes are more than 50%, the contractor proposal is approved and the payment is completed. 

 - Recieve contractor tokens: sending ethers to a contractor gives to DAO voters the right to recieve contractor tokens in proportion of their Dao shares. This will allow contractors to reward the Community according to the contractor proposal. For the PM contractor, this function gives to DAO holders reputation tokens. 

- Transfer tokens: after an initial period, the Dao can vote to let their members transfer their shares in Dao.

- Refund: the Dao can vote to refund its balance.


=

## Solidity files

- Token.sol:
Basic, standardized Token contract. Defines the functions to check token balances, send tokens, send tokens on behalf of a 3rd party and the corresponding approval process.

- AccountManager.sol:
The Account Manager smart contract is associated with a recipient and used for the management of tokens by a client smart contract (the dao).

- Funding.sol:
The Funding smart contract used for the funding of the Dao.

- DAO.sol:
Smart contract for a Decentralized Autonomous Organization (DAO) to automate organizational governance and decision-making.
