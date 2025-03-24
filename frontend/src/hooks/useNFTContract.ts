import { useAccount, useReadContract } from "wagmi";
import { auctionContract, nftContract } from "../contracts/contracts";
import { generateMerkleProof } from "../utils/merkle";
import { useWeb3Store } from "../stores/useWeb3Store";

export const useNFTContract = (
  options?: {
    fetchMintPrice?: boolean;
    fetchIsAdmin?: boolean;
    fetchMyNftIds?: boolean;
    fetchIsApproved?: boolean;
    fetchIsWhitelisted?: boolean;
    fetchSupportedTokens?: boolean;
    fetchMintPriceInToken?: boolean;
    fetchNFTsOfOwner?: boolean;
  },
  tokenAddress?: string
) => {
  const { address } = useAccount();
  const whitelist = useWeb3Store((state) => state.whitelist);

  const { data: mintPrice, refetch: refetchMintPrice } = options?.fetchMintPrice
    ? useReadContract({
        address: nftContract.address,
        abi: nftContract.abi,
        functionName: "mintPrice",
      })
    : { data: null, refetch: () => {} };

  const { data: isAdmin, isLoading: isAdminLoading } = options?.fetchIsAdmin
    ? useReadContract({
        address: nftContract.address,
        abi: nftContract.abi,
        functionName: "isAdmin",
        args: [address],
      })
    : { data: null, isLoading: false };

  const { data: myNftIds } = options?.fetchMyNftIds
    ? useReadContract({
        address: nftContract.address,
        abi: nftContract.abi,
        functionName: "getNFTsOfOwner",
        args: [address],
      })
    : { data: null };

  const { data: isApproved, refetch: refetchIsApproved } =
    options?.fetchIsApproved
      ? useReadContract({
          address: nftContract.address,
          abi: nftContract.abi,
          functionName: "isApprovedForAll",
          args: [address, auctionContract.address],
        })
      : { data: null, refetch: () => {} };

  const { data: isWhitelisted } = options?.fetchIsWhitelisted
    ? useReadContract({
        address: nftContract.address,
        abi: nftContract.abi,
        functionName: "isWhitelisted",
        args: [generateMerkleProof((address as string) || "", whitelist)],
        account: address,
      })
    : { data: null };

  const { data: supportedTokens } = options?.fetchSupportedTokens
    ? useReadContract({
        address: nftContract.address,
        abi: nftContract.abi,
        functionName: "getSupportedTokens",
      })
    : { data: null };

  const { data: mintPriceInToken, refetch: refetchMintPriceInToken } =
    options?.fetchMintPriceInToken && tokenAddress
      ? useReadContract({
          address: nftContract.address,
          abi: nftContract.abi,
          functionName: "getMintPriceInToken",
          args: [tokenAddress],
        })
      : { data: null, refetch: () => {} };

  const { data: nfts } = options?.fetchNFTsOfOwner
    ? useReadContract({
        address: nftContract.address,
        abi: nftContract.abi,
        functionName: "getNFTsOfOwner",
        args: [address],
      })
    : { data: null };

  return {
    nfts,
    mintPrice,
    refetchMintPrice,
    mintPriceInToken,
    refetchMintPriceInToken,
    isAdmin,
    isAdminLoading,
    myNftIds,
    isApproved,
    refetchIsApproved,
    isWhitelisted,
    supportedTokens,
  };
};
