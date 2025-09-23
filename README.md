# NFT Wash Trade Sentinel

This Drosera trap is designed to detect and alert on potential NFT wash trading activities on the blockchain.

## How It Works

The sentinel periodically takes snapshots of the ownership of a specific NFT using the `ownerOf()` function. The core logic identifies when the same NFT is repeatedly transferred back and forth between a small set of addresses in a short period. This pattern is a strong indicator of wash trading, where the goal is to artificially inflate the trading volume and price of an NFT.

### Heuristics

- Monitors consecutive `Transfer` events for a specific `tokenId`.
- Tracks the `from` and `to` addresses involved in the transfers.
- Flags a potential wash trade if an NFT is transferred between the same two addresses multiple times within a defined time window.

The primary goal of this sentinel is to provide real-time alerts for on-chain activities that suggest market manipulation, helping to maintain a fair and transparent NFT marketplace.
