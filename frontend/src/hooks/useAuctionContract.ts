import { useAccount, useReadContract } from "wagmi";
import { useMemo } from "react";
import { AUCTION_CONTRACT_ADDRESS } from "../utils/constants";
import { AUCTION_CONTRACT_ABI } from "../utils/constants";
import { IAuction } from "../utils/types";

export const useAuctionContract = (
  options?: {
    fetchAuction?: boolean;
    fetchAuctions?: boolean;
    fetchBids?: boolean;
  },
  id?: string
) => {
  const { address } = useAccount();

  const { data: auction, refetch: refetchAuction } = options?.fetchAuction
    ? useReadContract({
        address: AUCTION_CONTRACT_ADDRESS,
        abi: AUCTION_CONTRACT_ABI,
        functionName: "getAuction",
        args: [id],
      })
    : { data: null, refetch: () => {} };

  const auctionsContractConfig = useMemo(
    () => ({
      address: AUCTION_CONTRACT_ADDRESS,
      abi: AUCTION_CONTRACT_ABI,
      functionName: "getAuctions" as const,
    }),
    []
  );

  const { data: auctions } = options?.fetchAuctions
    ? useReadContract(auctionsContractConfig)
    : { data: null };

  const { data: bids } = options?.fetchBids
    ? useReadContract({
        address: AUCTION_CONTRACT_ADDRESS,
        abi: AUCTION_CONTRACT_ABI,
        functionName: "getMyBids",
        account: address,
      })
    : { data: null };

  return {
    auction: auction as IAuction,
    auctions,
    bids,
    refetchAuction,
  };
};
