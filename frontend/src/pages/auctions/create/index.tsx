"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import BigNumber from "bignumber.js";
import toast from "react-hot-toast";
import { useWaitForTransactionReceipt, useWriteContract } from "wagmi";
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
  const { myNftIds, isApproved, refetchIsApproved } = useNFTContract();
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

  const handleCreateAuction = () => {
    const selectedDateTime = Math.floor(new Date(endDate).getTime() / 1000);
    const currentTime = Math.floor(new Date().getTime() / 1000);

    if (selectedDateTime < currentTime) {
      toast.error("End date and time must be in the future.");
      return;
    }

    if (selectedNFT && selectedDateTime && startingPrice) {
      writeCreateAuction({
        address: AUCTION_CONTRACT_ADDRESS,
        abi: AUCTION_CONTRACT_ABI,
        functionName: "createAuction",
        args: [
          selectedNFT,
          BigNumber(formatPriceInWei(startingPrice)),
          BigNumber(selectedDateTime),
        ],
      });
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
    if (isCreateAuctionLoading || isApproveLoading) {
      toast.loading("Transaction pending...", { id: "txn" });
    }

    if (isApproveSuccess) {
      refetchIsApproved();
      toast.success("Transaction confirmed! 🎉", { id: "txn" });
    }

    if (isCreateAuctionSuccess) {
      router.push("/auctions");
      toast.success("Transaction confirmed! 🎉", { id: "txn" });
    }

    if (isCreateAuctionError || isApproveError) {
      toast.error("Transaction failed! ❌", { id: "txn" });
    }
  }, [
    isCreateAuctionLoading,
    isApproveLoading,
    isApproveSuccess,
    isCreateAuctionSuccess,
    isApproveError,
    isCreateAuctionError,
  ]);

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
          Create Auction
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
          Approve NFT
        </button>
      )}
    </div>
  );
};

export default CreateAuction;
