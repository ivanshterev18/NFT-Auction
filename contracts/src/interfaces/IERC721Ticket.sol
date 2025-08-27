// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IERC721Ticket {
    struct SupportedToken {
        address token;
        string symbol;
    }

    function setMintPrice(uint256 newPrice) external;
    function mintNFT() external payable;
    function mintNFTWithToken(address token) external;
    function setPriceFeed(address token, address priceFeedAddress, string memory symbol) external;
    function withdraw() external;
    function getSupportedTokensWithSymbols() external view returns (SupportedToken[] memory);
    function getMintPriceInToken(address token) external view returns (uint256);
    function isWhitelisted(address user) external view returns (bool);
    function isAdmin(address account) external view returns (bool);
    function getNFTsOfOwner(address owner) external view returns (uint256[] memory);
    function getTokenSymbol(address token) external view returns (string memory);
}
