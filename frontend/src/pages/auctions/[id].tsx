"use client";

import React, { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import Image from "next/image";
import {
  useAccount,
  useWaitForTransactionReceipt,
  useWriteContract,
} from "wagmi";
import toast from "react-hot-toast";
import { formatPriceInETH, formatPriceInWei } from "../../utils/format";
import { AUCTION_CONTRACT_ADDRESS } from "../../utils/constants";
import { AUCTION_CONTRACT_ABI } from "../../utils/constants";
import { TimerComponent } from "../../components/TimerComponent";
import { useAuctionContract } from "../../hooks/useAuctionContract";

export default function AuctionPage() {
  const { id } = useParams() || {};
  const { address } = useAccount();
  const { auction, refetchAuction } = useAuctionContract(
    { fetchAuction: true },
    id as string
  );

  const [bidAmount, setBidAmount] = useState(0);

  // Bid Transaction
  const { writeContract: bid, data: bidHash } = useWriteContract();

  const {
    isLoading: isBidLoading,
    isSuccess: isBidSuccess,
    isError: isBidError,
  } = useWaitForTransactionReceipt({
    hash: bidHash,
  });

  // Finalize Auction Transaction
  const { writeContract: finalize, data: finalizeHash } = useWriteContract();

  const {
    isLoading: isFinalizeLoading,
    isSuccess: isFinalizeSuccess,
    isError: isFinalizeError,
  } = useWaitForTransactionReceipt({
    hash: finalizeHash,
  });

  const handleBid = () => {
    bid({
      address: AUCTION_CONTRACT_ADDRESS,
      abi: AUCTION_CONTRACT_ABI,
      functionName: "bid",
      args: [id],
      value: BigInt(formatPriceInWei(bidAmount.toString())),
    });
  };

  const handleFinalize = () => {
    finalize({
      address: AUCTION_CONTRACT_ADDRESS,
      abi: AUCTION_CONTRACT_ABI,
      functionName: "finalizeAuction",
      args: [auction?.id],
    });
  };

  useEffect(() => {
    if (isBidLoading || isFinalizeLoading) {
      toast.loading("Transaction pending...", { id: "txn" });
    }
    if (isBidSuccess) {
      setBidAmount(0);
      refetchAuction();
      toast.success("Transaction successful", { id: "txn" });
    }
    if (isFinalizeSuccess) {
      refetchAuction();
      toast.success("Transaction successful", { id: "txn" });
    }
    if (isBidError || isFinalizeError) {
      toast.error("Transaction failed", { id: "txn" });
    }
  }, [
    isBidSuccess,
    isFinalizeSuccess,
    isBidError,
    isFinalizeError,
    isBidLoading,
    isFinalizeLoading,
  ]);

  const hasAuctionEnded = Number(auction?.endTime) < Date.now() / 1000;

  return (
    <div className="min-h-screen pt-16 flex justify-center bg-gradient-to-br from-gray-900 via-black to-gray-800 p-6">
      <div className="flex border border-gray-800 rounded-2xl h-full">
        <div className="w-1/2 p-8">
          <Image
            width={400}
            height={400}
            src="/ticket.jpeg"
            alt="Auction Item"
            className="rounded-lg"
          />
        </div>
        <div className="max-w-3xl w-full bg-gray-950 bg-opacity-90 backdrop-blur-lg shadow-2xl rounded-2xl p-8 text-white">
          <h1 className="text-2xl font-bold mb-6 text-indigo-400">
            Auction Details
          </h1>
          <div className="my-4">
            <p className="text-gray-100 font-semibold">
              NFT ID: #{auction?.tokenId}
            </p>
            <p className="text-gray-100 font-semibold flex gap-2">
              Ends in:{" "}
              {auction?.endTime && (
                <TimerComponent endTime={Number(auction?.endTime)} />
              )}
            </p>
            <p className="text-gray-100 font-semibold">
              Starting Price:{" "}
              {formatPriceInETH(auction?.reservePrice.toString())} ETH
            </p>
            <p className="text-gray-100">
              Current Highest Bid:{" "}
              {auction?.highestBidAmount
                ? `${formatPriceInETH(
                    auction?.highestBidAmount.toString()
                  )} ETH`
                : "No bids yet"}
            </p>
          </div>

          {/* Bid Form */}
          {auction?.endTime > Date.now() / 1000 && (
            <div className="my-6 flex gap-4 items-center">
              <input
                type="number"
                step="0.0001"
                value={bidAmount}
                placeholder="Enter your bid"
                onChange={(e) => setBidAmount(Number(e.target.value))}
                className="w-full p-3 rounded-lg bg-gray-800 border border-gray-700 text-white focus:ring-2 focus:ring-indigo-500 outline-none transition"
              />
              <button
                onClick={handleBid}
                disabled={
                  isBidLoading || bidAmount <= 0 || auction?.seller === address
                }
                className="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-3 px-6 rounded-lg transition duration-300 shadow-md disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
              >
                Bid
              </button>
            </div>
          )}

          {address === auction?.seller && !auction?.finalized && (
            <button
              disabled={isFinalizeLoading || !hasAuctionEnded}
              onClick={handleFinalize}
              className="mt-4 w-full bg-green-500 hover:bg-green-600 text-white font-semibold py-3 px-6 rounded-lg transition duration-300 shadow-md cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Finalize Auction
            </button>
          )}

          {(auction?.finalized ||
            (auction?.seller !== address && hasAuctionEnded)) && (
            <button className="mt-4 w-full bg-gray-500 text-white font-semibold py-3 px-6 rounded-lg transition duration-300 shadow-md cursor-not-allowed">
              Auction Ended
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
