# Our Decentralized Autonomous Organization

=

## The Project : A PEER-TO-PEER C2C TRANSPORTATION SYSTEM OF OBJECTS

Website : http://pacifics.org/dao

=

## Overview
Pass DAO is open source and used for the project to put together a transparent organization where governance and decision making system are immutably programmed in the Blockchain. The source includes three separated smart contracts : the manager smart contract for the management of Eth accounts and shares or tokens, the Dao smart contract to make decision on proposals and the Funding smart contract to fund the Dao.

=

## Bug Bounty Program

In case of bug, we will send up to 500 eth (serious security bug) to the first who found it. Start date : 16 november 2016.

=

## The Manager Smart Contract

The Dao Manager smart contract contains the Eth balance of the Dao. A manager smart contract is also created for each contractor with proposals to work for the Dao and orders from the Dao. The smart contract derives to the Token Manager smart contract used for the management of Dao shares or contractor tokens. The smart contract is conform to ERC20.

External functions are : 

- Fallback payable function: allows to send Eth to the manager smart contract.

- Update recipient: allows the contractor to update the address for the withdrawal of ethers fom the manager contract.

- BuyShares and BuySharesFor in case of public fundings without funding smart contract.

- Set a new proposal: every contractor can offer his client (the DAO) to sell products or execute services. The proposal contains a description, a hash of document and the amount of the proposal. 

- Order and sendTo for the order and payment of ethers to the contractor manager by the Dao manager according to a proposal.

- Withdraw function: allows the contractors to withdraw the amounts sent by the Dao manager.

- SetTokenPriceProposal: allows the contractors to propose a token price for the creation of contractor tokens.

- SetFundingRules according to funding proposals approved by the Dao.

- RewardToken to funders by the funding smart contract.

- Transfer and TransferFrom for the transfer of tokens or shares.

- Approve tokens allowance by a token owner to a spender third party. 

=

## The Dao Smart Contract

Proposals can be to fund the Dao, to change the Dao rules or to send Eth to a contractor. For each proposal, shareholders vote after a set period and during a debate period called board meeting. To make a new proposal and organize a board meeting will cost minimum 10 ethers (to avoid useless proposals, minimum value can be updated by voting). For the contractor proposals, the fees go to the voters according to their share and how quickly they vote after the set period. For the funding and Dao rules proposal, the Dao gives back the fees to the creator of the proposal if the quorum is reached. The balance of fees goes to the Dao manager smart contract.

External functions are :

- Set a contractor or funding proposal: the dao sharehoders can propose to order a work of a contractor (defined in a proposal of the contractor manager) or/and to fund the Dao with a public or private funding. The proposal can foresee the payment of funded ethers to a contractor. The funding rules can be set in a separated smart contract and foresee to reward contractor tokens to funders. We use this method for the primary funding that gives to new DAO share holders Pass reputation tokens.

- Set a Dao Rules proposal: the dao share holders can propose to change the minimum quorum for proposals, the board meeting fees, the period before the board meeting to set or consider a proposal, the minimum debate period, the inflation rate for the reward of fees to voters during board meetings and the date when shares can be transfered.

- Vote for or against a proposal: If the quorum is more than 20% (minimal quorum can be updated by voting) and the positive votes are more than 50%, the proposal is approved and can be completed. 

- Order a contractor proposal: In case of funding proposal linked to a contractor proposal, the amount sent to the contrator management corresponds to the funded amount. Otherwise, the amount sent is the amount of the proposal.

- Withdraw function: allows the share holders to withdraw the board meeting fees sent by the creators of the proposals.

=

## The Funding Smart Contract

Smart contract used for the primary funding of the Dao. Each partner who sent his Eth account address by email (for communication and security purposes) can become a shareholder of the Dao. All Eth addresses can refund for the amount sent and not funded. After the primary funding, the smart contract will allow others fundings with for instance Priority Subscription Rights for share holders. The smart contract also foresees a preliminary step for the setting before the voting procedure of the corresponding funding proposal in the Dao. This will allow the share holders to approve a set private funding without allowing the creator of the funding to change  anything.

External functions are :

- SetContractorManager: allows to reward contractor tokens when funding the Dao.

- SetPresaleAmountLimits: allows the smart contract creator to set the presale limits (minimum and maximum).

- Fallback and Presale function to send Eth to the Funding smart contract.

- SetPartners: allows the smart contract creator to set Eth account addresses.

- SetShareHolders: allows organizing a private funding for the share holders.

- AbortFunding: allows the smart contract creator to abort the funding before the closing time.

- Pause: allows the smart contract creator to stop the presale without aborting the funding.

- SetLimits: allows the smart contract creator to set the funding limits for all partners.

- SetFunding : sets the amounts to fund for each partner according to the presale amounts, the set limits and the funding amount of the approved Dao funding proposal.

- FundDaoFor: to send Eth from the Funding smart contract.

- RefundForValidPartners and RefundForAll: to refund the amount that did not fund the Dao (priority to the valid addresses).

- AbortFunding: allows the smart contract creator to abort the funding and refund at any time during the presale.

=

# Notes

- This Dao is for Ethereum Blockchain (ETH) only and is not foreseen to run on "Ethereum Classic" Blockchain (ETC).

- We limit the amount to send to the funding smart contract and if fueled we limit the amount to fund to the Dao for each partner. Our first goal is decentralization and we want everyone to be able to become a share holder.

- Payments to the contractors are done with ethers and step by step. Each contractor proposal can contains serveral orders from the Dao if the total ordered amount is less than the amount of the proposal.

- It is possible to link a funding proposal with a contractor proposal and that will be completed only if the funding is fueled during a predefined period, otherwise the Dao is not funded and the contractor proposal not completed. We use this method for the first Project Manager proposal and the primary funding. For the next steps of the project, we can proceed in the same way and with no ether balance in the Dao after the funding.

- If the work of a contractor allows the development of our project, it should increase the value of Pass reputation tokens which belongs to the Community. In this case, there is no need for shareholders to report any revenue from the contractor. 

- Make a proposal will cost board meeting fees. In case of funding or Dao rules proposals, the fees return to the creator of the proposal if the quorum is reached. 

- The shareholders should vote on contractor proposals as it's the only way to receive board meeting fees. 

- A period to consider or set the proposal is foreseen before each board meeting.

- After a vote, the share holders are not able to transfer tokens until the end of the board meeting. 

=

# About Security

- It is necessary to be included in the mailing list in order to participate in the first funding. It will avoid the possibility to fund using "hundreds" addresses and allow to check that partners's addresses are not related to a smart contract. 

- By allowing fundings (public or private) for each step of the project and by limiting the presale and funding amounts, we limit the amount of money "at risk" and avoid useless blocked ethers in the Dao.

- In case of any bug or exploit during the primary funding, the project manager (who is confident in the security of the smart contract) promises to do his best to complete the work foreseen in his proposal without asking for additional funds. He can also abort the funding and refund before the closing time of the funding.

- Only the Dao shareholders can decide by vote to allow the transfer of shares.

- There is no calldata function.  We use a “withdraw” pattern instead of a “send” pattern.

=

# Upgrading Procedure

In case of bugs or improvements, the funding smart contract can be updated and called in new Dao proposals. Share holders can also make a contractor proposal to send the Dao balance to a new smart contract. This will "transfer" the Dao balance, shares and reputation tokens (technically creating new shares and tokens) to new manager smart contracts and with a new Dao smart contract as client.
