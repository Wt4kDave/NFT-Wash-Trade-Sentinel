// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title NFTWashTradeResponse
/// @notice This contract is the response component for the NFTWashTradeSentinel trap.
/// @dev It is called by the Drosera protocol when a wash trade is detected.
///      Its purpose is to emit an event logging the details of the detected wash trade.
contract NFTWashTradeResponse {
    // --- Events ---

    /// @notice Emitted when a potential NFT wash trade is detected and reported.
    /// @param trap The address of the trap that triggered this response.
    /// @param nftAddress The address of the NFT collection involved.
    /// @param tokenId The ID of the token being wash traded.
    /// @param walletA The first wallet involved in the trade.
    /// @param walletB The second wallet involved in the trade.
    event WashTradeDetected(
        address indexed trap,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address walletA,
        address walletB
    );

    // --- Response Function ---

    /// @notice This function is called by the Drosera protocol to execute the response.
    /// @dev It decodes the response data from the trap and emits an event.
    ///      The `trapAddress` is passed by the Drosera protocol, identifying the source of the alert.
    /// @param trapAddress The address of the NFTWashTradeSentinel trap that triggered this call.
    /// @param responseData The abi-encoded data from the trap, containing details of the trade.
    function raiseAlert(address trapAddress, bytes calldata responseData) external {
        (address nftAddress, uint256 tokenId, address walletA, address walletB) =
            abi.decode(responseData, (address, uint256, address, address));

        emit WashTradeDetected(trapAddress, nftAddress, tokenId, walletA, walletB);
    }
}
