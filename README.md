# Our Decentralized Autonomous Organization

=

### Project : A PEER-TO-PEER C2C TRANSPORTATION SYSTEM OF OBJECTS

Website : http://pacifics.org/

=

## Overview
Our DAO is open source and used for our project to put together a transparent organization where governance and decision making system are immutably programmed in the Blockchain. 

=

## Note
This Dao is for Ethereum Blockchain (ETH) only and is not foreseen to run on "Ethereum Classic" Blockchain (ETC).

=

## Short description
The smart contracts have the next main functions: 

 - Fund: everyone from the ether Community who wants to join our Community and get shares can fund sending ethers. The funding has two stages. During the first stage (two weeks), the new partners (ether holders) indicate the amount they intend to fund (they pay only gas for transaction). This first stage will allow to determine limits in amount and ether balance share for all partner addresses with the next main goal : to have a decentralized Community. The second stage (two weeks) will allow partners to fund the Dao according to their intention and the set limits. After this first funding, the new partners become shareholders and can vote for a new crowdfunding or a private funding. 

 - Set a contractor proposal: every contractor can offer the DAO to sell products or execute services and ask for a voting process called board meeting. To make a new proposal and organize a board meeting will cost minimum 10 ethers (to avoid useless proposals, minimum value can be updated by voting). The fees go to the voters according to their share in Dao. This will incentive the Community members to be active members. 
 
 - Approve a contractor proposal: shareholders can vote for or against a contractor proposal during a board meeting which can last from two to eight weeks (can be updated by voting). If the quorum is more than 20% (minimal quorum can be updated by voting) and the positive votes are more than 50%, the contractor proposal is approved and the payment of proposal amount is completed. 

 - Recieve contractor tokens: sending ethers to a contractor gives to DAO voters the right to recieve contractor tokens in proportion of their Dao shares. This will allow contractors to reward the Community according to the contractor proposal. For the PM contractor, this function gives to DAO holders reputation tokens which will be used for the project. 

- Able transfer of Dao shares and tokens : the Dao can vote to let their members transfer their shares and contractor tokens.

=

# About Security

- There is no useless blocked ethers. The presale starts with only funding intentions and the minimum and maximum funding amounts are limited according to what is needed to start the project and to ensure decentralization. If the Dao shareholders want to refund a part of the Dao balance, they can vote to send it to a contractor smart contract which will reward shareholders according to their share in Dao.

- There is no "calldata" function which could allow contractor smart contracts to run complex or recursive functions.
 
- Rewards to the contractors are done with ethers and step by step for each contractor. Each new step starts with a new contractor proposal which includes a report about the result of the last proposal. All the voting weights of shareholders for all approved proposals of the contractor are stored as tokens in the account manager of the contractor.

- If the work of a contractor allows the development of our project, it should increase the value of reputation tokens which belong to the Community. In this case, there is no need for shareholders to report any revenue from the contractor.

- There is no split function. There is one Dao which works according to the democracy law.

- Make a proposal will cost board meeting fees. In case of funding or Dao rules proposals, the fees return to the creator if the quorum is reached.

- A period to consider or set the proposal is foreseen before each board meeting. 

- The shareholders should vote on contractor proposals as it's the only way to recieve board meeting fees and contractor tokens.

- The Dao will decide when the shares and contractor tokens can be transfered.

=

# Solidity Files

- DAO.sol:
Smart contract for a Decentralized Autonomous Organization (DAO) to automate organizational governance and decision-making.

- AccountManager.sol:
The Account Manager smart contract is associated with a recipient (the Dao for dao shares and the contractor recipient for contractor tokens) and used for the management of tokens by a client smart contract (the dao).

- Token.sol:
Basic, standardized Token contract. Defines the functions to check token balances, send tokens, send tokens on behalf of a 3rd party and the corresponding approval process.

- Funding.sol:
Smart contract used for the presale of Dao shares. 

=

## See Beta version on Testnet

For the presale, the Funding address : 0x95D35014fc727F6f5C849A60E5256C7D1bfC6158

To make proposals, the Dao address : 0xcc2d68D2494640d7904858353fA79AB98d46C49d

To see balances, the Dao Account Manager address : 0x39eAFFdD3Cc3957f150C6a2130a8DaCA3f79D28e
