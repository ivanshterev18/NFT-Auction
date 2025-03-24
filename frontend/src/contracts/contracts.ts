import {
  AUCTION_CONTRACT_ABI,
  ERC20_CONTRACT_ABI,
  NFT_CONTRACT_ABI,
  NFT_CONTRACT_ADDRESS,
  USDC_CONTRACT_ADDRESS,
} from "../utils/constants";

import { AUCTION_CONTRACT_ADDRESS } from "../utils/constants";

export const auctionContract = {
  abi: AUCTION_CONTRACT_ABI,
  address: AUCTION_CONTRACT_ADDRESS,
};

export const nftContract = {
  abi: NFT_CONTRACT_ABI,
  address: NFT_CONTRACT_ADDRESS,
};

export const usdcContract = {
  abi: ERC20_CONTRACT_ABI,
  address: USDC_CONTRACT_ADDRESS,
};
