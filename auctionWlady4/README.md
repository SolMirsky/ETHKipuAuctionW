🏆 Simple Solidity Auction Contract
This repository contains a Solidity smart contract for a basic, single-use auction. It allows participants to place bids, with a minimum increment, and includes features for partial withdrawals and auction extension. The auction is finalized by the contract owner, who collects the winning bid (minus a commission), while non-winning bidders can reclaim their deposits.

✨ Features
Fixed-Time Auction: Configurable duration at deployment.
Minimum Bid Increment: New bids must be at least 5% higher than the current highestBid.
Auction Extension: If a bid is placed in the last 10 minutes, the auction automatically extends by 10 minutes.
Partial Withdrawal: Bidders can withdraw any funds they've deposited that exceed their current lastBids amount during the active auction.
Auction Finalization: The endAuction() function can be called by anyone once the auction time expires, marking the auction as ended.
Deposit Reclamation (returnDeposits):
Only the contract owner can call this function after the auction ends.
It transfers the highestBid amount (minus a 2% owner commission) to the owner.
It refunds the full deposits of all non-winning bidders.
Transparency: Events are emitted for new bids, auction extensions, partial withdrawals, and when funds are transferred, making activity traceable on the blockchain.
🚀 Getting Started
To interact with this contract, you'll need:

MetaMask: A browser extension wallet for Ethereum.
Sepolia Testnet ETH: You can get test ETH from a Sepolia faucet (e.g., sepoliafaucet.com).
Remix IDE: The recommended online Solidity IDE (remix.ethereum.org).
🛠️ Deployment
Open in Remix: Copy the Auction.sol code into a new file in Remix.
Compile: Go to the "Solidity Compiler" tab in Remix. Select a compiler version compatible with ^0.8.20 (e.g., 0.8.20). Click "Compile Auction.sol".
Deploy:
Go to the "Deploy & Run Transactions" tab.
In the "Environment" dropdown, select "Injected Provider - MetaMask".
Ensure your MetaMask is connected to the Sepolia Test Network.
In the "Deploy" section, find your Auction contract. Next to the "Deploy" button, you'll see a field for the constructor argument _durationInMinutes. Enter your desired auction duration in minutes (e.g., 30 for 30 minutes).
Click "Deploy". Confirm the transaction in MetaMask.
Verify (Recommended): Once deployed, copy your contract's address from Remix. Go to Sepolia Etherscan, search for your contract address, and use the "Verify and Publish" feature to make your code publicly visible and verifiable.
🤝 Interaction
After deployment, you can interact with your contract instance directly from Remix or Sepolia Etherscan (if verified):

Using Remix
In the "Deploy & Run Transactions" tab, ensure "Injected Provider - MetaMask" is still selected.
In the "At Address" field (below the "Deploy" section), paste your deployed contract's address and click "At Address".
Your contract will appear under "Deployed Contracts", allowing you to call its functions.
Using Etherscan
Go to Sepolia Etherscan and search for your contract's address.
Navigate to the "Contract" tab, then the "Write Contract" sub-tab.
Click "Connect to Web3" to connect your MetaMask wallet.
You can now call the contract's payable functions (like bid(), partialWithdrawal(), endAuction(), returnDeposits()) and view public state variables/functions (like highestBid, auctionEndTime, showWinner()).
⚠️ Security Notes
This contract is a basic implementation for learning purposes. It has not undergone a formal security audit.
Reentrancy protection is used for Ether transfers (.call{value: ...}("") with Checks-Effects-Interactions pattern).
The endAuction() function can be called by anyone once the auction time has elapsed. This is a common pattern to allow gas payment by any user to finalize the auction, but ensure you're aware of this.
returnDeposits() is restricted to onlyOwner to manage final fund distribution.
📄 License
This project is licensed under the MIT License. See the SPDX-License-Identifier in the contract code.

✍️ Author
Sol Wlady