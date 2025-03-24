import { create } from "zustand";
import { persist } from "zustand/middleware";
import { pinata } from "../config/pinata";

interface Web3Store {
  whitelist: string[];
  setWhitelist: (newWhitelist: string[]) => void;
  fetchWhitelist: () => Promise<void>;
}

export const useWeb3Store = create<Web3Store>()(
  persist(
    (set) => ({
      whitelist: [],
      setWhitelist: async (newWhitelist: string[]) => {
        set({ whitelist: newWhitelist });
        localStorage.setItem("whitelist", JSON.stringify(newWhitelist));
      },
      fetchWhitelist: async () => {
        try {
          let currentCid = localStorage.getItem("cid");

          if (!currentCid) {
            currentCid = (await pinata.files.public.list().order("ASC"))
              ?.files[0]?.cid;
            if (currentCid) {
              localStorage.setItem("cid", currentCid);
            }
          }

          if (currentCid) {
            const result = await pinata?.gateways?.public?.get(currentCid);
            const fetchedWhitelist = result?.data || [];

            set({ whitelist: fetchedWhitelist as string[] });
            localStorage.setItem("whitelist", JSON.stringify(fetchedWhitelist));
          }
        } catch (error) {
          console.error("Error fetching whitelist:", error);
        }
      },
    }),
    { name: "web3-storage" }
  )
);

let hasFetched = false;

if (typeof window !== "undefined" && !hasFetched) {
  hasFetched = true;
  useWeb3Store.getState().fetchWhitelist();
}
