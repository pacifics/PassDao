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

# Short description

The smart contract has the next main functions: 

- Set a contractor proposal: every contractor can offer the DAO to sell products or execute services and ask for a voting process called board meeting. To make a new proposal and organize a board meeting will cost minimum 10 ethers (to avoid useless proposals, minimum value can be updated by voting). The fees go to the voters according to their share in Dao. This will influence the Community members to be active members. 

- Approve a contractor proposal: shareholders can vote** for or against a contractor proposal*** during a board meeting which can last from two to eight weeks (can be updated by voting). If the quorum is more than 20% (minimal quorum can be updated by voting) and the positive votes are more than 50%, the contractor proposal is approved and the payment**** of proposal amount is completed. 

- Receive contractor tokens: sending ethers to a contractor gives to DAO voters the right to receive contractor tokens in proportion of their Dao shares. This will allow contractors to reward the Community according to the contractor proposal. For the PM contractor, this function gives to DAO holders reputation tokens which will be used for the project. 

- Able transfer of Dao shares and tokens : the Dao can vote to decide the start date to let their members transfer their shares and contractor tokens.


** The shareholders should vote on contractor proposals as it's the only way to recieve board meeting fees and contractor tokens. 

*** If the work of a contractor allows the development of our project, it should increase the value of reputation tokens which belong to the Community. In this case, there is no need for shareholders to report any revenue from the contractor. 

**** Rewards to the contractors are done with ethers and step by step for each contractor. Each new step starts with a new contractor proposal which includes a report about the result of the last proposal. All the voting weights of shareholders for all approved proposals of the contractor are stored as tokens in the account manager of the contractor. 

=

# About Security

- It is necessary to ask to be included in the mailing list in order to participate in the first funding. This is only to ensure decentralization. For the same reason, funding amount for each partner is limited depending on the balance in ether of the partner address. 

- There is no useless blocked ethers. Each funding is limited according according to the funding proposal. And if the Dao shareholders want to refund a part of the Dao balance, they can vote to send it to a contractor smart contract which will reward shareholders according to their share in Dao.

- There is no "calldata" function which could allow contractor smart contracts to run complex or recursive functions.
 
- There is no split function. There is one Dao which works according to the democracy law.

- Make a proposal will cost board meeting fees. In case of funding or Dao rules proposals, the fees return to the creator if the quorum is reached.

- A period to consider or set the proposal is foreseen before each board meeting. 

- The Dao will decide when the shares and contractor tokens can be transfered.

=

# Solidity Files

- DAO.sol:
Smart contract for a Decentralized Autonomous Organization (DAO) to automate organizational governance and decision-making. Proposals can be to fund the Dao, to change the Dao rules or to send Eth to a contractor. For each proposal, shareholders vote after a set period that can be extent by the creator of the proposal, and during a debate period. Approved proposal can be executed after a period predefined in the Dao rules. External functions are : NewContractorProposal, NewFundingProposal, NewDaoRulesProposal, ExtentSetPeriod, Vote, ExecuteDecision and RewardContractorTokens (for voters).

- AccountManager.sol:
The Account Manager smart contract is associated with a recipient (the Dao for dao shares and the contractor recipient for contractor tokens) and used for the management of tokens by a client smart contract (the dao). The Dao Account Manager contains the balance of the Dao. External functions are : BuyToken (default function for public fundings), BuyTokenFor (for private fundings), Refund (for the first funding if not fueled), UnblockAccount (tokenholder's accounts are blocked when voting and can be unblocked when the proposal is closed), Transfer (to transfer Dao tokens), TransferFrom (to transfer Dao tokens).

- Token.sol:
Basic, standardized Token contract. Defines the functions to check token balances, send tokens, send tokens on behalf of a 3rd party and the corresponding approval process. External functions are : Approve (tokens allowance).

- Funding.sol:
Smart contract used for the preliminary funding of the Dao. Each Eth address has to be associated with a partner included in the mailing list to become a shareholder of the Dao. All Eth addresses can refund for the amount sent and not funded. External functions are : IntentionToFund (default function to send Eth to the smart contract), FundDao (to send Eth to the Dao), Refund (to give back the balance to the shareholder).

