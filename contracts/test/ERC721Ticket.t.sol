// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {ERC721Ticket} from "src/ERC721Ticket.sol";
import {MockAggregatorV3} from "./mocks/MockPriceFeed.sol";
import {IERC721TicketErrors} from "src/interfaces/IERC721TicketErrors.sol";
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

    function setUp() public {
        vm.startPrank(admin);
        erc721Ticket = new ERC721Ticket();
        mockToken = new MockERC20("Mock Token", "MTK");
        mockPriceFeed = new MockAggregatorV3(2000 * 10 ** 8, 8);
        adminWallet = new MockAdminWallet();
        adminWalletAddress = address(adminWallet);

        erc721Ticket.addToWhitelist(admin);
        erc721Ticket.addToWhitelist(user);

        vm.stopPrank();
    }

    function testSetMintPrice() public {
        vm.startPrank(admin);
        erc721Ticket.setMintPrice(0.01 ether);
        assertEq(erc721Ticket.mintPrice(), 0.01 ether);
        vm.stopPrank();
    }

    function testMintNFT() public {
        vm.startPrank(admin);
        erc721Ticket.setMintPrice(0.01 ether);
        vm.stopPrank();

        vm.startPrank(user);
        vm.deal(user, 0.01 ether);
        erc721Ticket.mintNFT{value: 0.01 ether}();
        assertEq(erc721Ticket.balanceOf(user), 1);
        vm.stopPrank();
    }

    function testSetPriceFeed() public {
        vm.startPrank(admin);

        address token = address(0x123);
        address priceFeedAddress = address(0x456);
        string memory symbol = "TEST";

        erc721Ticket.setPriceFeed(token, priceFeedAddress, symbol);

        assertEq(erc721Ticket.getSupportedTokensWithSymbols().length, 1);
        assertEq(erc721Ticket.getSupportedTokensWithSymbols()[0].token, token);
        assertEq(erc721Ticket.getTokenSymbol(token), symbol);

        vm.stopPrank();
    }

    function testIsWhitelisted() public {
        vm.startPrank(admin);
        assertTrue(erc721Ticket.isWhitelisted(admin), "Address should be whitelisted");
        vm.stopPrank();
    }

    function testGetMintPriceInToken() public {
        address token = address(0x123);
        address priceFeedAddress = address(0x456);
        uint256 mintPriceInETH = 0.01 ether;

        vm.startPrank(admin);

        erc721Ticket.setMintPrice(mintPriceInETH);

        erc721Ticket.setPriceFeed(token, priceFeedAddress, "TEST");
        vm.stopPrank();

        vm.mockCall(
            priceFeedAddress, abi.encodeWithSignature("latestRoundData()"), abi.encode(0, int256(2000), 0, 0, 0)
        );

        uint256 mintPriceInToken = erc721Ticket.getMintPriceInToken(token);

        uint256 expectedPriceInToken = (mintPriceInETH * 2000) / 1e8; // Adjust for decimals

        assertEq(mintPriceInToken, expectedPriceInToken, "Mint price in token should match expected price");
    }

    function testMintNFTWithToken() public {
        vm.startPrank(admin);
        erc721Ticket.setMintPrice(mintPrice);
        erc721Ticket.setPriceFeed(address(mockToken), address(mockPriceFeed), "MTK");
        mockToken.mint(admin, 1000 * 10 ** mockToken.decimals());

        mockToken.approve(address(erc721Ticket), 1000 * 10 ** mockToken.decimals());
        erc721Ticket.mintNFTWithToken(address(mockToken));

        assertEq(erc721Ticket.balanceOf(admin), 1);
        vm.stopPrank();
    }

    function testMintNFTWithInsufficientFunds() public {
        vm.startPrank(admin);
        erc721Ticket.setMintPrice(0.005 ether);

        vm.startPrank(user);
        vm.deal(user, 0.004 ether);

        vm.expectRevert(IERC721TicketErrors.InsufficientFunds.selector);
        erc721Ticket.mintNFT{value: 0.004 ether}();
        vm.stopPrank();
    }

    function testMintNFTNotWhitelisted() public {
        vm.startPrank(address(0x123));

        vm.expectRevert(IERC721TicketErrors.NotWhitelisted.selector);
        erc721Ticket.mintNFT();

        vm.stopPrank();
    }

    function testSetMintPriceWithZero() public {
        vm.startPrank(admin);
        vm.expectRevert(IERC721TicketErrors.MintPriceMustBeGreaterThanZero.selector);
        erc721Ticket.setMintPrice(0);
        vm.stopPrank();
    }

    function testIsAdmin() public {
        assertTrue(erc721Ticket.isAdmin(admin), "Admin should be recognized as an admin");
        assertFalse(erc721Ticket.isAdmin(user), "User should not be recognized as an admin");
    }

    function testGetNFTsOfOwner() public {
        vm.startPrank(admin);

        erc721Ticket.mintNFT();
        vm.stopPrank();

        uint256[] memory nfts = erc721Ticket.getNFTsOfOwner(admin);

        assertEq(nfts.length, 1, "Admin should own one NFT");
        assertEq(nfts[0], 0, "Check the token ID of the minted NFT");
    }

    function testWithdraw() public {
        vm.startPrank(adminWalletAddress);
        vm.deal(adminWalletAddress, 10 ether);

        ERC721Ticket erc721Ticket2 = new ERC721Ticket();
        erc721Ticket2.addToWhitelist(adminWalletAddress);
        erc721Ticket2.setMintPrice(mintPrice);

        uint256 initialBalance = address(erc721Ticket2).balance;

        erc721Ticket2.mintNFT{value: mintPrice}();

        uint256 withdrawAmount = address(this).balance;
        erc721Ticket2.withdraw();

        assertEq(address(erc721Ticket2).balance, 0, "Contract balance should be zero after withdraw");

        assertEq(
            address(this).balance, initialBalance + withdrawAmount, "Admin balance should increase by withdraw amount"
        );
        vm.stopPrank();
    }

    function testRemoveFromWhitelist() public {
        vm.startPrank(admin);
        erc721Ticket.removeFromWhitelist(user);
        assertFalse(erc721Ticket.isWhitelisted(user), "User should be removed from whitelist");
        vm.stopPrank();
    }

    function testGetWhitelistedUsers() public {
        vm.startPrank(admin);
        address[] memory whitelistedUsers = erc721Ticket.getWhitelistedUsers();
        assertEq(whitelistedUsers.length, 2, "Should have 2 whitelisted users");
        assertEq(whitelistedUsers[0], admin, "First user should be admin");
        assertEq(whitelistedUsers[1], user, "Second user should be user");
        vm.stopPrank();
    }

    function testSupportsInterface() public {
        assertTrue(erc721Ticket.supportsInterface(0x80ac58cd), "Should support ERC721 interface");
        assertTrue(erc721Ticket.supportsInterface(0x7965db0b), "Should support AccessControl interface");
        assertFalse(erc721Ticket.supportsInterface(0x12345678), "Should not support random interface");
    }

    function testMintNFTWithTokenTransferFailure() public {
        vm.startPrank(admin);
        erc721Ticket.setMintPrice(mintPrice);
        erc721Ticket.setPriceFeed(address(mockToken), address(mockPriceFeed), "MTK");

        MockERC20 failingToken = new MockERC20("Failing Token", "FTK");
        failingToken.mint(admin, 1000 * 10 ** failingToken.decimals());

        erc721Ticket.setPriceFeed(address(failingToken), address(mockPriceFeed), "FTK");

        vm.mockCall(
            address(failingToken), abi.encodeWithSignature("transferFrom(address,address,uint256)"), abi.encode(false)
        );

        vm.expectRevert(IERC721TicketErrors.TokenTransferFailed.selector);
        erc721Ticket.mintNFTWithToken(address(failingToken));
        vm.stopPrank();
    }

    function testMintNFTWithTokenNotWhitelisted() public {
        vm.startPrank(admin);
        erc721Ticket.setMintPrice(mintPrice);
        erc721Ticket.setPriceFeed(address(mockToken), address(mockPriceFeed), "MTK");
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert(IERC721TicketErrors.NotWhitelisted.selector);
        erc721Ticket.mintNFTWithToken(address(mockToken));
        vm.stopPrank();
    }

    function testGetMintPriceInTokenWithInvalidPriceFeed() public {
        vm.startPrank(admin);
        erc721Ticket.setMintPrice(mintPrice);

        address invalidToken = address(0x999);
        erc721Ticket.setPriceFeed(invalidToken, address(0), "INVALID");

        vm.expectRevert();
        erc721Ticket.getMintPriceInToken(invalidToken);
        vm.stopPrank();
    }

    function testGetMintPriceInTokenWithInvalidPrice() public {
        vm.startPrank(admin);
        erc721Ticket.setMintPrice(mintPrice);

        MockAggregatorV3 negativePriceFeed = new MockAggregatorV3(-1000 * 10 ** 8, 8);

        address token = address(0x888);
        erc721Ticket.setPriceFeed(token, address(negativePriceFeed), "NEG");

        vm.expectRevert(IERC721TicketErrors.InvalidETHPrice.selector);
        erc721Ticket.getMintPriceInToken(token);
        vm.stopPrank();
    }

    function testMultipleSupportedTokenOperations() public {
        vm.startPrank(admin);

        address token1 = address(0x111);
        address token2 = address(0x222);
        address token3 = address(0x333);

        erc721Ticket.setPriceFeed(token1, address(0x444), "TKN1");
        erc721Ticket.setPriceFeed(token2, address(0x555), "TKN2");
        erc721Ticket.setPriceFeed(token3, address(0x666), "TKN3");

        assertEq(erc721Ticket.getSupportedTokensWithSymbols().length, 3, "Should have 3 supported tokens");

        erc721Ticket.removeSupportedToken(token2);
        assertEq(erc721Ticket.getSupportedTokensWithSymbols().length, 2, "Should have 2 supported tokens after removal");

        vm.stopPrank();
    }
}
