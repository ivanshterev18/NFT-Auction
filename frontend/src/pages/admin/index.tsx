"use client";

import React, { useEffect, useState, useMemo } from "react";
import { useRouter } from "next/navigation";
import toast from "react-hot-toast";
import {
  useWriteContract,
  useWaitForTransactionReceipt,
  useAccount,
} from "wagmi";
import { NFT_CONTRACT_ADDRESS, NFT_CONTRACT_ABI } from "../../utils/constants";
import { formatPriceInETH, formatPriceInWei } from "../../utils/format";
import { useNFTContract } from "../../hooks/useNFTContract";

const AdminPanel = () => {
  const router = useRouter();
  const { isConnected } = useAccount();

  const {
    mintPrice,
    refetchMintPrice,
    isAdmin,
    isAdminLoading,
    whitelistedUsers,
    refetchWhitelistedUsers,
  } = useNFTContract({
    fetchIsAdmin: true,
    fetchMintPrice: true,
    fetchWhitelistedUsers: true,
  });

  const [addressToWhitelist, setAddressToWhitelist] = useState("");

  const [nftMintPrice, setNftMintPrice] = useState("");

  const [symbol, setSymbol] = useState("");
  const [tokenAddress, setTokenAddress] = useState("");
  const [priceAddress, setPriceAddress] = useState("");

  // Set NFT Price
  const { writeContract: setPrice, data: setPriceHash } = useWriteContract();

  // Wait for NFT Price transaction receipt
  const {
    isLoading: isSetPriceLoading,
    isSuccess: isSetPriceSuccess,
    isError: isSetPriceError,
  } = useWaitForTransactionReceipt({
    hash: setPriceHash,
  });

  // Add to Whitelist
  const { writeContract: addToWhitelist, data: addToWhitelistHash } =
    useWriteContract();

  // Wait for Add to Whitelist transaction receipt
  const {
    isLoading: isAddToWhitelistLoading,
    isSuccess: isAddToWhitelistSuccess,
    isError: isAddToWhitelistError,
  } = useWaitForTransactionReceipt({
    hash: addToWhitelistHash,
  });

  // Add Mint Currency
  const { writeContract: addMintCurrency, data: addMintCurrencyHash } =
    useWriteContract();

  // Wait for NFT Price transaction receipt
  const {
    isLoading: isAddMintCurrencyLoading,
    isSuccess: isAddMintCurrencySuccess,
    isError: isAddMintCurrencyError,
  } = useWaitForTransactionReceipt({
    hash: addMintCurrencyHash,
  });

  const handleSetPrice = () => {
    setPrice({
      address: NFT_CONTRACT_ADDRESS,
      abi: NFT_CONTRACT_ABI,
      functionName: "setMintPrice",
      args: [formatPriceInWei(nftMintPrice)],
    });
  };

  const handleAddMintCurrency = () => {
    addMintCurrency({
      address: NFT_CONTRACT_ADDRESS,
      abi: NFT_CONTRACT_ABI,
      functionName: "setPriceFeed",
      args: [tokenAddress, priceAddress, symbol],
    });
  };

  const handleAddToWhitelist = () => {
    addToWhitelist({
      address: NFT_CONTRACT_ADDRESS,
      abi: NFT_CONTRACT_ABI,
      functionName: "addToWhitelist",
      args: [addressToWhitelist],
    });
  };

  const handleRemoveAddress = (addressToRemove: string) => {
    addToWhitelist({
      address: NFT_CONTRACT_ADDRESS,
      abi: NFT_CONTRACT_ABI,
      functionName: "removeFromWhitelist",
      args: [addressToRemove],
    });
  };

  useEffect(() => {
    if ((!isAdminLoading && !isAdmin) || !isConnected) {
      router.push("/");
    }
  }, [isAdmin, isConnected]);

  const transactionStates = useMemo(
    () => ({
      addToWhitelist: {
        loading: isAddToWhitelistLoading,
        success: isAddToWhitelistSuccess,
        error: isAddToWhitelistError,
      },
      setPrice: {
        loading: isSetPriceLoading,
        success: isSetPriceSuccess,
        error: isSetPriceError,
      },
      addCurrency: {
        loading: isAddMintCurrencyLoading,
        success: isAddMintCurrencySuccess,
        error: isAddMintCurrencyError,
      },
    }),
    [
      isAddToWhitelistLoading,
      isAddToWhitelistSuccess,
      isAddToWhitelistError,
      isSetPriceLoading,
      isSetPriceSuccess,
      isSetPriceError,
      isAddMintCurrencyLoading,
      isAddMintCurrencySuccess,
      isAddMintCurrencyError,
    ]
  );

  useEffect(() => {
    const { addToWhitelist, setPrice, addCurrency } = transactionStates;

    if (addToWhitelist.loading || setPrice.loading || addCurrency.loading) {
      toast.loading("Transaction pending...", { id: "txn" });
      return;
    }

    if (addToWhitelist.success) {
      toast.dismiss("txn");
      setAddressToWhitelist("");
      refetchWhitelistedUsers?.();
      toast.success("Whitelist updated! 🎉", { id: "whitelist" });
      return;
    }

    if (setPrice.success) {
      toast.dismiss("txn");
      setNftMintPrice("");
      refetchMintPrice();
      toast.success("Transaction confirmed! 🎉", { id: "setPrice" });
      return;
    }

    if (addCurrency.success) {
      toast.dismiss("txn");
      setTokenAddress("");
      setPriceAddress("");
      toast.success("Transaction confirmed! 🎉", { id: "addCurrency" });
      return;
    }

    if (addToWhitelist.error || setPrice.error || addCurrency.error) {
      toast.dismiss("txn");
      toast.error("Transaction failed! ❌", { id: "failed" });
      return;
    }
  }, [transactionStates, refetchMintPrice]);

  return isConnected ? (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-gray-900 via-black to-gray-800 p-6">
      <div className="max-w-3xl w-full bg-gray-950 bg-opacity-90 backdrop-blur-lg shadow-2xl border border-gray-800 rounded-2xl p-8 text-white">
        <h2 className="text-4xl font-bold mb-6 text-indigo-400 text-center">
          Admin Panel
        </h2>

        {/* Display Current Mint Price */}
        <div className="mb-4 flex items-center gap-2">
          <h3 className="text-2xl font-semibold text-indigo-400">
            Current Mint Price:
          </h3>
          <p className="text-lg text-gray-300">
            {formatPriceInETH(mintPrice as string)} ETH
          </p>
        </div>

        <label className="block mb-2 text-lg text-gray-300">
          Set NFT Price (ETH):
        </label>
        <input
          type="number"
          value={nftMintPrice}
          onChange={(e) => setNftMintPrice(e.target.value)}
          className="w-full p-3 rounded-lg bg-gray-800 border border-gray-700 text-white focus:ring-2 focus:ring-indigo-500 outline-none transition"
          placeholder="Enter price"
        />
        <button
          type="submit"
          disabled={!nftMintPrice}
          onClick={handleSetPrice}
          className={`mt-4 w-full ${
            !nftMintPrice
              ? "bg-gray-500 cursor-not-allowed"
              : "bg-indigo-600 hover:bg-indigo-500 cursor-pointer"
          } text-white font-semibold py-3 px-6 rounded-lg transition duration-300 shadow-md`}
        >
          Set Price
        </button>

        {/* Whitelist Management */}
        <div className="mb-8">
          <label className="block mt-2   mb-2 text-lg text-gray-300">
            Add Address to Whitelist:
          </label>
          <input
            type="text"
            value={addressToWhitelist}
            onChange={(e) => setAddressToWhitelist(e.target.value)}
            className="w-full p-3 rounded-lg bg-gray-800 border border-gray-700 text-white focus:ring-2 focus:ring-green-500 outline-none transition"
            placeholder="Enter wallet address"
          />
          <button
            disabled={
              !addressToWhitelist ||
              !addressToWhitelist.match(/^0x[a-fA-F0-9]{40}$/)?.length
            }
            onClick={handleAddToWhitelist}
            className={`mt-4 w-full ${
              !addressToWhitelist.match(/^0x[a-fA-F0-9]{40}$/)?.length
                ? "bg-gray-500 cursor-not-allowed"
                : "bg-green-600 hover:bg-green-500  cursor-pointer"
            } text-white font-semibold py-3 px-6 rounded-lg transition duration-300 shadow-md`}
          >
            Add to Whitelist
          </button>
        </div>

        {/* Whitelist Display */}
        <div>
          <h3 className="text-2xl font-semibold mb-4 text-indigo-400">
            Whitelisted Addresses:
          </h3>
          <div className="bg-gray-800 bg-opacity-75 p-4 rounded-lg border border-gray-700">
            {(whitelistedUsers as string[])?.length > 0 ? (
              <ul className="space-y-3">
                {(whitelistedUsers as string[])?.map((addr, index) => (
                  <div
                    className="flex items-center justify-between"
                    key={index}
                  >
                    <li className="p-3 bg-gray-700 rounded-lg text-gray-300 text-sm">
                      {addr}
                    </li>
                    <button
                      onClick={() => handleRemoveAddress(addr)}
                      className="bg-red-500 hover:bg-red-600 text-white font-semibold py-1 px-2 rounded-lg transition duration-300 shadow-md cursor-pointer"
                    >
                      Remove
                    </button>
                  </div>
                ))}
              </ul>
            ) : (
              <p className="text-gray-400 text-center">
                No addresses whitelisted yet.
              </p>
            )}
          </div>
        </div>

        {/* Add Currency Form */}
        <div className="mt-8 w-full">
          <h3 className="text-2xl font-semibold mb-4 text-indigo-400">
            Add Currency:
          </h3>
          <label className="block mb-2 text-lg text-gray-300">Symbol:</label>
          <input
            type="text"
            value={symbol}
            onChange={(e) => setSymbol(e.target.value)}
            className="w-full p-3 rounded-lg bg-gray-800 border border-gray-700 text-white focus:ring-2 focus:ring-indigo-500 outline-none transition"
            placeholder="Enter token symbol"
          />
          <label className="block mb-2 text-lg text-gray-300  mt-4">
            Token Address:
          </label>
          <input
            type="text"
            value={tokenAddress}
            onChange={(e) => setTokenAddress(e.target.value)}
            className="w-full p-3 rounded-lg bg-gray-800 border border-gray-700 text-white focus:ring-2 focus:ring-indigo-500 outline-none transition"
            placeholder="Enter token address"
          />
          <label className="block mb-2 text-lg text-gray-300 mt-4">
            Price Feed Address:
          </label>
          <input
            type="text"
            value={priceAddress}
            onChange={(e) => setPriceAddress(e.target.value)}
            className="w-full p-3 rounded-lg bg-gray-800 border border-gray-700 text-white focus:ring-2 focus:ring-indigo-500 outline-none transition"
            placeholder="Enter price address"
          />
          <button
            type="submit"
            onClick={handleAddMintCurrency}
            disabled={!tokenAddress || !priceAddress}
            className={`mt-8 w-full ${
              !tokenAddress || !priceAddress
                ? "bg-gray-500 cursor-not-allowed"
                : "bg-indigo-600 hover:bg-indigo-500 cursor-pointer"
            } text-white font-semibold py-3 px-6 rounded-lg transition duration-300 shadow-md`}
          >
            Add Currency
          </button>
        </div>
      </div>
    </div>
  ) : (
    // Not Found Page
    <></>
  );
};

export default AdminPanel;
