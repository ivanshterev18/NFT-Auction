export interface IAuction {
  id: string;
  endTime: bigint;
  finalized: boolean;
  highestBidAmount: bigint;
  highestBidder: string;
  nftContract: string;
  reservePrice: bigint;
  seller: string;
  tokenId: bigint;
}

export type SupportedTokens = {
  symbol: string;
  address: string;
};

export interface IBid {
  auctionId: bigint;
  bidAmount: bigint;
  endTime: bigint;
}
