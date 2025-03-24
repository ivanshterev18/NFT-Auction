// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNFT is ERC721 {
    uint256 public tokenCounter;

    constructor() ERC721("MockNFT", "MNFT") {
        tokenCounter = 0;
    }

    function mint() external {
        _mint(msg.sender, tokenCounter);
        tokenCounter++;
    }
}
