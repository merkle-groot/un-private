// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Counter.sol";
import "./Helper/VRFCoordinatorV2Mock.sol";
import "./Helper/LinkToken.sol";


contract CounterTest is Test {
    uint96 public BASE_FEE = 100000000000000000;
    uint96 public LINK_AMOUNT = 1000000000000000000;
    uint96 public GAS_PRICE_LINK = 10000000000;
    // Counter public counter;
    VRFCoordinatorV2Mock public vrf;
    LinkToken public link;


    function setUp() public {
        vrf = new VRFCoordinatorV2Mock(BASE_FEE, GAS_PRICE_LINK);
        link = new LinkToken(,LINK_AMOUNT);
        // counter.setNumber(0);
    }

    function test_init() public {
        uint64 res = vrf.createSubscription();
        console.log("works", res);
    }

    // function testIncrement() public {
    //     counter.increment();
    //     assertEq(counter.number(), 1);
    // }

    // function testSetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}
