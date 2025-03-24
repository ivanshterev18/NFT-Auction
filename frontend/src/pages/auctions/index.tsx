"use client";

import React, { useEffect, useState } from "react";
import {
  useAccount,
  useReadContract,
  useWaitForTransactionReceipt,
  useWriteContract,
} from "wagmi";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useRouter } from "next/navigation";
import {
  NFT_CONTRACT_ADDRESS,
  NFT_CONTRACT_ABI,
  USDC_CONTRACT_ADDRESS,
  ERC20_CONTRACT_ABI,
} from "../../utils/constants";
import {
  formatPriceInETH,
  formatPriceInWei,
  formatTimeDifference,
} from "../../utils/format";
import toast from "react-hot-toast";
import Link from "next/link";
import Image from "next/image";
import { generateMerkleProof } from "../../utils/merkle";
import { useWeb3Store } from "../../stores/useWeb3Store";
import { useNFTContract } from "../../hooks/useNFTContract";
import { useAuctionContract } from "../../hooks/useAuctionContract";
import { IAuction, SupportedTokens } from "../../utils/types";

export default function Auctions() {
  const router = useRouter();
  const { address, isConnected } = useAccount();
  const whitelist = useWeb3Store((state) => state.whitelist);
  const [selectedToken, setSelectedToken] = useState<SupportedTokens>({
    symbol: "ETH",
    address: "",
  });
  const {
    mintPrice,
    isWhitelisted,
    supportedTokens,
    mintPriceInToken,
    refetchMintPriceInToken,
  } = useNFTContract(
    {
      fetchMintPriceInToken: true,
      fetchSupportedTokens: true,
      fetchIsWhitelisted: true,
      fetchMintPrice: true,
    },
    selectedToken.address
  );

  const { auctions } = useAuctionContract({
    fetchAuctions: true,
  });

  useEffect(() => {
    if (!isConnected) {
      router.push("/");
    }
  }, [isConnected, router]);

  if (!isConnected) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen bg-gray-900 text-white">
        <h1 className="text-3xl font-bold">Access Restricted</h1>
        <p className="mt-2 text-lg text-gray-400">
          Please connect your wallet to access the auctions.
        </p>
        <div className="mt-6">
          <ConnectButton />
        </div>
      </div>
    );
  }

  const { writeContract, data: hash } = useWriteContract();

  const { isLoading, isSuccess, isError, error } = useWaitForTransactionReceipt(
    {
      hash,
    }
  );

  const handleMintNFT = () => {
    if (selectedToken.symbol === "ETH") {
      writeContract({
        address: NFT_CONTRACT_ADDRESS,
        abi: NFT_CONTRACT_ABI,
        functionName: "mintNFT",
        args: [generateMerkleProof(address as string, whitelist)],
        value: BigInt(formatPriceInWei(formatPriceInETH(mintPrice as string))),
      });
    } else {
      writeContract({
        address: NFT_CONTRACT_ADDRESS,
        abi: NFT_CONTRACT_ABI,
        functionName: "mintNFTWithToken",
        args: [
          USDC_CONTRACT_ADDRESS,
          generateMerkleProof(address as string, whitelist),
        ],
      });
    }
  };

  const handleApprove = () => {
    writeContract({
      address: selectedToken.address as `0x${string}`,
      abi: ERC20_CONTRACT_ABI,
      functionName: "approve",
      args: [
        NFT_CONTRACT_ADDRESS,
        BigInt(
          formatPriceInWei(
            (
              Number(formatPriceInETH(mintPriceInToken as string)) * 1.2
            ).toString()
          )
        ),
      ],
    });
  };

  const { data: allowance, refetch: refetchAllowance } = useReadContract({
    address: selectedToken.address as `0x${string}`,
    abi: ERC20_CONTRACT_ABI,
    functionName: "allowance",
    args: [address, NFT_CONTRACT_ADDRESS],
  });

  useEffect(() => {
    if (isLoading) {
      toast.loading("Transaction pending...", { id: "txn" });
    }
    if (isSuccess) {
      refetchAllowance();
      toast.success("Transaction confirmed! 🎉", { id: "txn" });
    }
    if (isError) {
      toast.error(error?.message || "Transaction failed! ❌", { id: "txn" });
    }
  }, [isLoading, isSuccess, isError]);

  const isApproving =
    Number(formatPriceInETH(allowance?.toString())) <
      Number(formatPriceInETH(mintPriceInToken as string)) &&
    selectedToken.symbol !== "ETH";

  const nftPrice =
    selectedToken.symbol !== "ETH"
      ? Number(formatPriceInETH(mintPriceInToken as string)).toFixed(2)
      : formatPriceInETH(mintPrice as string);

  return (
    <div className="max-w-3xl mx-auto bg-gray-900 text-white p-6">
      <h1 className="text-4xl font-bold text-center">Auction Listings</h1>
      <p className="text-gray-400 text-center mt-2">
        Participate in live NFT auctions or create your own.
      </p>

      <div className="flex justify-center gap-4 mt-6">
        <Link
          href="/auctions/create"
          className="bg-green-500 hover:bg-green-600 text-white px-4 py-2 rounded cursor-pointer"
        >
          Create Auction
        </Link>

        {/* Only show mint button if the logged in user is whitelisted */}
        {!!isWhitelisted && (
          <div className="flex gap-2">
            <div className="flex gap-2">
              <button
                disabled={isLoading}
                onClick={isApproving ? handleApprove : handleMintNFT}
                className="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded cursor-pointer"
              >
                {isLoading
                  ? "Transaction processing..."
                  : `${isApproving ? "Approve" : "Mint NFT"} (${
                      Number(nftPrice) === 0 ? "Free" : nftPrice
                    }${
                      Number(nftPrice) > 0 ? " " + selectedToken.symbol : ""
                    })`}
              </button>
              <select
                value={selectedToken.symbol}
                onChange={(e) => {
                  setSelectedToken({
                    symbol: e.target.value as string,
                    address: (supportedTokens as SupportedTokens[])?.find(
                      (token: SupportedTokens) =>
                        token.symbol === e.target.value
                    )?.address as string,
                  });
                  refetchMintPriceInToken();
                }}
                className="bg-gray-800 border border-gray-700 text-white p-2 rounded-lg"
              >
                {[
                  { symbol: "ETH" },
                  ...((supportedTokens as SupportedTokens[]) || []),
                ]?.map((token: SupportedTokens | { symbol: string }) => (
                  <option key={token.symbol} value={token.symbol}>
                    {token.symbol}
                  </option>
                ))}
              </select>
            </div>
          </div>
        )}
      </div>

      <div className="mt-8">
        <h2 className="text-2xl font-semibold">Live Auctions</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-3 gap-6 mt-4">
          {(auctions as IAuction[])?.map((auction: IAuction) => (
            <div
              key={auction.id}
              className="bg-gray-800 p-4 rounded shadow h-80 flex flex-col gap-2 h-88"
            >
              <Image
                width={0}
                height={0}
                sizes="100vw"
                src="/ticket.jpeg"
                alt="Auction Item"
                style={{ width: "100%", height: "180px" }}
              />
              <h3 className="text-xl font-bold">{`NFT #${auction.tokenId}`}</h3>
              <p className="text-gray-400">
                Ends in: {formatTimeDifference(Number(auction.endTime))}
              </p>
              <p className="text-gray-400">
                Highest Bid:{" "}
                {auction.highestBidAmount
                  ? formatPriceInETH(auction.highestBidAmount.toString())
                  : "No bids yet"}
              </p>
              <div className="text-center mt-auto flex">
                <Link
                  href={`/auctions/${auction.id}`}
                  className="bg-indigo-600 hover:bg-indigo-500 text-white px-4 py-2 rounded cursor-pointer w-full"
                >
                  See Details
                </Link>
              </div>
            </div>
          ))}
        </div>
        {!auctions && <p className="text-gray-400 ">No auctions found</p>}
      </div>
    </div>
  );
}
