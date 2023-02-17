// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {VRFConsumerBase} from "chainlink/v0.8/dev/VRFConsumerBase.sol";

contract Lotto is VRFConsumerBase{
    struct LotteryTicket {
        uint256 series;
        uint256 ticketNumber;
    }
    uint256 lastTimestamp;
    uint256 state;
    uint256 currentEpoch;
    uint256 noOfTicketsBought;
    address immutable owner;
    uint256 constant noOfSeries = 5;
    uint256 immutable noOfTicketsPerSeries = 2000;
    address immutable token;
    uint256 immutable ticketCost;
    mapping(uint256 => mapping(uint256 => address))
        public lotteryTicketToHolder;
    mapping(address => LotteryTicket) public holderToLotteryTicket;
    mapping(uint256 => uint256) public epochToPrizePool;
    mapping(uint256 => LotteryTicket) public drawnNumbers;

    constructor(address token_, uint256 ticketCost_) {
        lastTimestamp = block.timestamp;
        owner = msg.sender;
        token = token_;
        ticketCost = ticketCost_;
    }

    function buyTicket(uint256 series_, uint256 ticketNumber_) external {
        require(state == 0, "Invalid state");
        require(series_ < noOfSeries || series_ != 0, "Invalid series");
        require(
            ticketNumber_ < noOfTicketsPerSeries || ticketNumber_ != 0,
            "Invalid ticket number"
        );
        require(
            lotteryTicketToHolder[series_][ticketNumber_] == address(0) ||
                holderToLotteryTicket[msg.sender].ticketNumber == 0,
            "Ticket already bought"
        );

        IERC20(token).transferFrom(msg.sender, address(this), ticketCost);

        lotteryTicketToHolder[series_][ticketNumber_] == msg.sender;
    }

    function transitionToCashOutPeriod() external {
        require(state == 0 && block.timestamp >= lastTimestamp + 7 days);
        // increment state
        state++;
        lastTimestamp = block.timestamp;

        // find the winner

        epochToPrizePool[currentEpoch] = IERC20(token).balanceOf(address(this));
    }

    function transitionToBuyPeriod() external {
        require(state == 1 && block.timestamp >= lastTimestamp + 2 days);
        // increment state
        state = 0;
        lastTimestamp = block.timestamp;
        currentEpoch++;
    }

    function cashOut(uint256 series) external {
        // Get the winning ticket and user ticket of the current epoch
        LotteryTicket memory seriesWinner = drawnNumbers[series];
        LotteryTicket storage userTicket = holderToLotteryTicket[msg.sender];
        require(state == 1, "Invalid state");
        require(seriesWinner.ticketNumber != 0, "Winner not drawn yet");
        require(userTicket.ticketNumber != 0, "User doesn't hold a ticket");

        uint256 totalPrizePool = epochToPrizePool[currentEpoch];
        uint256 userPayout = 0;
        uint256 ownerPayout = 0;
        if (seriesWinner.ticketNumber == userTicket.ticketNumber) {
            if (seriesWinner.series == userTicket.series) {
                // If the tickets match fully
                state = 2;
                // Give user 60% of the pool
                userPayout = (totalPrizePool * 60) / 100;
                // Give the owner 5% of the pool
                ownerPayout = (totalPrizePool * 5) / 100;
            } else {
                // If the last four numbers match
                // Give user 3% of the pool
                userPayout = (totalPrizePool * 3) / 100;
            }
        } else if (
            seriesWinner.ticketNumber % 1000 == userTicket.ticketNumber % 1000
        ) {
            // If the last three numbers match
            // Give user 1% of the pool
            userPayout = (totalPrizePool * 1) / 100;
        } else {
            // If no numbers match
            return;
        }
        IERC20(token).transfer(msg.sender, userPayout);

        if (ownerPayout != 0) {
            IERC20(token).transfer(owner, ownerPayout);
        }

        lotteryTicketToHolder[userTicket.series][
            userTicket.ticketNumber
        ] = address(0);

        userTicket.series = 0;
        userTicket.ticketNumber = 0;
    }
}
