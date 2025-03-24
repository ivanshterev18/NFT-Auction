// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Ticket} from "src/interfaces/IERC721Ticket.sol";
import {IERC721TicketErrors} from "src/interfaces/IERC721TIcketErrors.sol";

contract ERC721Ticket is ERC721, AccessControl, IERC721Ticket, IERC721TicketErrors {
    SupportedToken[] public supportedTokens;
    mapping(address => AggregatorV3Interface) public priceFeeds;
    uint256 public mintPrice;

    uint256 private _nftCounter;
    bytes32 private merkleRoot;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor() ERC721("NFTicket", "NT") {
        _grantRole(ADMIN_ROLE, msg.sender);
        _nftCounter = 0;
    }

    /**
     * @dev Sets the mint price for the NFTs.
     * @param newPrice The new mint price in wei.
     */
    function setMintPrice(uint256 newPrice) external onlyRole(ADMIN_ROLE) {
        mintPrice = newPrice;
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
        if (!isTokenSupported(token)) {
            supportedTokens.push(SupportedToken(token, symbol));
        }
    }

    /**
     * @dev Updates the Merkle root for the whitelist.
     * @param _newRoot The new Merkle root.
     */
    function updateWhitelistMerkleRoot(bytes32 _newRoot) external onlyRole(ADMIN_ROLE) {
        merkleRoot = _newRoot;
    }

    /**
     * @dev Mints an NFT for the sender if they are whitelisted and have sent enough ETH.
     * @param _proof The Merkle proof for verification.
     */
    function mintNFT(bytes32[] calldata _proof) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_proof, merkleRoot, leaf)) {
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
     * @param _proof The Merkle proof for verification.
     */
    function mintNFTWithToken(address token, bytes32[] calldata _proof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_proof, merkleRoot, leaf)) {
            revert NotWhitelisted();
        }

        // Convert the mint price from ETH to the equivalent amount in the specified token
        uint256 tokenAmountRequired = convertETHToToken(token);
        if (!IERC20(token).transferFrom(msg.sender, address(this), tokenAmountRequired)) {
            revert TokenTransferFailed();
        }

        _safeMint(msg.sender, _nftCounter);
        _nftCounter++;
    }

    /**
     * @dev Withdraws the contract's balance to the admin's address.
     */
    function withdraw() external onlyRole(ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Checks if an address is whitelisted using a Merkle proof.
     * @param _proof The Merkle proof for verification.
     * @return True if the address is whitelisted, false otherwise.
     */
    function isWhitelisted(bytes32[] calldata _proof) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_proof, merkleRoot, leaf);
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
     * @dev Gets the list of supported tokens.
     * @return An array of supported tokens.
     */
    function getSupportedTokens() external view returns (SupportedToken[] memory) {
        return supportedTokens;
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
     * @dev Converts a specified amount of a token to its equivalent in ETH using the price feed.
     * @param token The address of the token to convert.
     * @param tokenAmount The amount of the token to convert.
     * @return The equivalent amount in wei.
     */
    function convertTokenToETH(address token, uint256 tokenAmount) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = priceFeeds[token];
        if (address(priceFeed) == address(0)) {
            revert PriceFeedNotSet(token);
        }

        // Fetch the latest price from the Chainlink oracle
        (, int256 price,,,) = priceFeed.latestRoundData();

        // Convert token to ETH (assuming the token has 6 decimals)
        return (tokenAmount * uint256(price)) / 1e6;
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
        return (mintPrice * uint256(ethPrice) * 1e10) / 1e18; // Adjust for decimals
    }

    /**
     * @dev Checks if a token is supported.
     * @param token The address of the token.
     * @return True if the token is supported, false otherwise.
     */
    function isTokenSupported(address token) internal view returns (bool) {
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            if (supportedTokens[i].token == token) {
                return true;
            }
        }
        return false;
    }
}
