// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "solmate/tokens/ERC721.sol";

contract MockERC721 is ERC721 {
    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to, uint256 id) public {
        _mint(to, id);
    }

    function tokenURI(uint256 /*id*/) public view virtual override returns (string memory) {
        return "mock://token.uri";
    }
}
