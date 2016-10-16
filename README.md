# Our Decentralized Autonomous Organization

=

## The Project : A PEER-TO-PEER C2C TRANSPORTATION SYSTEM OF OBJECTS

Website : http://pacifics.org/dao

=

## Overview
Our DAO is open source and used for our project to put together a transparent organization where governance and decision making system are immutably programmed in the Blockchain. 

=

## Note
This Dao is for Ethereum Blockchain (ETH) only and is not foreseen to run on "Ethereum Classic" Blockchain (ETC).


=

## The Dao Smart Contract

Proposals can be to fund the Dao, to change the Dao rules or to send Eth to a contractor. For each proposal, shareholders vote after a set period that can be extent by the creator of the proposal, and during a debate period. Approved proposal can be executed during a period predefined in the Dao rules.

Main functions: 

- Set a contractor proposal: every contractor can offer the DAO to sell products or execute services and ask for a voting process called board meeting. To make a new proposal and organize a board meeting will cost minimum 10 ethers (to avoid useless proposals, minimum value can be updated by voting). The fees go to the voters according to their share in Dao. This will incentivize the Community members to be active members. 

- Approve a contractor proposal: shareholders can vote for or against a contractor proposal during a board meeting which can last from two to eight weeks (can be updated by voting). If the quorum is more than 20% (minimal quorum can be updated by voting) and the positive votes are more than 50%, the contractor proposal is approved and the payment of proposal amount is completed. 

- Receive contractor tokens: sending ethers to a contractor gives to DAO voters the right to receive contractor tokens in proportion of their Dao shares. This will allow contractors to reward the shareholder according to the contractor proposal. For the PM contractor, this function gives to DAO holders reputation tokens which will be used for the project. 

- Able transfer of Dao shares and tokens : the Dao can vote to decide the start date to let their members transfer their shares and contractor tokens.

Notes :

- If the work of a contractor allows the development of our project, it should increase the value of reputation tokens which belong to the Community. In this case, there is no need for shareholders to report any revenue from the contractor. 

- Rewards to the contractors are done with ethers and step by step for each contractor. Each new step starts with a new contractor proposal which includes a report about the result of the last proposal.  

=

## The Account Manager Smart Contract

The smart contract derive to the basic, standardized Token contract Token.sol. The Account Manager smart contract is associated with a recipient (the Dao for dao shares and the contractor recipient for contractor tokens) and used for the management of tokens by a client smart contract (the dao). The Dao Account Manager contains the balance of the Dao. An account manager smart contract is also created for each contractor.

Main functions are : 

- SendEth (default function). 

- BuyToken (for public fundings) and BuyTokenFor (for private fundings)

- UnblockAccount (tokenholder's accounts are blocked when voting and can be unblocked when the proposal is closed)

- Transfer (to transfer tokens) and TransferFrom (to transfer tokens)

- Approve (tokens allowance). 

=

## The Funding Smart Contract

Smart contract used for the preliminary funding of the Dao. Each partner has to send an Eth address to be included in the mailing list and become a shareholder of the Dao. All Eth addresses can refund for the amount sent and not funded. 

Main functions: 

- IntentionToFund: default function to send Eth to the Funding smart contract.

- SetPartners: allows the smart contract creator to validate Eth addresses according to the mailing list.

- SetLimits and SetFundingLimits: allows the smart contract creator to set the funding limits (amount and percentage of ether balance share) for all partners.

- FundDaoFor: to send Eth from the Funding smart contract to the Dao and according to the set limits if the funding is fueled.

- Refund: to refund the not funded amount.

=

# About Security

- It is necessary to be included in the mailing list in order to participate in the first funding. It will help communicating with shareholders, avoid the possibility to fund using "hundreds" addresses and allow to check that partners's addresses are not related to a smart contract. 

- We limit the amount to send to the funding smart contract and if fueled we limit the amount to fund to the Dao for each partner. Our first goal is decentralization and we don't want to limit the ability to become a shareholder 

- By allowing fundings (public or private) for each step of the project and by limiting the funding amounts, we avoid useless blocked ethers in the Dao. It is possible to link a funding proposal with a contractor proposal and that will be completed only if the funding is fueled during a predefined period, unless the Dao is not funded and the contractor proposal not completed. We use this method for the first Project Manager proposal and the primary funding. For the next steps of the project, we can proceed in the same way and with no ether balance in the Dao after the funding.

- Make a proposal will cost board meeting fees. In case of funding or Dao rules proposals, the fees return to the creator of the proposal if the quorum is reached.

- A period to consider or set the proposal is foreseen before each board meeting. 

- The shareholders should vote on contractor proposals as it's the only way to receive board meeting fees and contractor tokens. The contractor proposal can foresee an inflation rate for the reward of contractor tokens which will incentivize shareholders to vote early.

- Only the Dao shareholders can decide by vote to allow the transfer of shares.

- There is no calldata function.  We use a “withdraw” pattern instead of a “send” pattern for the reward of board meeting fees to tokenholders or the payment of approved proposal amounts to contractors. 

- Refund from the funding smart contract will be before the closing time of the primary funding for the valid adresses and after the closing time of the primary funding for the not valid adresses.

