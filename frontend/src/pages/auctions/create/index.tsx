"use client";

import React, { useEffect, useState, useMemo } from "react";
import { useRouter } from "next/navigation";
import BigNumber from "bignumber.js";
import toast from "react-hot-toast";
import { useWaitForTransactionReceipt, useWriteContract } from "wagmi";
import Loader from "../../../components/Loader";
import {
  NFT_CONTRACT_ADDRESS,
  NFT_CONTRACT_ABI,
  AUCTION_CONTRACT_ADDRESS,
  AUCTION_CONTRACT_ABI,
} from "../../../utils/constants";
import { formatPriceInWei } from "../../../utils/format";
import { useNFTContract } from "../../../hooks/useNFTContract";

const CreateAuction = () => {
  const router = useRouter();
  const { myNftIds, isApproved, refetchIsApproved } = useNFTContract({
    fetchMyNftIds: true,
    fetchIsApproved: true,
  });
  const [selectedNFT, setSelectedNFT] = useState("");
  const [endDate, setEndDate] = useState<string>("");
  const [startingPrice, setStartingPrice] = useState("");

  // Create Auction Transaction
  const { writeContract: writeCreateAuction, data: createAuctionHash } =
    useWriteContract();

  const {
    isLoading: isCreateAuctionLoading,
    isSuccess: isCreateAuctionSuccess,
    isError: isCreateAuctionError,
  } = useWaitForTransactionReceipt({
    hash: createAuctionHash,
  });

  // Approve NFT Transaction
  const { writeContract: writeApprove, data: approveHash } = useWriteContract();

  const {
    isLoading: isApproveLoading,
    isSuccess: isApproveSuccess,
    isError: isApproveError,
  } = useWaitForTransactionReceipt({
    hash: approveHash,
  });

  // Combine all transaction states into a single memoized object
  const transactionStates = useMemo(
    () => ({
      createAuction: {
        loading: isCreateAuctionLoading,
        success: isCreateAuctionSuccess,
        error: isCreateAuctionError,
      },
      approve: {
        loading: isApproveLoading,
        success: isApproveSuccess,
        error: isApproveError,
      },
    }),
    [
      isCreateAuctionLoading,
      isCreateAuctionSuccess,
      isCreateAuctionError,
      isApproveLoading,
      isApproveSuccess,
      isApproveError,
    ]
  );

  const handleCreateAuction = () => {
    const selectedDateTime = Math.floor(new Date(endDate).getTime() / 1000);
    const currentTime = Math.floor(new Date().getTime() / 1000);
    const durationInSeconds = selectedDateTime - currentTime;

    if (durationInSeconds <= 0) {
      toast.error("End date and time must be in the future.");
      return;
    }

    if (selectedNFT && durationInSeconds && startingPrice) {
      const confirmed = window.confirm(
        `Are you sure you want to create an auction for NFT #${Number(
          selectedNFT
        )}?\n\n` +
          `Starting Price: ${startingPrice} ETH\n` +
          `Duration: ${Math.floor(durationInSeconds / 3600)} hours ${Math.floor(
            (durationInSeconds % 3600) / 60
          )} minutes\n\n`
      );

      if (confirmed) {
        writeCreateAuction({
          address: AUCTION_CONTRACT_ADDRESS,
          abi: AUCTION_CONTRACT_ABI,
          functionName: "createAuction",
          args: [
            selectedNFT,
            BigNumber(formatPriceInWei(startingPrice)),
            durationInSeconds,
          ],
        });
      }
    }
  };

  const handleApprove = () => {
    writeApprove({
      address: NFT_CONTRACT_ADDRESS,
      abi: NFT_CONTRACT_ABI,
      functionName: "setApprovalForAll",
      args: [AUCTION_CONTRACT_ADDRESS, true],
    });
  };

  useEffect(() => {
    if (
      transactionStates.createAuction.loading ||
      transactionStates.approve.loading
    ) {
      toast.loading("Transaction pending...", { id: "txn" });
      return;
    }

    if (transactionStates.approve.success) {
      refetchIsApproved();
      toast.success("Transaction confirmed! 🎉", { id: "txn" });
      return;
    }

    if (transactionStates.createAuction.success) {
      router.push("/auctions");
      toast.success("Transaction confirmed! 🎉", { id: "txn" });
      return;
    }

    if (
      transactionStates.createAuction.error ||
      transactionStates.approve.error
    ) {
      toast.error("Transaction failed! ❌", { id: "txn" });
      return;
    }
  }, [transactionStates, router]);

  return (
    <div className="p-6 pt-16 w-1/2 mx-auto">
      <h2 className="text-4xl font-bold mb-6">Create Auction</h2>
      <label className="block mb-2 text-lg">Select NFT:</label>
      <select
        value={selectedNFT}
        onChange={(e) => setSelectedNFT(e.target.value)}
        className="w-full p-3 rounded-lg bg-gray-800 border border-gray-700 text-white"
      >
        <option value="">Select an NFT</option>
        {(myNftIds as string[])?.map((tokenId: string, index: number) => (
          <option key={index} value={tokenId}>
            {`NFT #${Number(tokenId)}`}
          </option>
        ))}
      </select>

      <label className="block mb-2 text-lg mt-4">End Date and Time:</label>
      <input
        type="datetime-local"
        value={endDate}
        onChange={(e) => setEndDate(e.target.value)}
        className="w-full p-3 rounded-lg bg-gray-800 border border-gray-700 text-white"
      />

      <label className="block mb-2 text-lg mt-4">Starting Price (ETH):</label>
      <input
        type="number"
        value={startingPrice}
        onChange={(e) => setStartingPrice(e.target.value)}
        className="w-full p-3 rounded-lg bg-gray-800 border border-gray-700 text-white"
        placeholder="Enter starting price"
      />

      {isApproved ? (
        <button
          type="submit"
          onClick={handleCreateAuction}
          disabled={
            !selectedNFT || !endDate || !startingPrice || isCreateAuctionLoading
          }
          className={`mt-8 w-full bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-3 px-6 rounded-lg transition duration-300 ${
            !selectedNFT || !endDate || !startingPrice || isCreateAuctionLoading
              ? "opacity-50 cursor-not-allowed"
              : "cursor-pointer"
          }`}
        >
          {isCreateAuctionLoading ? (
            <div className="flex items-center justify-center">
              <Loader />
            </div>
          ) : (
            "Create Auction"
          )}
        </button>
      ) : (
        <button
          disabled={isApproveLoading}
          onClick={handleApprove}
          className={`mt-8 w-full bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-3 px-6 rounded-lg transition duration-300 cursor-pointer ${
            isApproveLoading
              ? "opacity-50 cursor-not-allowed"
              : "cursor-pointer"
          }`}
        >
          {isApproveLoading ? (
            <div className="flex items-center justify-center">
              <Loader />
            </div>
          ) : (
            "Approve NFT"
          )}
        </button>
      )}
    </div>
  );
};

export default CreateAuction;
