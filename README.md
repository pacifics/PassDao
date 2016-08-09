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

 - Fund: everyone from the ether Community who wants to join our Community and get shares can fund sending ethers. The funding has two stages. During the first stage (two weeks), the new partners (ether holders) indicate the amount they intend to fund (they pay only gas for transaction). This first stage will allow to determine limits in amount and ether balance share for all partner addresses with the next main goal : to have a decentralized Community. The second stage (two weeks) will allow partners to fund the Dao according to their intention and the set limits. After this first funding, the new partners become shareholders and can vote for a new crowdfunding or a private funding. 

 - Set a contractor proposal: every contractor can offer the DAO to sell products or execute services and ask for a voting process called board meeting. To make a new proposal and organize a board meeting will cost minimum 10 ethers (to avoid useless proposals, minimum value can be updated by voting). The fees go to the voters according to their share in Dao. This will incentive the Community members to be active members. 
 
 - Approve a contractor proposal: shareholders can vote for or against a contractor proposal during a board meeting which can last from two to eight weeks (can be updated by voting). If the quorum is more than 20% (minimal quorum can be updated by voting) and the positive votes are more than 50%, the contractor proposal is approved and the payment is completed. 

 - Recieve contractor tokens: sending ethers to a contractor gives to DAO voters the right to recieve contractor tokens in proportion of their Dao shares. This will allow contractors to reward the Community according to the contractor proposal. For the PM contractor, this function gives to DAO holders reputation tokens. 

- Transfer Dao shares: the Dao can vote to let their members transfer their shares in Dao.

=

# Solidity Files

- DAO.sol:
Smart contract for a Decentralized Autonomous Organization (DAO) to automate organizational governance and decision-making.

- AccountManager.sol:
The Account Manager smart contract is associated with a recipient (the Dao for dao shares and the recipient for contractor tokens) and used for the management of tokens by a client smart contract (the dao).

- Token.sol:
Basic, standardized Token contract. Defines the functions to check token balances, send tokens, send tokens on behalf of a 3rd party and the corresponding approval process.

- Funding.sol:
Standard smart contract used for the funding of the Dao. One smart contract is associated with each funding. 

=

# About Security

- There is no useless blocked ethers. The funding starts with only funding intentions and the maximum funding amount is limited according of what is needed to start the project and to ensure decentralization.

- There is no "calldata" function. There is a "send" function for approved contractor proposals.

- There is no split function. There is one Dao which works according to the democraty law.

- The Dao will decide when the shares can be transfered.

=

## See Beta version on Testnet

For the presale, the Funding address : 0xb6875e1A6FceB5509543E116625449C1622B4EaA

To make proposals, the Dao address : 0xaEFb92D6a6f6EF875Cc98190866A9F167F6c5d60

To see balances, the Dao Account Manager address : 0xC4DB31856959468431814a219e6C42C50DDf73f0
