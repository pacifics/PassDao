## Project : A PEER-TO-PEER C2C TRANSPORTATION SYSTEM OF OBJECTS



## Overview
This DAO is open source and can be used to put together a transparent organization where governance and decision making system are immutably programmed in the Blockchain.
Note: Although the word "contract" is used in The DAO’s code, the term is a programming convention and is not being used as a legal term of art. The term is a programming convention, not a representation that the code is in and of itself a legally binding and enforceable contract. If you have questions about legal enforceability, consult with legal counsel.

## Short description
The smart contract have the next main functions: 

 - Fund: everyone from the ether Community who wants to join our Community and get shares can fund sending ethers. This crowdfunding will last one month. After this first stage, the shareholders can vote for a new crowdfunding or private funding. In case of private funding, the identity of the partner must be checked by the curator : a contract address chosen by the Dao shareholders and which represents a group of persons or an automatic procedure to proof identities.

 - Set a contractor proposal: every contractor can offer the DAO to sell products or execute services and ask for a voting process called board meeting. To make a new proposal will cost 10 ethers (to avoid useless proposals, can be updated by voting). Before the board meeting, the identity of the contractor must be checked by the curator.

 - Approve a contractor proposal: shareholders can vote for or against a contractor proposal during a board meeting which can last from two to eight weeks (can be updated by voting). If the quorum is more than 20% (minimal quorum can be updated by voting) and the positive votes are more than 50%, the contractor proposal is approved and can be completed. For each proposal, the voting process will reward the voters (reward amount can be updated by voting). This will incentive the Community members to be active members. 

 - Recieve contractor tokens: sending ethers to a contractor gives to DAO voters the right to recieve contractor tokens in proportion of their Dao shares. This will allow contractors to reward the Community. For the PM contractor, this function gives to DAO holders reputation tokens. 

- Transfer tokens: shares and contractor tokens are valuable and can be transfered.


## Solidity files

- DAO.sol:
Standard smart contract for a Decentralized Autonomous Organization (DAO) to automate organizational governance and decision-making.

- Token.sol:
Basic, standardized Token contract. Defines the functions to check token balances, send tokens, send tokens on behalf of a 3rd party and the corresponding approval process.

- TokenManager.sol:
Token Manager contract is used by the DAO for the management of tokens. The tokens can be created by a crowdfunding or by a private funding.
