// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; // 5 USD in ETH
    uint256 constant STARTING_BALANCE = 10 ether; // Starting balance for the user
    //uint256 constant GAS_PRICE = 1; // Set a gas price for the transaction

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5 * 10 ** 18, "Minimum USD should be 5 ETH");
    }

    function testOwnerIsMsgSender() public view {
        
        assertEq(fundMe.getOwner(), msg.sender, "Owner should be the message sender");
    }

    // Different types of tests
    // 1. Unit test
    //    - Test a single function in isolation
    // 2. Integration test
    //    - Test multiple functions together
    // 3. Forked test
    //    - Test against a live network (e.g., Sepolia, Mainnet)
    // 4. Staging test
    //    - Test against a live network with a specific state (e.g., after a deployment)
    //    - forge test --match-test testGetVersion -vvv --fork-url $SEPOLIA_RPC_URL
    // forge coverage --fork-url $SEPOLIA_RPC_URL tells how much of the code is covered by tests

    modifier funded() {
        vm.prank(USER); // Simulate a different user
        vm.deal(USER, SEND_VALUE);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testGetVersion() public view {
        uint256 version = fundMe.getVersion();
        //this wont work without having the chainlink contract deployed
        console.log("Chainlink Version:", version);
        assertEq(version, 4, "Chainlink version should be 4");
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert("You need to spend more ETH!");
        fundMe.fund(); // send 0 ETH
    }

    function testFundUpdatesAddressToAmountFunded() public payable funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE, "Amount funded should be updated");
    }

    function testAddsFunderToArrayOfFunders() public payable funded {
        //vm.prank(USER);
        //fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER, "Funder should be added to the array of funders");
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw(); // USER tries to withdraw
    }

    function testWithdrawAsSingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        //uint256 gasStart = gasleft();
        //vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //uint256 gasEnd = gasleft();
        //uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // Calculate gas used in wei
        //console.log("Gas used for withdrawal:", gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0, "FundMe balance should be 0 after withdrawal");
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance,
            "Owner balance should be increased by the FundMe balance"
        );
    }

    function testWithdrawWithMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10; // Number of funders to simulate
        uint160 startingFunderIndex = 1; // Start funding from index to avoid 0 address sending (contract create)
        
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i),SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0, "FundMe balance should be 0 after withdrawal");
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance,
            "Owner balance should be increased by the FundMe balance"
        );
    }

    function testWithdrawWithMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10; // Number of funders to simulate
        uint160 startingFunderIndex = 1; // Start funding from index to avoid 0 address sending (contract create)
        
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i),SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0, "FundMe balance should be 0 after withdrawal");
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance,
            "Owner balance should be increased by the FundMe balance"
        );
    }


}
