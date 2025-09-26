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
    // --- Data Structures ---

    /// @dev Holds the snapshot data collected at a specific block.
    struct Snap {
        address owner;
        uint256 blockNum;
    }

    // --- Hardcoded Configuration ---

    ERC721 public constant NFT_ADDRESS = ERC721(0x730ceaf5a436ae2542588d94dF7426C56238222b);

    // @dev The specific token ID to monitor within the NFT collection.
    uint256 public constant TOKEN_ID = 1;

    // @dev The first wallet involved in the potential wash trade.
    address public constant WALLET_A = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    // @dev The second wallet involved in the potential wash trade.
    address public constant WALLET_B = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    // @dev The maximum number of blocks between the first and last transaction.
    uint256 public constant BLOCK_WINDOW = 100;

    // @dev 4-byte selector for the response function, to prevent misrouting.
    bytes4 public constant WASH_TRADE_SELECTOR = bytes4(keccak256("WashTradeDetected(address,uint256,address,address)"));

    // --- ITrap Interface ---

    /// @notice Collects the current owner of the monitored NFT and the block number.
    /// @dev This function is called periodically by the Drosera network.
    ///      It returns the encoded Snap struct containing the owner and block number.
    function collect() external view override returns (bytes memory) {
        Snap memory snap = Snap({
            owner: NFT_ADDRESS.ownerOf(TOKEN_ID),
            blockNum: block.number
        });
        return abi.encode(snap);
    }

    /// @notice Determines if a response should be triggered based on collected data.
    /// @dev It looks for a pattern where NFT ownership moves between WALLET_A and WALLET_B
    ///      within a defined block window.
    /// @param data An array of bytes, where each element is an abi-encoded Snap struct.
    /// @return shouldRespond A boolean indicating whether to trigger the response.
    /// @return responseData The data to be passed to the response contract if shouldRespond is true.
    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        // A wash trade pattern requires at least 3 data points.
        if (data.length < 3) {
            return (false, "");
        }

        // In Drosera, data[0] is the most recent sample.
        Snap memory snap_t0 = abi.decode(data[0], (Snap)); // Current state (t-0)
        Snap memory snap_t1 = abi.decode(data[1], (Snap)); // State at t-1
        Snap memory snap_t2 = abi.decode(data[2], (Snap)); // State at t-2

        // 1. Check if the transfers happened within the defined block window.
        if (snap_t0.blockNum > snap_t2.blockNum + BLOCK_WINDOW) {
            return (false, "");
        }

        // 2. Check for both A -> B -> A and B -> A -> B patterns.
        bool patternABA = (snap_t2.owner == WALLET_A && snap_t1.owner == WALLET_B && snap_t0.owner == WALLET_A);
        bool patternBAB = (snap_t2.owner == WALLET_B && snap_t1.owner == WALLET_A && snap_t0.owner == WALLET_B);

        if (patternABA || patternBAB) {
            // 3. Tag the payload with the selector.
            bytes memory responseData = abi.encode(NFT_ADDRESS, TOKEN_ID, WALLET_A, WALLET_B);
            return (true, abi.encodePacked(WASH_TRADE_SELECTOR, responseData));
        }

        return (false, "");
    }
}
