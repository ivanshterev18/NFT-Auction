// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract MockAdminWallet is IERC721Receiver {
    // Fallback function to accept Ether
    receive() external payable {}

    // Optional: Function to withdraw Ether from the contract
    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Function to handle the receipt of an NFT
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        // You can add custom logic here if needed
        return this.onERC721Received.selector; // Return the function selector
    }
}
