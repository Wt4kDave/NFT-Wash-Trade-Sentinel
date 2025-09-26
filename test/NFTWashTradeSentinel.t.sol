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
        NFTWashTradeSentinel.Snap memory snap0 = abi.decode(data0, (NFTWashTradeSentinel.Snap));
        assertEq(snap0.owner, WALLET_A);

        // --- State 2: Transfer from A to B ---
        vm.roll(block.number + 10);
        vm.prank(WALLET_A);
        MockERC721(NFT_ADDRESS).transferFrom(WALLET_A, WALLET_B, TOKEN_ID);
        bytes memory data1 = sentinel.collect();
        NFTWashTradeSentinel.Snap memory snap1 = abi.decode(data1, (NFTWashTradeSentinel.Snap));
        assertEq(snap1.owner, WALLET_B);

        // --- State 3: Transfer from B back to A ---
        vm.roll(block.number + 10);
        vm.prank(WALLET_B);
        MockERC721(NFT_ADDRESS).transferFrom(WALLET_B, WALLET_A, TOKEN_ID);
        bytes memory data2 = sentinel.collect();
        NFTWashTradeSentinel.Snap memory snap2 = abi.decode(data2, (NFTWashTradeSentinel.Snap));
        assertEq(snap2.owner, WALLET_A);

        // --- Check shouldRespond ---
        bytes[] memory collectedData = new bytes[](3);
        collectedData[0] = data2; // t-0 (newest)
        collectedData[1] = data1; // t-1
        collectedData[2] = data0; // t-2 (oldest)

        (bool should, bytes memory responseData) = sentinel.shouldRespond(collectedData);

        // Assert the trap should trigger
        assertTrue(should, "Trap should trigger on a wash trade pattern");

        // Assert the response data is correct
        bytes memory expectedPayload = abi.encode(
            address(sentinel.NFT_ADDRESS()),
            sentinel.TOKEN_ID(),
            sentinel.WALLET_A(),
            sentinel.WALLET_B()
        );
        bytes memory expectedResponse = abi.encodePacked(sentinel.WASH_TRADE_SELECTOR(), expectedPayload);
        assertEq(responseData, expectedResponse, "Response data should be correct");
    }

    /// @notice Tests that the trap correctly identifies a B -> A -> B wash trade pattern.
    function test_shouldTriggerOnWashTrade_BAB() public {
        // --- State 0: Transfer to B to set up the initial state ---
        vm.prank(WALLET_A);
        MockERC721(NFT_ADDRESS).transferFrom(WALLET_A, WALLET_B, TOKEN_ID);

        // --- State 1: Initial state ---
        bytes memory data0 = sentinel.collect();
        NFTWashTradeSentinel.Snap memory snap0 = abi.decode(data0, (NFTWashTradeSentinel.Snap));
        assertEq(snap0.owner, WALLET_B);

        // --- State 2: Transfer from B to A ---
        vm.roll(block.number + 10);
        vm.prank(WALLET_B);
        MockERC721(NFT_ADDRESS).transferFrom(WALLET_B, WALLET_A, TOKEN_ID);
        bytes memory data1 = sentinel.collect();
        NFTWashTradeSentinel.Snap memory snap1 = abi.decode(data1, (NFTWashTradeSentinel.Snap));
        assertEq(snap1.owner, WALLET_A);

        // --- State 3: Transfer from A back to B ---
        vm.roll(block.number + 10);
        vm.prank(WALLET_A);
        MockERC721(NFT_ADDRESS).transferFrom(WALLET_A, WALLET_B, TOKEN_ID);
        bytes memory data2 = sentinel.collect();
        NFTWashTradeSentinel.Snap memory snap2 = abi.decode(data2, (NFTWashTradeSentinel.Snap));
        assertEq(snap2.owner, WALLET_B);

        // --- Check shouldRespond ---
        bytes[] memory collectedData = new bytes[](3);
        collectedData[0] = data2; // t-0 (newest)
        collectedData[1] = data1; // t-1
        collectedData[2] = data0; // t-2 (oldest)

        (bool should, ) = sentinel.shouldRespond(collectedData);

        // Assert the trap should trigger
        assertTrue(should, "Trap should trigger on a B->A->B wash trade pattern");
    }

    /// @notice Tests that the trap does not trigger if transfers are outside the block window.
    function test_shouldNotTriggerOutsideWindow() public {
        // --- State 1: Initial state ---
        bytes memory data0 = sentinel.collect();

        // --- State 2: Transfer from A to B ---
        vm.roll(block.number + 50);
        vm.prank(WALLET_A);
        MockERC721(NFT_ADDRESS).transferFrom(WALLET_A, WALLET_B, TOKEN_ID);
        bytes memory data1 = sentinel.collect();

        // --- State 3: Transfer from B back to A (outside the window) ---
        vm.roll(block.number + sentinel.BLOCK_WINDOW() + 1);
        vm.prank(WALLET_B);
        MockERC721(NFT_ADDRESS).transferFrom(WALLET_B, WALLET_A, TOKEN_ID);
        bytes memory data2 = sentinel.collect();

        // --- Check shouldRespond ---
        bytes[] memory collectedData = new bytes[](3);
        collectedData[0] = data2; // t-0
        collectedData[1] = data1; // t-1
        collectedData[2] = data0; // t-2

        (bool should, ) = sentinel.shouldRespond(collectedData);

        // Assert the trap should NOT trigger
        assertFalse(should, "Trap should not trigger outside the block window");
    }

    /// @notice Tests that the trap does not trigger on a simple, one-way transfer.
    function test_shouldNotTriggerOnSimpleTransfer() public {
        // --- State 1: Initial state ---
        bytes memory data0 = sentinel.collect();

        // --- State 2: Transfer from A to B ---
        vm.roll(block.number + 10);
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
