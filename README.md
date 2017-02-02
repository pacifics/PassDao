# The DAPP of PASS DAO

=

Website : http://forum.passdao.org/

=

## Overview
Open source Decentralized Application used to put together a transparent organization where governance and decision making system are immutably programmed in the Blockchain. The source includes six separated smart contracts.

=

## PASS DAO and PASS DAO Project Smart Contracts

Smart contracts used for the management of the upgrades and projects from the beginning of the application.

=

## PASS DAO Contractor Smart Contract

Smart contract used by the project managers and contractors of the application.

Public functions are : 

- Update Project Description (for the project manager).

- Update recipient and withdraw: allows the contractors using their manager as an account with deposits and withdrawals.

- Set a new proposal: every contractor can offer to sell products or execute services. Payments to the contractors are done with ethers and step by step. 

=

## PASS DAO Manager and Pass DAO Token Manager Smart Contract

Smart contract used for the management of tokens. The smart contract derives to the Token Manager smart contract used for the management of tokens. The smart contract is conform to ERC20.

Public functions are : 

- Buy Tokens, Sell Tokens and Remove buy orders: allows to buy and sell transferable tokens using the application.

- Buy tokens and promote proposals: allows to buy tokens in order to pay a project manager according to an approved proposal.

- Transfer tokens and Approve tokens allowance: ERC20 functions.

=

## The Committee Room Smart Contract

Smart contract used to submit proposals to vote and to execute the decisions of the shareholders.

Public functions are :

- Propose to create a new project

- Propose to be a contractor

- Submit a Funding proposal

- Submit a question to the vote of the Community

- Propose to change the Dao rules

- Propose to upgrade one or all the smart contracts (except Pass DAO who can't be updated)

- Vote (for shareholders)

- Buy shares and promote proposals:  allows to buy sharesin order to pay a contractor according to an approved proposal.

=

# Notes

- This Dao is for Ethereum Blockchain (ETH) only and is not foreseen to run on "Ethereum Classic" Blockchain (ETC).

- If the work of a contractor allows the development of the projects, it should increase the value of shares and Pass reputation tokens which belongs to the Community. In this case, there is no need for shareholders to report any revenue from the contractor. 

- Make a proposal will cost board meeting fees. In case of funding or Dao rules proposals, the creator of the proposal will receive shares if the proposal is estimated (but not necessarily approved).

- The shareholders should vote on contractor proposals as it's the only way to receive board meeting fees. 

=

# About Security

- By allowing fundings (public or private) for each step of the project and by limiting the funding amounts, we limit the amount of money "at risk" and avoid useless blocked ethers in the Dao.

- Only the Dao shareholders can decide by vote to allow the transfer of shares.
