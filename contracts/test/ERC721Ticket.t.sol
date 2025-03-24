// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ERC721Ticket} from "src/ERC721Ticket.sol";
import {MockAggregatorV3} from "./mocks/MockPriceFeed.sol";
import {IERC721TicketErrors} from "src/interfaces/IERC721TIcketErrors.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockAdminWallet} from "./mocks/MockAdminWallet.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract ERC721TicketTest is Test {
    ERC721Ticket erc721Ticket;
    address admin = address(0x1);
    address user = address(0x2);
    address user1 = address(0x3);
    bytes32 role = keccak256("ADMIN_ROLE");

    MockERC20 mockToken;
    MockAggregatorV3 public mockPriceFeed;
    MockAdminWallet adminWallet;
    address adminWalletAddress;
    uint256 mintPrice = 0.01 ether;

    bytes32 public merkleRoot;
    bytes32[] proof1;
    bytes32[] proof2;

    function setUp() public {
        vm.startPrank(admin);
        erc721Ticket = new ERC721Ticket();
        mockToken = new MockERC20("Mock Token", "MTK");
        mockPriceFeed = new MockAggregatorV3(2000 * 10 ** 8, 8);
        adminWallet = new MockAdminWallet();
        adminWalletAddress = address(adminWallet);

        address[] memory whitelistedAddresses = new address[](2);
        whitelistedAddresses[0] = admin;
        whitelistedAddresses[1] = user;

        // Generate the Merkle root for both addresses
        bytes32 root = generateMerkleRoot(whitelistedAddresses);
        erc721Ticket.updateWhitelistMerkleRoot(root);

        proof1 = generateMerkleProof(whitelistedAddresses, admin);
        proof2 = generateMerkleProof(whitelistedAddresses, user);

        vm.stopPrank();
    }

    function testSetMintPrice() public {
        vm.startPrank(admin);
        erc721Ticket.setMintPrice(0.01 ether);
        assertEq(erc721Ticket.mintPrice(), 0.01 ether);
        vm.stopPrank();
    }

    function testSetMintPriceUnauthorized() public {
        uint256 newPrice = 0.1 ether;
        vm.startPrank(user);

        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, role));
        erc721Ticket.setMintPrice(newPrice);
        vm.stopPrank();
    }

    function testMintNFT() public {
        vm.startPrank(admin);
        erc721Ticket.setMintPrice(0.01 ether);
        vm.stopPrank();

        vm.startPrank(user);
        vm.deal(user, 0.01 ether);
        erc721Ticket.mintNFT{value: 0.01 ether}(proof2);
        assertEq(erc721Ticket.balanceOf(user), 1);
        vm.stopPrank();
    }

    function testSetPriceFeed() public {
        vm.startPrank(admin);

        address token = address(0x123);
        address priceFeedAddress = address(0x456);
        string memory symbol = "TEST";

        erc721Ticket.setPriceFeed(token, priceFeedAddress, symbol);

        assertEq(erc721Ticket.getSupportedTokens().length, 1);
        assertEq(erc721Ticket.getSupportedTokens()[0].token, token);
        assertEq(erc721Ticket.getSupportedTokens()[0].symbol, symbol);

        vm.stopPrank();
    }

    function testIsWhitelisted() public {
        vm.startPrank(admin);
        assertTrue(erc721Ticket.isWhitelisted(proof1), "Address should be whitelisted");
        vm.stopPrank();
    }

    function testGetMintPriceInToken() public {
        // Set up the price feed for the token
        address token = address(0x123);
        address priceFeedAddress = address(0x456);
        uint256 mintPriceInETH = 0.01 ether; // Set the mint price in ETH

        vm.startPrank(admin);
        // Set the mint price in the contract
        erc721Ticket.setMintPrice(mintPriceInETH);

        // Assume the price feed returns a price of 2000 for 1 ETH in the token
        erc721Ticket.updateWhitelistMerkleRoot(keccak256(abi.encodePacked(admin)));
        erc721Ticket.setPriceFeed(token, priceFeedAddress, "TEST");
        vm.stopPrank();

        // Mock the price feed to return a specific price
        vm.mockCall(
            priceFeedAddress, abi.encodeWithSignature("latestRoundData()"), abi.encode(0, int256(2000), 0, 0, 0)
        );

        // // Call the function to get the mint price in the token
        uint256 mintPriceInToken = erc721Ticket.getMintPriceInToken(token);

        // // Calculate expected price in token
        uint256 expectedPriceInToken = (mintPriceInETH * 2000) / 1e8; // Adjust for decimals

        // // Assert that the returned price matches the expected price
        assertEq(mintPriceInToken, expectedPriceInToken, "Mint price in token should match expected price");
    }

    function testGetMintPriceInTokenEquals() public {
        // Mock price feed for converting ETH to USDC
        address token = address(0x123); // Mock token address

        uint256 mockEthPriceInToken = 2000 * 10 ** 6; // 1 ETH = 2000 USDC, with 6 decimals

        vm.startPrank(admin);
        erc721Ticket.setMintPrice(mintPrice);
        erc721Ticket.updateWhitelistMerkleRoot(keccak256(abi.encodePacked(admin)));
        erc721Ticket.setPriceFeed(token, address(mockPriceFeed), "TEST");

        uint256 expectedTokenAmount = (mintPrice * uint256(mockEthPriceInToken)) / 1e6;

        uint256 tokenAmount = erc721Ticket.getMintPriceInToken(token);

        assertEq(tokenAmount, expectedTokenAmount);
    }

    // function testUpdateAndRemoveWhitelist() public {
    //     vm.deal(admin, 100 ether);
    //     vm.startPrank(admin);

    //     vm.startPrank(secondAddress);

    //     // Generate proof for the second address
    //     assertTrue(erc721Ticket.isWhitelisted(proof), "Address should be whitelisted");
    //     vm.stopPrank();

    //     vm.startPrank(admin);
    //     address[] memory updatedWhitelistedAddresses = new address[](1);
    //     updatedWhitelistedAddresses[0] = admin;
    //     bytes32 updatedRoot = generateMerkleRoot(updatedWhitelistedAddresses);
    //     erc721Ticket.updateWhitelistMerkleRoot(updatedRoot);

    //     vm.startPrank(secondAddress);

    //     bytes32[] memory updatedProof = generateMerkleProof(updatedWhitelistedAddresses, secondAddress);

    //     assertFalse(erc721Ticket.isWhitelisted(updatedProof), "Address should not be whitelisted");
    // }

    function testMintNFTWithToken() public {
        vm.startPrank(admin);
        erc721Ticket.setMintPrice(mintPrice);
        erc721Ticket.setPriceFeed(address(mockToken), address(mockPriceFeed), "MTK");
        mockToken.mint(admin, 1000 * 10 ** mockToken.decimals());

        mockToken.approve(address(erc721Ticket), 1000 * 10 ** mockToken.decimals());
        erc721Ticket.mintNFTWithToken(address(mockToken), proof1);

        assertEq(erc721Ticket.balanceOf(admin), 1);
        vm.stopPrank();
    }

    function testMintNFTNotWhitelisted() public {
        vm.startPrank(address(0x123)); // A non-admin address

        vm.expectRevert(IERC721TicketErrors.NotWhitelisted.selector);
        erc721Ticket.mintNFT(proof1);

        vm.stopPrank();
    }

    function testMintNFTInsufficientFunds() public {
        vm.startPrank(admin);
        erc721Ticket.setMintPrice(mintPrice);
        vm.stopPrank();

        vm.startPrank(user);

        vm.expectRevert(IERC721TicketErrors.InsufficientFunds.selector);
        erc721Ticket.mintNFT{value: 0 ether}(proof2); // Sending less than mintPrice

        vm.stopPrank();
    }

    function testIsAdmin() public {
        assertTrue(erc721Ticket.isAdmin(admin), "Admin should be recognized as an admin");

        assertFalse(erc721Ticket.isAdmin(user), "User should not be recognized as an admin");
    }

    function testGetNFTsOfOwner() public {
        vm.startPrank(admin);

        erc721Ticket.mintNFT(proof1);
        vm.stopPrank();

        uint256[] memory nfts = erc721Ticket.getNFTsOfOwner(admin);

        assertEq(nfts.length, 1, "Admin should own one NFT");
        assertEq(nfts[0], 0, "Check the token ID of the minted NFT");
    }

    function testWithdraw() public {
        vm.startPrank(adminWalletAddress);
        vm.deal(adminWalletAddress, 10 ether);

        ERC721Ticket erc721Ticket2 = new ERC721Ticket();
        erc721Ticket2.setMintPrice(mintPrice);

        address[] memory whitelistedAddresses = new address[](1);
        whitelistedAddresses[0] = adminWalletAddress;
        bytes32 root = generateMerkleRoot(whitelistedAddresses);
        erc721Ticket2.updateWhitelistMerkleRoot(root);

        uint256 initialBalance = address(erc721Ticket2).balance;
        bytes32[] memory localProof = generateMerkleProof(whitelistedAddresses, adminWalletAddress);

        erc721Ticket2.mintNFT{value: mintPrice}(localProof);

        uint256 withdrawAmount = address(this).balance;
        erc721Ticket2.withdraw();

        assertEq(address(erc721Ticket2).balance, 0, "Contract balance should be zero after withdraw");

        assertEq(
            address(this).balance, initialBalance + withdrawAmount, "Admin balance should increase by withdraw amount"
        );
        vm.stopPrank();
    }

    // Helper functions

    function generateMerkleRoot(address[] memory addresses) internal pure returns (bytes32) {
        bytes32[] memory leaves = new bytes32[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            leaves[i] = keccak256(abi.encodePacked(addresses[i]));
        }
        return computeMerkleRoot(leaves);
    }

    function generateMerkleProof(address[] memory addresses, address target) internal pure returns (bytes32[] memory) {
        bytes32[] memory leaves = new bytes32[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            leaves[i] = keccak256(abi.encodePacked(addresses[i]));
        }
        return computeMerkleProof(leaves, target);
    }

    function computeMerkleRoot(bytes32[] memory leaves) internal pure returns (bytes32) {
        require(leaves.length > 0, "Empty leaf array");

        while (leaves.length > 1) {
            uint256 len = leaves.length;
            for (uint256 i = 0; i < len / 2; i++) {
                leaves[i] = keccak256(abi.encodePacked(leaves[2 * i], leaves[2 * i + 1]));
            }
            if (len % 2 == 1) {
                leaves[len / 2] = leaves[len - 1];
                len++;
            }
            // Resize the array manually
            bytes32[] memory newLeaves = new bytes32[](len / 2);
            for (uint256 i = 0; i < len / 2; i++) {
                newLeaves[i] = leaves[i];
            }
            leaves = newLeaves;
        }
        return leaves[0];
    }

    function computeMerkleProof(bytes32[] memory leaves, address target) internal pure returns (bytes32[] memory) {
        uint256 index = 0;
        for (uint256 i = 0; i < leaves.length; i++) {
            if (leaves[i] == keccak256(abi.encodePacked(target))) {
                index = i;
                break;
            }
        }
        bytes32[] memory proof = new bytes32[](leaves.length - 1);
        uint256 proofIndex = 0;
        for (uint256 i = 0; i < leaves.length; i++) {
            if (i != index) {
                proof[proofIndex++] = leaves[i];
            }
        }
        return proof;
    }
}
