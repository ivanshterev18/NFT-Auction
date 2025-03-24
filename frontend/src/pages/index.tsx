import React from "react";
import { useAccount } from "wagmi";
import Auctions from "./auctions";

export default function Home() {
  const { isConnected } = useAccount();

  return (
    <div className="flex flex-col items-center min-h-screen bg-gray-900 text-white pt-16">
      <h1 className="text-4xl font-bold">Welcome to Our NFT Platform</h1>
      <p className="mt-2 text-lg text-gray-400">
        {isConnected
          ? "Explore the live auctions below."
          : "Connect your wallet to start using the app."}
      </p>

      {isConnected && (
        <div className="mt-6 w-full max-w-3xl">
          <Auctions />
        </div>
      )}
    </div>
  );
}
