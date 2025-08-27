// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Ticket} from "src/interfaces/IERC721Ticket.sol";
import {IERC721TicketErrors} from "src/interfaces/IERC721TicketErrors.sol";

contract ERC721Ticket is ERC721, AccessControl, ReentrancyGuard, IERC721Ticket, IERC721TicketErrors {
    mapping(address => SupportedToken) public supportedTokens;
    mapping(address => AggregatorV3Interface) public priceFeeds;
    mapping(address => bool) public whitelistedUsers;

    uint256 public mintPrice;
    uint256 private _nftCounter;
    address[] private whitelistedAddresses;
    address[] private supportedTokenAddresses;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event MintPriceUpdated(uint256 newPrice);
    event SupportedTokenAdded(address indexed token, address indexed priceFeedAddress, string symbol);
    event SupportedTokenRemoved(address indexed token);
    event FundsWithdrawn(address indexed admin);

    constructor() ERC721("NFTicket", "NT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _nftCounter = 0;
    }

    /**
     * @dev Sets the mint price for the NFTs.
     * @param newPrice The new mint price in wei.
     */
    function setMintPrice(uint256 newPrice) external onlyRole(ADMIN_ROLE) {
        if (newPrice <= 0) {
            revert MintPriceMustBeGreaterThanZero();
        }
        mintPrice = newPrice;
        emit MintPriceUpdated(newPrice);
    }

    /**
     * @dev Sets the price feed for a specific token and adds it to supported tokens if not already present.
     * @param token The address of the token.
     * @param priceFeedAddress The address of the price feed contract.
     * @param symbol The symbol of the token.
     */
    function setPriceFeed(address token, address priceFeedAddress, string memory symbol)
        external
        onlyRole(ADMIN_ROLE)
    {
        priceFeeds[token] = AggregatorV3Interface(priceFeedAddress);

        // Add token to supportedTokens if it's not already present
        if (supportedTokens[token].token == address(0)) {
            supportedTokens[token] = SupportedToken(token, symbol);
            supportedTokenAddresses.push(token);
        }

        emit SupportedTokenAdded(token, priceFeedAddress, symbol);
    }

    /**
     * @dev Adds a user to the whitelist.
     * @param user The address of the user to add to the whitelist.
     */
    function addToWhitelist(address user) external onlyRole(ADMIN_ROLE) {
        if (!whitelistedUsers[user]) {
            whitelistedUsers[user] = true;
            whitelistedAddresses.push(user);
        }
    }

    /**
     * @dev Removes a user from the whitelist.
     * @param user The address of the user to remove from the whitelist.
     */
    function removeFromWhitelist(address user) external onlyRole(ADMIN_ROLE) {
        if (whitelistedUsers[user]) {
            whitelistedUsers[user] = false;

            for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
                if (whitelistedAddresses[i] == user) {
                    whitelistedAddresses[i] = whitelistedAddresses[whitelistedAddresses.length - 1];
                    whitelistedAddresses.pop();
                    break;
                }
            }
        }
    }

    /**
     * @dev Removes a token from the supported tokens list.
     * @param token The address of the token to remove.
     */
    function removeSupportedToken(address token) external onlyRole(ADMIN_ROLE) {
        if (supportedTokens[token].token != address(0)) {
            delete supportedTokens[token];
            delete priceFeeds[token];

            for (uint256 i = 0; i < supportedTokenAddresses.length; i++) {
                if (supportedTokenAddresses[i] == token) {
                    supportedTokenAddresses[i] = supportedTokenAddresses[supportedTokenAddresses.length - 1];
                    supportedTokenAddresses.pop();
                    break;
                }
            }
        }

        emit SupportedTokenRemoved(token);
    }

    /**
     * @dev Mints an NFT for the sender if they are whitelisted and have sent enough ETH.
     */
    function mintNFT() external payable {
        if (!whitelistedUsers[msg.sender]) {
            revert NotWhitelisted();
        }
        if (msg.value < mintPrice) {
            revert InsufficientFunds();
        }
        _safeMint(msg.sender, _nftCounter);
        _nftCounter++;
    }

    /**
     * @dev Mints an NFT for the sender using a specified token if they are whitelisted.
     * @param token The address of the token to use for payment.
     */
    function mintNFTWithToken(address token) external nonReentrant {
        if (!whitelistedUsers[msg.sender]) {
            revert NotWhitelisted();
        }

        // Convert the mint price from ETH to the equivalent amount in the specified token
        uint256 tokenAmountRequired = convertETHToToken(token);

        _safeMint(msg.sender, _nftCounter);
        _nftCounter++;

        if (!IERC20(token).transferFrom(msg.sender, address(this), tokenAmountRequired)) {
            revert TokenTransferFailed();
        }
    }

    /**
     * @dev Withdraws the contract's balance to the admin's address.
     */
    function withdraw() external onlyRole(ADMIN_ROLE) nonReentrant {
        payable(msg.sender).transfer(address(this).balance);
        emit FundsWithdrawn(msg.sender);
    }

    /**
     * @dev Gets the list of whitelisted users.
     * @return An array of whitelisted users.
     */
    function getWhitelistedUsers() external view onlyRole(ADMIN_ROLE) returns (address[] memory) {
        return whitelistedAddresses;
    }

    /**
     * @dev Checks if an address is whitelisted.
     * @param user The address to check.
     * @return True if the address is whitelisted, false otherwise.
     */
    function isWhitelisted(address user) external view returns (bool) {
        return whitelistedUsers[user];
    }

    /**
     * @dev Gets the mint price in a specified token.
     * @param token The address of the token.
     * @return The mint price in the specified token.
     */
    function getMintPriceInToken(address token) external view returns (uint256) {
        return convertETHToToken(token);
    }

    /**
     * @dev Gets the list of supported tokens with their addresses and symbols.
     * @return An array of SupportedToken structs containing address and symbol.
     */
    function getSupportedTokensWithSymbols() external view returns (SupportedToken[] memory) {
        uint256 length = supportedTokenAddresses.length;
        SupportedToken[] memory tokens = new SupportedToken[](length);

        for (uint256 i = 0; i < length; i++) {
            address tokenAddress = supportedTokenAddresses[i];
            tokens[i] = supportedTokens[tokenAddress];
        }

        return tokens;
    }

    function getTokenSymbol(address token) external view returns (string memory) {
        return supportedTokens[token].symbol;
    }

    /**
     * @dev Checks if an account has the admin role.
     * @param account The address to check.
     * @return True if the account is an admin, false otherwise.
     */
    function isAdmin(address account) external view returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    /**
     * @dev Gets the list of NFT IDs owned by a specific address.
     * @param owner The address of the owner.
     * @return An array of NFT IDs owned by the address.
     */
    function getNFTsOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 totalTokens = _nftCounter;
        uint256 balance = balanceOf(owner);
        uint256[] memory result = new uint256[](balance);
        uint256 resultIndex = 0;

        for (uint256 tokenId = 0; tokenId < totalTokens; tokenId++) {
            if (ownerOf(tokenId) == owner) {
                result[resultIndex] = tokenId;
                resultIndex++;
            }
        }

        return result;
    }

    /**
     * @dev This function overrides `supportsInterface` in multiple parent contracts
     * @param interfaceId The interface identifier.
     * @return True if the interface is supported, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Converts the mint price from ETH to the equivalent amount in a specified token.
     * @param token The address of the token.
     * @return The equivalent amount in the specified token.
     */
    function convertETHToToken(address token) internal view returns (uint256) {
        // Get the price of ETH in Token
        AggregatorV3Interface ethPriceInTokenFeed = priceFeeds[token];
        if (address(ethPriceInTokenFeed) == address(0)) {
            revert PriceFeedNotSet(token);
        }

        (, int256 ethPrice,,,) = ethPriceInTokenFeed.latestRoundData();
        if (ethPrice <= 0) {
            revert InvalidETHPrice();
        }

        // Supports only 6 decimal tokens
        return (mintPrice * uint256(ethPrice) * 1e10) / 1e18;
    }
}
