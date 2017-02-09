# The PASS Distributed Application


Website : http://forum.passdao.org/

=

The source includes the next smart contracts :


#### Dao and Project Smart Contract ("DappScan")
Used for the management and display of the upgrades and projects from the beginning of the application. One Pass DAO smart contract, a meta project for the DAO and a project smart contract for each project. No public function.


#### Committee Room Smart Contract ("Committees")
Used to submit proposals, to vote and to execute the decisions of the shareholders.

Public functions are :

- Create Contractor: allows creating a project manager or a contractor smart contract. Inputs: the contractor creator smart contract (a verified: 0xf03262DCE825ACd93d0630d3e6aE495B7d907890), the recipient of the amount received from the DAO, the project (meta project if no secific project, the name and a description of the project if new project). Note: for new projects, the contractor will be the project manager of the created project.

- Contractor Proposal: proposal to order a work from a project manager or a contractor or to fund the Dao. Inputs: the amount of the proposal in wei, the address of the contractor smart contract (0 if proposal to fund the DAO), the proposal (the index in the contractor smart contract or a description and a hash of the proposal document), the funding rules (not mandatory), the debating period (not mandatory).

- Resolution Proposal: submit a question to a vote by the Community of shareholders. Inputs: the name of the question, a description, the address of the project, the debating period (not mandatory). 

- Rules Proposal: proposal to change the rules of the committee room. Inputs: the min quorum for proposals, the minimum amount in wei of committee fees, the percentage of positive votes to reward shares to the creator of the proposal, the period before committees, the minimum debate period, the inflation rate for the rewarding of fees to voters, the token price inflation rate and the default funding period.

- Upgrade Proposal: proposal to upgrade the Committee Room or the manager smart contracts. Inputs: the new Committee Room smart contract (not mandatory), the new share manager smart contract (not mandatory) or the new token manager smart contract (not mandatory).

- Vote (for shareholders): support or vote against a proposal. Inputs: the index of the proposal, true if support and false against.

- Execute decision (after and according to the votes of a committee, input: the index of the committee) and order a work from a contractor (after the closing time of the funding for the proposal, input: the index of the proposal).


#### Manager Smart Contracts ("Tokens")
Used for the management of tokens. Includes the PASS token Manager smart contract. One smart contract for the DAO shares and one smart contract for the PASS tokens. The smart contracts are conform to ERC20.

Public functions are : 

- Buy tokens for a proposal: allows to buy tokens in order to pay a project manager (or contractor if shares) according to an approved proposal. Inputs : the index of the proposal and the address of the buyer (default: msg.sender).

- Withdraw pending amounts: allows receiving tokens or refunding after the closing time of the fundings.

- Buy Tokens: allows sending a buy order.

- Remove orders: allow removing buy orders and refunding. Input: from an order to another order (default: all orders).

- Sell Tokens: allows selling tokens from the buy orders. Inputs: the amount in token you want to sell, from an order to another order (default: all orders).

- Transfer tokens and Approve tokens allowance: ERC20 functions.


#### PASS Contractor Smart Contracts
Used by the project managers and contractors of the application. One smart contract for each project manager or contractor.

Public functions are : 

- Update Project Description (for the project manager).

- Update recipient and withdraw: allows the contractors using their smart contract as an account manager with deposits and withdrawals.

- Set a new proposal: every contractor can offer to sell products or execute services. Payments to the contractors are done with ethers and step by step. For each step, the shareholders decide by voting to continue or to stop ordering work from the contractor.  

=

## Notes

- This Dapp is for Ethereum Blockchain (ETH) only and is not foreseen to run on "Ethereum Classic" Blockchain (ETC).

- The creators of proposals have to pay committee fees. If the proposal is estimated (and not necessarily approved), the creator of the proposal receives shares with an amount equal to the fees.

- The shareholders should vote on contractor proposals as it's the only way to receive committee fees. 

- By allowing fundings step by step and by limiting the funding amounts, we limit the amount of money "at risk" and avoid useless blocked ethers in the Dao.

- The creation of new shares is decided by the shareholders and can be limited using a moderator smart contract. 
