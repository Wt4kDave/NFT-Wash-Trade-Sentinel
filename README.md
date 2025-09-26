# NFT Wash Trade Sentinel

This Drosera trap is designed to detect and alert on potential NFT wash trading activities on the blockchain.

## How It Works

The sentinel uses an **owner snapshot pattern** to detect potential wash trades. It periodically calls the `ownerOf()` function on a specific NFT contract to record the owner at that moment.

The core logic then analyzes a sequence of these snapshots to identify a simple wash trade pattern.

### Heuristics

- **Snapshot Analysis**: The trap collects the owner of a specific `tokenId` at regular intervals.
- **Pattern Detection**: It flags a potential wash trade if it detects a direct back-and-forth transfer pattern between two wallets (e.g., Wallet A → Wallet B → Wallet A).

This version of the trap detects a single, direct transfer reversal. It does not currently track transfers over a wider time window or count multiple alternations.

The primary goal of this sentinel is to provide real-time alerts for on-chain activities that suggest market manipulation, helping to maintain a fair and transparent NFT marketplace.
