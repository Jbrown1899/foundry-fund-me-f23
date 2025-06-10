// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {FundMe} from "../src/FundMe.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    FundMe public fundMe;

    function run() external returns (FundMe) {
        // Before broadcasting is not real TXN
        HelperConfig helperConfig = new HelperConfig();
        address priceFeedAddr = helperConfig.activeNetworkConfig();
       
        // After broadcasting is a real TXN
        vm.startBroadcast();
        // Mock contract
        fundMe = new FundMe(priceFeedAddr);
        vm.stopBroadcast();
        return fundMe;
    }
}
