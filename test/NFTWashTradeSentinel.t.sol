import {Test} from "forge-std/Test.sol";
import {NFTWashTradeSentinel} from "../src/NFTWashTradeSentinel.sol";
import {MockERC721} from "./mocks/MockERC721.sol";

contract NFTWashTradeSentinelTest is Test {
    NFTWashTradeSentinel public sentinel;
    MockERC721 public mockNft;

    address internal constant NFT_ADDRESS = 0x730ceaf5a436ae2542588d94dF7426C56238222b;
    address internal constant WALLET_A = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address internal constant WALLET_B = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    uint256 internal constant TOKEN_ID = 1;

    function setUp() public {
        // Deploy the trap
        sentinel = new NFTWashTradeSentinel();

        // Deploy the mock NFT contract at the hardcoded address
        mockNft = new MockERC721();
        vm.etch(NFT_ADDRESS, address(mockNft).code);

        // Mint the test NFT to WALLET_A
        MockERC721(NFT_ADDRESS).mint(WALLET_A, TOKEN_ID);
    }

    /// @notice Tests that the trap correctly identifies a wash trade pattern (A -> B -> A).
    function test_shouldTriggerOnWashTrade() public {
        // --- State 1: Initial state ---
        bytes memory data0 = sentinel.collect();
        (address owner0) = abi.decode(data0, (address));
        assertEq(owner0, WALLET_A);

        // --- State 2: Transfer from A to B ---
        vm.prank(WALLET_A);
        MockERC721(NFT_ADDRESS).transferFrom(WALLET_A, WALLET_B, TOKEN_ID);
        bytes memory data1 = sentinel.collect();
        (address owner1) = abi.decode(data1, (address));
        assertEq(owner1, WALLET_B);

        // --- State 3: Transfer from B back to A ---
        vm.prank(WALLET_B);
        MockERC721(NFT_ADDRESS).transferFrom(WALLET_B, WALLET_A, TOKEN_ID);
        bytes memory data2 = sentinel.collect();
        (address owner2) = abi.decode(data2, (address));
        assertEq(owner2, WALLET_A);

        // --- Check shouldRespond ---
        bytes[] memory collectedData = new bytes[](3);
        collectedData[0] = data2; // t-0 (newest)
        collectedData[1] = data1; // t-1
        collectedData[2] = data0; // t-2 (oldest)

        (bool should, bytes memory responseData) = sentinel.shouldRespond(collectedData);

        // Assert the trap should trigger
        assertTrue(should, "Trap should trigger on a wash trade pattern");

        // Assert the response data is correct
        (address nft, uint256 tokenId, address walletA, address walletB) =
            abi.decode(responseData, (address, uint256, address, address));
        assertEq(nft, NFT_ADDRESS);
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
        MockERC721(NFT_ADDRESS).transferFrom(WALLET_A, WALLET_B, TOKEN_ID);
        bytes memory data1 = sentinel.collect();

        // --- Check shouldRespond with only two data points ---
        bytes[] memory collectedData = new bytes[](2);
        collectedData[0] = data1; // t-0
        collectedData[1] = data0; // t-1

        (bool should, ) = sentinel.shouldRespond(collectedData);

        // Assert the trap should NOT trigger
        assertFalse(should, "Trap should not trigger on a simple transfer");
    }
}
