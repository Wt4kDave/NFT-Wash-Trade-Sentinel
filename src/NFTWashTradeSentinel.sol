// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";

/// @title NFTWashTradeSentinel
/// @notice This trap detects a specific NFT wash trading pattern:
///         an NFT being transferred back and forth between two specific wallets.
/// @dev This is a stateless trap designed for the Drosera Protocol.
///      It monitors ownership of a single, hardcoded NFT.
contract NFTWashTradeSentinel is ITrap {
    // --- Hardcoded Configuration ---

    ERC721 public constant NFT_ADDRESS = ERC721(0x730ceaf5a436ae2542588d94dF7426C56238222b);

    // @dev The specific token ID to monitor within the NFT collection.
    uint256 public constant TOKEN_ID = 1;

    // @dev The first wallet involved in the potential wash trade.
    address public constant WALLET_A = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    // @dev The second wallet involved in the potential wash trade.
    address public constant WALLET_B = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    // --- ITrap Interface ---

    /// @notice Collects the current owner of the monitored NFT.
    /// @dev This function is called periodically by the Drosera network.
    ///      It returns the encoded owner address of the specified TOKEN_ID.
    function collect() external view override returns (bytes memory) {
        address owner = NFT_ADDRESS.ownerOf(TOKEN_ID);
        return abi.encode(owner);
    }

    /// @notice Determines if a response should be triggered based on collected data.
    /// @dev This function is called by the Drosera network with an array of data
    ///      from previous `collect` calls. It looks for a pattern where the NFT
    ///      ownership moves from WALLET_A to WALLET_B and then back to WALLET_A.
    /// @param data An array of bytes, where each element is an abi-encoded owner address.
    /// @return shouldRespond A boolean indicating whether to trigger the response.
    /// @return responseData The data to be passed to the response contract if shouldRespond is true.
    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        // A wash trade pattern A -> B -> A requires at least 3 data points.
        if (data.length < 3) {
            return (false, "");
        }

        // In Drosera, data[0] is the most recent sample.
        (address owner_t0) = abi.decode(data[0], (address)); // Current state (t-0)
        (address owner_t1) = abi.decode(data[1], (address)); // State at t-1
        (address owner_t2) = abi.decode(data[2], (address)); // State at t-2

        bool isWashTradePattern = (owner_t2 == WALLET_A && owner_t1 == WALLET_B && owner_t0 == WALLET_A);

        if (isWashTradePattern) {
            bytes memory responseData = abi.encode(NFT_ADDRESS, TOKEN_ID, WALLET_A, WALLET_B);
            return (true, responseData);
        }

        return (false, "");
    }
}
