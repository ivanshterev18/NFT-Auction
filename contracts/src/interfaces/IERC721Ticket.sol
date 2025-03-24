// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IERC721Ticket {
    struct SupportedToken {
        address token;
        string symbol;
    }

    function setMintPrice(uint256 newPrice) external;
    function updateWhitelistMerkleRoot(bytes32 newRoot) external;
    function mintNFT(bytes32[] calldata _proof) external payable;
    function mintNFTWithToken(address token, bytes32[] calldata _proof) external;
    function setPriceFeed(address token, address priceFeedAddress, string memory symbol) external;
    function withdraw() external;
    function getSupportedTokens() external view returns (SupportedToken[] memory);
    function getMintPriceInToken(address token) external view returns (uint256);
    function isWhitelisted(bytes32[] calldata _proof) external view returns (bool);
    function isAdmin(address account) external view returns (bool);
    function getNFTsOfOwner(address owner) external view returns (uint256[] memory);
}
