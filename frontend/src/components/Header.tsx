import React from "react";
import { useAccount } from "wagmi";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import Link from "next/link";
import { useNFTContract } from "../hooks/useNFTContract";

export default function Header() {
  const { address } = useAccount();
  const { isAdmin } = useNFTContract({ fetchIsAdmin: true });

  return (
    <header className="bg-gray-800 text-white p-4 flex justify-between items-center">
      <Link href="/">
        <h1 className="text-2xl font-bold cursor-pointer">
          NFT Auction Platform
        </h1>
      </Link>
      <div className="flex gap-4">
        {!!isAdmin && (
          <Link href="/admin">
            <button className="bg-blue-500 text-white p-2 rounded-2xl cursor-pointer">
              Admin Panel
            </button>
          </Link>
        )}
        {!!address && (
          <Link href="/profile">
            <button className="bg-blue-500 w-24 text-white p-2 rounded-2xl cursor-pointer">
              My Profile
            </button>
          </Link>
        )}
        <ConnectButton />
      </div>
    </header>
  );
}
