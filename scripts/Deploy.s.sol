// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {NFTWashTradeResponse} from "../src/NFTWashTradeResponse.sol";
import {MockERC721} from "../test/mocks/MockERC721.sol";

contract Deploy is Script {
    function run() external returns (NFTWashTradeResponse, MockERC721) {
        vm.startBroadcast();

        // Deploy the mock NFT contract for testing purposes
        MockERC721 mockNft = new MockERC721();
        console.log("MockERC721 deployed at:", address(mockNft));

        // Deploy the response contract
        NFTWashTradeResponse responseContract = new NFTWashTradeResponse();
        console.log("NFTWashTradeResponse deployed at:", address(responseContract));

        vm.stopBroadcast();
        return (responseContract, mockNft);
    }
}
