//Withdraw funds
//Set a minimum funding value in USD

// SPDX-License-Identifier:MIT

pragma solidity >0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
// import {MathLibrary} from "./MathLibrary.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe_NotOwner();

// error WhereAddress();

contract FundMe {
    using PriceConverter for uint256;
    // using MathLibrary for uint256;
    // uint256[] public numbers;
    uint256 public constant MINIMUM_USD = 2e18;
    address[] private s_funders;
    // address public owner = msg.sender;
    address private immutable i_owner;
    // uint256 public startTime;
    // address public firstAccount;
    // bool public isFirstAccountSet= false;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
        // startTime=block.timestamp;
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) > MINIMUM_USD,
            "bye bye"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function getVersion() public view returns (uint256) {
        return AggregatorV3Interface(s_priceFeed).version();
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        // payable(msg.sender).transfer(address(this).balance); //transfer function

        // bool success= payable(msg.sender).send(address(this).balance); //send function
        // require(success,"Failed");

        (bool finish, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); // call function
        require(finish, "failed");
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // function withdrawOnlyFirstAccountRemix() public{
    //   require(!isFirstAccountSet,"already set");
    //   firstAccount=msg.sender;
    //   isFirstAccountSet=true;

    // }

    // function callAmountTo() public{
    //   (bool success,)= payable(msg.sender).call{value: address(0x9D91f92cE2D12EE093ba95b9D4427fc3D6356257).balance}("");
    //   require(success, "failed");

    // }

    // function expensiveReset() public{
    //   for(uint256 funderIndex=0; funderIndex<funders.length; funderIndex++){
    //     funders[funderIndex]=address(0);
    //   }
    // }

    // function pushNumbers() public onlyAfter{
    //   for (uint256 numberIndex=1; numberIndex<=10; numberIndex++)
    //   {
    //    numbers.push(numberIndex);
    //   }
    // }

    // modifier onlyAfter{
    //   require(block.timestamp>= 12332423534534534,"Not time yet");
    //   _;
    // }

    // modifier AddressZero(){
    //   if(msg.sender == address(0)){
    //     revert WhereAddress();
    //   }
    //   _;
    // }

    modifier onlyOwner() {
        // require(msg.sender==i_owner,"not owner");
        if (msg.sender != i_owner) {
            revert FundMe_NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    //Getter function

    function getAddressToAmountFunded(
        address fundingAddress
    ) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
