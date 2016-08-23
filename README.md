# Our Decentralized Autonomous Organization

=

### Project : A PEER-TO-PEER C2C TRANSPORTATION SYSTEM OF OBJECTS

Website : http://pacifics.org/dao

=

## Overview
Our DAO is open source and used for our project to put together a transparent organization where governance and decision making system are immutably programmed in the Blockchain. 

=

## Note
This Dao is for Ethereum Blockchain (ETH) only and is not foreseen to run on "Ethereum Classic" Blockchain (ETC).

=

# About Security

- There is no useless blocked ethers. The presale starts with only funding intentions and the minimum and maximum funding amounts are limited according to what is needed to start the project and to ensure decentralization. If the Dao shareholders want to refund a part of the Dao balance, they can vote to send it to a contractor smart contract which will reward shareholders according to their share in Dao.

- There is no "calldata" function which could allow contractor smart contracts to run complex or recursive functions.
 
- There is no split function. There is one Dao which works according to the democracy law.

- Make a proposal will cost board meeting fees. In case of funding or Dao rules proposals, the fees return to the creator if the quorum is reached.

- A period to consider or set the proposal is foreseen before each board meeting. 

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

For the presale, the Funding address : 0x03fB2eD967a23AeB844963F24e8Bd8a94d30d706

To make proposals, the Dao address : 0xA707cd659A3E0e28654Fe2C362F1b326F17f8B09

To see balances, the Dao Account Manager address : 0xC418EE9603623bB87106956a64824be82c0d664C
