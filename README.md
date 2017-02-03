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

- Set a new proposal: every contractor can offer to sell products or execute services. Payments to the contractors are done with ethers and step by step. For each step, the PASS DAO shareholders decide to continue or to stop ordering work from the contractor.  


#### PASS Manager Smart Contract
Used for the management of tokens. One smart contract for the DAO shares and one smart contract for the PASS tokens. The smart contract is conform to ERC20.

Public functions are : 

- Buy Tokens, Sell Tokens and Remove buy orders: allows to buy and sell transferable tokens using the application.

- Buy tokens for a proposal: allows to buy tokens in order to pay a project manager according to an approved proposal.

- Transfer tokens and Approve tokens allowance: ERC20 functions.



#### PASS Committee Room Smart Contract
Used to submit proposals, to vote and to execute the decisions of the shareholders.

Public functions are :

- Proposal to create a new project and to work as a project manager of PASS DAO

- Proposal to be a contractor of PASS DAO

- Submit a Funding proposal

- Submit a question to a vote by the Community of shareholders

- Proposal to change the Dao rules

- Proposal to upgrade one or all the smart contracts (except Pass DAO which can't be updated)

- Vote (for shareholders)

- Execute decision and order a work from a contractor (after and according to the votes of a board meeting)

- Buy shares for a proposal: allows funding the DAO according to an approved funding proposal or allows buying shares in order to pay a contractor according to an approved contractor proposal.


=

## Notes

- This Dapp is for Ethereum Blockchain (ETH) only and is not foreseen to run on "Ethereum Classic" Blockchain (ETC).

- The creators of proposals have to pay board meeting fees. If the proposal is estimated (and not necessarily approved), the creator of the proposal receives shares with an amount equal to the fees.

- The shareholders should vote on contractor proposals as it's the only way to receive board meeting fees. 

- By allowing fundings (public or private) step by step and by limiting the funding amounts, we limit the amount of money "at risk" and avoid useless blocked ethers in the Dao.

- The creation of new shares is decided by the shareholders and can be limited using a moderator smart contract in prder to ensure decentralization. Only the Dao shareholders can decide by vote to allow the transfer of shares.
