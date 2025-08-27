import { useAccount, useReadContract } from "wagmi";
import { auctionContract, nftContract } from "../contracts/contracts";

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
    fetchWhitelistedUsers?: boolean;
  },
  tokenAddress?: string
) => {
  const { address } = useAccount();

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
        args: [address],
        account: address,
      })
    : { data: null };

  const { data: whitelistedUsers, refetch: refetchWhitelistedUsers } = options?.fetchWhitelistedUsers
    ? useReadContract({
        address: nftContract.address,
        abi: nftContract.abi,
        functionName: "getWhitelistedUsers",
        account: address,
      })
    : { data: null };

  const { data: supportedTokens } = options?.fetchSupportedTokens
    ? useReadContract({
        address: nftContract.address,
        abi: nftContract.abi,
        functionName: "getSupportedTokensWithSymbols",
      })
    : { data: null };

  const { data: mintPriceInToken, refetch: refetchMintPriceInToken } =
    useReadContract({
      address: nftContract.address,
      abi: nftContract.abi,
      functionName: "getMintPriceInToken",
      args: [tokenAddress],
    });

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
    whitelistedUsers,
    refetchWhitelistedUsers,
    supportedTokens,
  };
};
