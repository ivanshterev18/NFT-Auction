import nftContractAbi from "../contracts/abi/nft-contract-abi.json";
import auctionContractAbi from "../contracts/abi/auction-contract-abi.json";
import erc20ContractAbi from "../contracts/abi/erc20-contract-abi.json";

export const NFT_CONTRACT_ADDRESS = process.env
  .NEXT_PUBLIC_NFT_CONTRACT_ADDRESS as `0x${string}`;

export const AUCTION_CONTRACT_ADDRESS = process.env
  .NEXT_PUBLIC_AUCTION_CONTRACT_ADDRESS as `0x${string}`;

export const USDC_CONTRACT_ADDRESS = process.env
  .NEXT_PUBLIC_USDC_CONTRACT_ADDRESS as `0x${string}`;

export const PINATA_API_KEY = process.env.NEXT_PUBLIC_PINATA_API_KEY;
export const PINATA_SECRET_API_KEY =
  process.env.NEXT_PUBLIC_PINATA_SECRET_API_KEY;
export const PINATA_JWT = process.env.NEXT_PUBLIC_PINATA_JWT;
export const PINATA_GATEWAY = process.env.NEXT_PUBLIC_PINATA_GATEWAY;

export const ERC20_CONTRACT_ABI = erc20ContractAbi;
export const NFT_CONTRACT_ABI = nftContractAbi;
export const AUCTION_CONTRACT_ABI = auctionContractAbi;
