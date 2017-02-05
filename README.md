# The PASS DAPP (Decentralized Application)


Website : http://forum.passdao.org/

=

The source includes the next smart contracts :


#### PASS DAO Smart Contract
Used for the management and display of the upgrades from the beginning of the application. No public function.


#### PASS Project Smart Contracts
Used for the management and display of the PASS projects. One project smart contract for each project. No public function.


#### PASS Contractor Smart Contracts
Used by the project managers and contractors of the application. One smart contract for each project manager or contractor.

Public functions are : 

- Update Project Description (for the project manager).

- Update recipient and withdraw: allows the contractors using their smart contract as an account manager with deposits and withdrawals.

- Set a new proposal: every contractor can offer to sell products or execute services. Payments to the contractors are done with ethers and step by step. For each step, the shareholders decide by voting to continue or to stop ordering work from the contractor.  


#### PASS Manager Smart Contracts
Used for the management of tokens. Includes the PASS token Manager smart contract. One smart contract for the DAO shares and one smart contract for the PASS tokens. The smart contracts are conform to ERC20.

Public functions are : 

- Buy Tokens, Sell Tokens and Remove buy orders: allows to buy and sell transferable tokens using the application.

- Buy tokens for a proposal: allows to buy tokens in order to pay a project manager (or contractor if shares) according to an approved proposal.

- Transfer tokens and Approve tokens allowance: ERC20 functions.



#### PASS Committee Room Smart Contract
Used to submit proposals, to vote and to execute the decisions of the shareholders.

Public functions are :

- Proposal to be a project manager or a contractor

- Proposal to order a work from a project manager or a contractor and/or to fund the Dao

- Submit a question to a vote by the Community of shareholders

- Proposal to change the rules of the committee room

- Proposal to upgrade the Committee Room or the manager smart contracts

- Vote (for shareholders)

- Execute decision and order a work from a contractor (after and according to the votes of a committee)

=

## Notes

- This Dapp is for Ethereum Blockchain (ETH) only and is not foreseen to run on "Ethereum Classic" Blockchain (ETC).

- The creators of proposals have to pay committee fees. If the proposal is estimated (and not necessarily approved), the creator of the proposal receives shares with an amount equal to the fees.

- The shareholders should vote on contractor proposals as it's the only way to receive committee fees. 

- By allowing fundings step by step and by limiting the funding amounts, we limit the amount of money "at risk" and avoid useless blocked ethers in the Dao.

- The creation of new shares is decided by the shareholders and can be limited using a moderator smart contract. Only the Dao shareholders can decide by vote to allow the transfer of shares.
