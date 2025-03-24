"use client";

import React, { useEffect } from "react";
import Image from "next/image";
import { useAccount } from "wagmi";
import { formatAddress, formatPriceInETH } from "../../utils/format";
import { useRouter } from "next/router";
import { useNFTContract } from "../../hooks/useNFTContract";
import { useAuctionContract } from "../../hooks/useAuctionContract";
import { IBid } from "../../utils/types";

const UserProfile: React.FC = () => {
  const router = useRouter();
  const { address, isConnected } = useAccount();

  const { nfts } = useNFTContract({ fetchNFTsOfOwner: true });
  const { bids } = useAuctionContract({ fetchBids: true });

  useEffect(() => {
    if (!isConnected) {
      router.push("/");
    }
  }, [isConnected]);

  return (
    <div className="bg-gray-900 text-white p-6 pt-16 flex gap-16">
      {/* User Profile Data on the Left */}
      <div className="w-1/3 flex flex-col gap-4 items-center mt-8">
        <Image
          width={50}
          height={50}
          src="/user-profile.png"
          alt="User Avatar"
          className="w-24 h-24 rounded-full border-2 border-gray-600 mx-auto"
        />
        <p className="text-lg mt-2">
          <strong>Test</strong>
        </p>
        <p className="text-lg">
          <strong>Test@gmail.com</strong>
        </p>
        <p className="text-lg">
          <strong>Software Developer</strong>
        </p>
        <p className="text-lg text-center">
          <strong>{formatAddress(address as string)}</strong>
        </p>
      </div>
      {/* Other Sections on the Right */}
      <div className="w-full flex flex-col gap-12 max-w-4xl">
        <div>
          <h2 className="text-2xl font-semibold">My NFTs</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mt-2">
            {(nfts as number[])?.length > 0 ? (
              (nfts as number[])?.map((nft: number) => (
                <div
                  key={nft}
                  className="bg-gray-800 p-4 rounded shadow flex flex-col gap-1"
                >
                  <Image
                    width={100}
                    height={50}
                    src="/ticket.jpeg"
                    alt={`NFT #${nft}`}
                    className="w-full h-32 object-cover rounded"
                  />
                  <h3 className="text-xl font-bold">{`NFT #${Number(nft)}`}</h3>
                </div>
              ))
            ) : (
              <div className="bg-gray-800 w-40 px-4 py-2">
                <h5 className="font-bold">No NFTs found</h5>
              </div>
            )}
          </div>
        </div>
        <div>
          <h2 className="text-2xl font-semibold">My Bids</h2>
          <div className="overflow-x-auto mt-4">
            {(bids as IBid[])?.length > 0 ? (
              <table className="w-full bg-gray-800 rounded">
                <thead className="bg-gray-700">
                  <tr>
                    <th className="py-2 px-4 text-left">Auction</th>
                    <th className="py-2 px-4 text-center">Bid Amount</th>
                    <th className="py-2 px-4 text-right">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {(bids as IBid[])?.map((bid: IBid, index: number) => (
                    <tr key={index}>
                      <td className="py-2 px-4">{`Auction #${bid.auctionId}`}</td>
                      <td className="py-2 px-4 text-center">{`${formatPriceInETH(
                        bid.bidAmount.toString()
                      )} ETH`}</td>
                      <td className="py-2 px-4 text-right">{`${
                        bid.endTime > Date.now() / 1000 ? "Active" : "Ended"
                      }`}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : (
              <div className="bg-gray-800 w-40 px-4 py-2">
                <h5 className="font-bold">No Bids found</h5>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default UserProfile;
