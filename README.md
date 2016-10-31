# Our Decentralized Autonomous Organization

=

## The Project : A PEER-TO-PEER C2C TRANSPORTATION SYSTEM OF OBJECTS

Website : http://pacifics.org/dao

=

## Overview
Our DAO is open source and used for our project to put together a transparent organization where governance and decision making system are immutably programmed in the Blockchain. 

=


## The Dao Smart Contract

Proposals can be to fund the Dao, to change the Dao rules or to send Eth to a contractor. For each proposal, shareholders vote after a set period and during a debate period called board meeting.

Main functions: 

- Set a contractor proposal: every contractor can offer the DAO to sell products or execute services. To make a new proposal and organize a board meeting will cost minimum 10 ethers (to avoid useless proposals, minimum value can be updated by voting). The fees go to the voters according to their share in the Dao. Voters can also receive contractor tokens in proportion of their Dao share. For the PM contractor, this function gives to DAO share holders Pass reputation tokens which will be used by the couriers as currency for deposits when taking parcels. 

- Set a funding proposal: the dao sharehoders can propose to fund the Dao with a public or private funding. In case of private funding, the funding rules can be set in a separated smart contract and the funding can be linked to a contractor proposal that will be executed if the funding is fueled. We use this method for the primary funding with a funding smart contract linked to the first project manager proposal.

- Set a Dao Rules proposal: the dao share holders can propose to change the minimum quorum for proposals, the board meeting fees, the period before the board meeting to set or consider a proposal, the minimum debate period and the date when shares can be transfered.

- Approve a proposal: share holders can vote for or against a proposal. If the quorum is more than 20% (minimal quorum can be updated by voting) and the positive votes are more than 50%, the proposal is approved and can be completed. 

=

## The Account Manager Smart Contract

The smart contract derives to the token contract Token.sol and is used for the management of tokens by the client smart contract (the dao). The smart contract is conform to ERC20. The Dao Account Manager contains the Eth balance of the Dao. An account manager smart contract is also created for each contractor without any Eth balance.

Main functions are : 

- Fallback function to send Eth to the Dao account manager 

- BuyToken and BuyTokenFor to buy shares in case of public fundings

- RewardToken to voters by the Dao smart contract or to funders for private fundings by the funding smart contract

- Transfer and TransferFrom for the transfer of tokens

- Approve tokens allowance by a token owner to a spender third party. 

=

## The Funding Smart Contract

Smart contract used for the primary funding of the Dao and which is linked to the first Project Manager proposal. Each partner has to send an Eth address to be included in the mailing list and become a shareholder of the Dao. All Eth addresses can refund for the amount sent and not funded. 

Main functions: 

- Fallback function to send Eth to the Funding smart contract.

- SetPartners: allows the smart contract creator to validate Eth account addresses according to the mailing list.

- SetLimits and SetFundingLimits: allows the smart contract creator to set the funding limits (amounts and percentage of ether balance share) for all partners.

- FundDaoFor: to send Eth from the Funding smart contract to the Dao according to the set limits (if the funding is fueled).

- Refund: to refund the amount that did not fund the Dao.

=

# Notes

- This Dao is for Ethereum Blockchain (ETH) only and is not foreseen to run on "Ethereum Classic" Blockchain (ETC).

- We limit the amount to send to the funding smart contract and if fueled we limit the amount to fund to the Dao for each partner. Our first goal is decentralization and we want everyone to be able to become a share holder.

- Prepayments to the contractors are done with ethers and step by step for each contractor. Each new step starts with a new contractor proposal which includes a report about the result of the last proposal.  

- It is possible to link a funding proposal with a contractor proposal and that will be completed only if the funding is fueled during a predefined period, otherwise the Dao is not funded and the contractor proposal not completed. We use this method for the first Project Manager proposal and the primary funding. For the next steps of the project, we can proceed in the same way and with no ether balance in the Dao after the funding.

- If the work of a contractor allows the development of our project, it should increase the value of Pass reputation tokens which belongs to the Community. In this case, there is no need for shareholders to report any revenue from the contractor. 

- Make a proposal will cost board meeting fees. In case of funding or Dao rules proposals, the fees return to the creator of the proposal if the quorum is reached. 

- The shareholders should vote on contractor proposals as it's the only way to receive board meeting fees and contractor tokens. 

- A period to consider or set the proposal is foreseen before each board meeting. 

- The contractor proposal can foresee an inflation rate for the reward of contractor tokens to voters which will incentivize shareholders to vote early.

- After a vote, the share holders are not able to transfer tokens until the end of the board meeting. 

=

# About Security

- It is necessary to be included in the mailing list in order to participate in the first funding. It will help communicating with shareholders, avoid the possibility to fund using "hundreds" addresses and allow to check that partners's addresses are not related to a smart contract. 

- Refund from the funding smart contract will be before the closing time of the primary funding for the valid adresses and after the closing time of the primary funding for the invalid adresses.

- By allowing fundings (public or private) for each step of the project and by limiting the funding amounts, we limit the amount of money "at risk" and avoid useless blocked ethers in the Dao.

- Only the Dao shareholders can decide by vote to allow the transfer of shares.

- There is no calldata function.  We use a “withdraw” pattern instead of a “send” pattern for the reward of board meeting fees to share holders.

- In case of bugs or improvements, we can make a proposal to send the Dao balance (if not null) to a contract that will "transfer" the balance and shares (technically creating new shares) to a new Dao account manager and with a new Dao smart contract as client.
