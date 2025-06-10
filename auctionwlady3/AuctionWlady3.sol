// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Auction {
    // --- State Variables ---

    // Owner and auction timing
    address public owner;
    uint256 public auctionStartTime;
    uint256 public auctionEndTime;

    // Auction status and winning bid
    uint256 public highestBid;
    address public highestBidder;
    bool public ended;

    // Constants for auction rules
    uint256 public constant EXTENSION_TIME = 10 minutes;
    uint256 public constant MIN_BID_INCREMENT_PERCENT = 5;
    uint256 public constant GAS_COMMISSION_PERCENT = 2; // 2% commission for gas

    // Mappings for bids and deposits
    mapping(address => uint256) public deposits; // Total deposited by each participant
    mapping(address => Bid) public lastBids;     // Last valid bid for each participant

    // Structure to store details of each valid bid
    struct Bid {
        address bidder;
        uint256 amount;
    }

    // List of all addresses that have bid, for `showBids`
    address[] public allBidders;
    // Auxiliary mapping to quickly check if a bidder is already in `allBidders`
    mapping(address => bool) private hasBidder;

    // --- Events ---
    event NewBid(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 winningBid);
    event DepositRefunded(address indexed beneficiary, uint256 amount);
    event PartialWithdrawal(address indexed bidder, uint256 amount);
    event AuctionExtended(uint256 newEndTime);

    // --- Constructor ---
    /// @dev Initializes the auction with the necessary parameters.
    /// @param _durationInMinutes The duration of the auction in minutes.
    constructor(uint256 _durationInMinutes) {
        owner = msg.sender;
        auctionStartTime = block.timestamp;
        auctionEndTime = block.timestamp + (_durationInMinutes * 1 minutes);
        highestBid = 0;
        highestBidder = address(0);
        ended = false;
    }

    // --- Modifiers ---

    /// @dev Restricts access to functions to the contract owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner.");
        _;
    }

    /// @dev Restricts access to functions only if the auction is active.
    modifier auctionActive() {
        require(block.timestamp < auctionEndTime && !ended, "Auction inactive.");
        _;
    }

    /// @dev Restricts access to functions only if the auction has ended.
    modifier auctionEnded() {
        require(block.timestamp >= auctionEndTime || ended, "Auction not ended.");
        _;
    }

    // --- Functions ---

    /// @dev Allows a participant to place a bid.
    /// The Ether amount is sent with the transaction (msg.value).
    /// A bid must be at least 5% higher than the current highest bid.
    /// Extends the auction deadline if the bid is placed in the last 10 minutes.
    function bid() public payable auctionActive {
        uint256 requiredMinBid = highestBid + (highestBid * MIN_BID_INCREMENT_PERCENT / 100);
        if (highestBid == 0) {
            requiredMinBid = 1 wei; // First bid must be at least 1 wei
        }

        require(msg.value >= requiredMinBid, "Bid too low.");

        // Add to allBidders using the hasBidder mapping
        if (!hasBidder[msg.sender]) {
            hasBidder[msg.sender] = true;
            allBidders.push(msg.sender);
        }

        deposits[msg.sender] += msg.value;

        if (msg.value > highestBid) {
            highestBid = msg.value;
            highestBidder = msg.sender;
        }

        // Store the current bid value as the last valid bid for this sender
        lastBids[msg.sender] = Bid(msg.sender, msg.value);

        emit NewBid(msg.sender, msg.value);

        if (auctionEndTime - block.timestamp <= EXTENSION_TIME && block.timestamp < auctionEndTime) {
            auctionEndTime += EXTENSION_TIME;
            emit AuctionExtended(auctionEndTime);
        }
    }

    /// @dev Marks the auction as ended if the time has expired.
    /// Anyone can call this function to end the auction.
    function endAuction() public {
        require(block.timestamp >= auctionEndTime && !ended, "Cannot end auction.");
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
    }

    /// @dev Shows the address of the winning bidder and the winning bid amount.
    /// Can only be called once the auction has ended.
    /// @return winner The address of the winning bidder.
    /// @return winningBid The amount of the winning bid.
    function showWinner() public view auctionEnded returns (address winner, uint256 winningBid) {
        return (highestBidder, highestBid);
    }

    /// @dev Shows the list of bidders and their respective last offered amounts.
    /// @return bidders Array of bidder addresses.
    /// @return amounts Array of the last offered amounts by each bidder.
    function showBids() public view returns (address[] memory bidders, uint256[] memory amounts) {
        uint256 len = allBidders.length; // Optimization: store length in a local variable
        bidders = new address[](len);
        amounts = new uint256[](len);

        address currentBidder; // Optimization: declare outside the loop
        for (uint i = 0; i < len; i++) {
            currentBidder = allBidders[i];
            bidders[i] = currentBidder;
            amounts[i] = lastBids[currentBidder].amount;
        }
        return (bidders, amounts);
    }

    /// @dev Allows non-winning bidders to reclaim their deposited Ether,
    /// after deducting a 2% commission. Only the owner can call this function
    /// to process refunds for all non-winning bidders.
    function returnDeposits() public onlyOwner auctionEnded {
        for (uint i = 0; i < allBidders.length; i++) {
            address currentBidder = allBidders[i];

            // Skip the winner or bidders with no deposits
            if (currentBidder == highestBidder || deposits[currentBidder] == 0) {
                continue;
            }

            uint256 amountToRefund = deposits[currentBidder];
            uint256 commission = (amountToRefund * GAS_COMMISSION_PERCENT) / 100;
            uint256 netRefund = amountToRefund - commission;

            // Reset the user's deposit to zero before the transfer to prevent reentrancy
            deposits[currentBidder] = 0;

            // Transfer the Ether back to the bidder
            (bool success, ) = payable(currentBidder).call{value: netRefund}("");
            require(success, "Refund failed.");

            emit DepositRefunded(currentBidder, netRefund);
        }
    }


    /// @dev Allows participants to withdraw the amount exceeding their last valid bid during the auction.
    /// Can only be called while the auction is active.
    function partialWithdrawal() public auctionActive {
        // The total amount the user has deposited.
        uint256 currentDeposit = deposits[msg.sender];
        // The amount of their last valid bid.
        uint256 lastBidAmount = lastBids[msg.sender].amount;

        // If the deposit is less than or equal to their last bid, there's nothing to partially withdraw.
        require(currentDeposit > lastBidAmount, "No excess deposit.");

        // Calculate the amount to withdraw (total deposit - last bid).
        uint256 amountToWithdraw = currentDeposit - lastBidAmount;

        // Reset the user's deposit BEFORE the transfer to prevent reentrancy.
        // The new deposit will be equal to their last bid amount.
        deposits[msg.sender] = lastBidAmount;

        // Perform the transfer of the excess amount.
        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Partial withdrawal failed.");

        emit PartialWithdrawal(msg.sender, amountToWithdraw);
    }
}