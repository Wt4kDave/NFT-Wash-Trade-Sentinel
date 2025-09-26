// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title NFTWashTradeResponse
/// @notice This contract is the response component for the NFTWashTradeSentinel trap.
/// @dev It is called by a trusted Drosera operator when a wash trade is detected.
///      Its purpose is to emit an event logging the details of the detected wash trade.
contract NFTWashTradeResponse {
    // --- State Variables ---

    /// @notice The trusted operator address authorized to call the execute function.
    address public immutable operator;

    // --- Constants ---

    /// @dev 4-byte selector for the response function, to prevent misrouting.
    bytes4 public constant WASH_TRADE_SELECTOR = bytes4(keccak256("WashTradeDetected(address,uint256,address,address)"));

    // --- Events ---

    /// @notice Emitted when a potential NFT wash trade is detected and reported.
    event WashTradeDetected(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address walletA,
        address walletB
    );

    // --- Errors ---

    /// @notice Thrown when the caller of execute is not the authorized operator.
    error Unauthorized();

    /// @notice Thrown when the response data has an invalid selector.
    error InvalidSelector();

    // --- Constructor ---

    constructor(address _operator) {
        if (_operator == address(0)) revert();
        operator = _operator;
    }

    // --- Response Function ---

    /// @notice This function is called by the Drosera operator to execute the response.
    /// @dev It decodes the response data from the trap and emits an event.
    ///      It is protected by the onlyOperator modifier.
    /// @param responseData The abi-encoded data from the trap, containing the selector and trade details.
    function execute(bytes calldata responseData) external {
        if (msg.sender != operator) revert Unauthorized();

        bytes4 selector = bytes4(responseData[:4]);
        if (selector != WASH_TRADE_SELECTOR) revert InvalidSelector();

        (address nftAddress, uint256 tokenId, address walletA, address walletB) =
            abi.decode(responseData[4:], (address, uint256, address, address));

        emit WashTradeDetected(nftAddress, tokenId, walletA, walletB);
    }
}
