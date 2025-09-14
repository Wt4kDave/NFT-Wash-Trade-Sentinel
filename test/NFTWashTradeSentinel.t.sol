// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {NFTWashTradeSentinel} from "../src/NFTWashTradeSentinel.sol";
import {MockERC721} from "./mocks/MockERC721.sol";

contract NFTWashTradeSentinelTest is Test {
    NFTWashTradeSentinel public sentinel;
    MockERC721 public mockNft;

    address internal constant WALLET_A = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address internal constant WALLET_B = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    uint256 internal constant TOKEN_ID = 1;

    function setUp() public {
        // Deploy the mock NFT contract and the trap
        mockNft = new MockERC721();
        sentinel = new NFTWashTradeSentinel(address(mockNft));

        // Mint the test NFT to WALLET_A
        mockNft.mint(WALLET_A, TOKEN_ID);
    }

    /// @notice Tests that the trap correctly identifies a wash trade pattern (A -> B -> A).
    function test_shouldTriggerOnWashTrade() public {
        // --- State 1: Initial state ---
        bytes memory data0 = sentinel.collect();
        (address owner0, address nftAddr0) = abi.decode(data0, (address, address));
        assertEq(owner0, WALLET_A);
        assertEq(nftAddr0, address(mockNft));

        // --- State 2: Transfer from A to B ---
        vm.prank(WALLET_A);
        mockNft.transferFrom(WALLET_A, WALLET_B, TOKEN_ID);
        bytes memory data1 = sentinel.collect();
        (address owner1, address nftAddr1) = abi.decode(data1, (address, address));
        assertEq(owner1, WALLET_B);
        assertEq(nftAddr1, address(mockNft));

        // --- State 3: Transfer from B back to A ---
        vm.prank(WALLET_B);
        mockNft.transferFrom(WALLET_B, WALLET_A, TOKEN_ID);
        bytes memory data2 = sentinel.collect();
        (address owner2, address nftAddr2) = abi.decode(data2, (address, address));
        assertEq(owner2, WALLET_A);
        assertEq(nftAddr2, address(mockNft));

        // --- Check shouldRespond ---
        bytes[] memory collectedData = new bytes[](3);
        collectedData[0] = data0;
        collectedData[1] = data1;
        collectedData[2] = data2;

        (bool should, bytes memory responseData) = sentinel.shouldRespond(collectedData);

        // Assert the trap should trigger
        assertTrue(should, "Trap should trigger on a wash trade pattern");

        // Assert the response data is correct
        (address nft, uint256 tokenId, address walletA, address walletB) =
            abi.decode(responseData, (address, uint256, address, address));
        assertEq(nft, address(mockNft));
        assertEq(tokenId, TOKEN_ID);
        assertEq(walletA, WALLET_A);
        assertEq(walletB, WALLET_B);
    }

    /// @notice Tests that the trap does not trigger on a simple, one-way transfer.
    function test_shouldNotTriggerOnSimpleTransfer() public {
        // --- State 1: Initial state ---
        bytes memory data0 = sentinel.collect();

        // --- State 2: Transfer from A to B ---
        vm.prank(WALLET_A);
        mockNft.transferFrom(WALLET_A, WALLET_B, TOKEN_ID);
        bytes memory data1 = sentinel.collect();

        // --- Check shouldRespond with only two data points ---
        bytes[] memory collectedData = new bytes[](2);
        collectedData[0] = data0;
        collectedData[1] = data1;

        (bool should, ) = sentinel.shouldRespond(collectedData);

        // Assert the trap should NOT trigger
        assertFalse(should, "Trap should not trigger on a simple transfer");
    }
}
