//SPDX-License-Identifier: MIT

pragma solidity >0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    // uint number = 1;
    FundMe fundMe;
    address curious = makeAddr("curious");
    uint256 FUNDED_AMOUNT = 1 ether;
    uint256 INITIAL_BALANCE = 100 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        // console.log(number);
        // number = 4;
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    function testMinimumUsd() public view {
        assertEq(fundMe.MINIMUM_USD(), 2e18);
        // console.log("curious");
        // assertEq(number, 4);
    }

    function testOwner() public view {
        assertEq(fundMe.getOwner(), msg.sender);
        console.log(fundMe.getOwner());
        console.log(msg.sender);
    }

    function testPriceFeed() public view {
        assertEq(fundMe.getVersion(), 4);
    }

    //here we are sending 0 eth, so we are checking to see if the contract is accepting anything less that $2 or not
    function testEnoughEthSent() public {
        vm.expectRevert();
        fundMe.fund();
    }

    //Here we are using curious to fund the contract and checking if its done correctly, also remember why "funded" is here
    //Hint: its a modifier
    function testFundUpdate() public funded {
        fundMe.fund{value: FUNDED_AMOUNT}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(curious);
        assertEq(amountFunded, FUNDED_AMOUNT);
    }

    //Here, we check to see if the address are being updated in the Array of addresses who have contributed to the contract.
    function testAddsFunderToArrayOfFunders() public funded {
        fundMe.fund{value: FUNDED_AMOUNT}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, curious);
    }

    //In this function, we are using "curious" address to call this transaction, so it should fail
    //vm.revert passes when its following transaction actually reverts.
    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();
    }

    // AAA methodology
    function testWithdrawFromASingleFunder() public funded {
        //Arrange: Initiliaze necessary variables, preconditions.
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.txGasPrice(GAS_PRICE);
        uint256 gasStart = gasleft();
        //Act: Performt tests
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Consumed gas: %d gas", gasUsed);
        //Assert: Checking to see if we get what we are looking for or not
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            hoax(address(i), INITIAL_BALANCE); //hoax is vm.deal and vm.prank combined
            fundMe.fund{value: FUNDED_AMOUNT}();
        }
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        //Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
        assert(
            (numberOfFunders + 1) * FUNDED_AMOUNT ==
                fundMe.getOwner().balance - startingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            hoax(address(i), INITIAL_BALANCE); //hoax is vm.deal and vm.prank combined
            fundMe.fund{value: FUNDED_AMOUNT}();
        }
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();
        //Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
        assert(
            (numberOfFunders + 1) * FUNDED_AMOUNT ==
                fundMe.getOwner().balance - startingOwnerBalance
        );
    }

    function testPrintStorageData() public view {
        for (uint256 i = 0; i < 3; i++) {
            bytes32 value = vm.load(address(fundMe), bytes32(i));
            console.log("Value at location", i, ":");
            console.logBytes32(value);
        }
        console.log("PriceFeed address:", address(fundMe.getPriceFeed()));
    }

    //we use modifier here to make our function clear, as we have to reuse these codes several times.
    modifier funded() {
        vm.prank(curious);
        vm.deal(curious, INITIAL_BALANCE);
        fundMe.fund{value: FUNDED_AMOUNT}();
        assert(address(fundMe).balance > 0);
        _;
    }
}
