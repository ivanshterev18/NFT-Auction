import React from "react";
import { WagmiProvider } from "wagmi";
import { Toaster } from "react-hot-toast";
import type { AppProps } from "next/app";
import { RainbowKitProvider } from "@rainbow-me/rainbowkit";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { config } from "../config/wagmi";
import Layout from "../components/Layout";
import "@rainbow-me/rainbowkit/styles.css";
import "../styles/globals.css";

const client = new QueryClient();

function MyApp({ Component, pageProps }: AppProps) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={client}>
        <RainbowKitProvider>
          <Toaster
            position="top-right"
            containerStyle={{
              marginTop: "72px",
            }}
            toastOptions={{
              loading: {
                style: {
                  background: "lightblue",
                },
              },
              success: {
                style: {
                  background: "green",
                  color: "white",
                },
              },
              error: {
                style: {
                  background: "red",
                  color: "white",
                },
              },
            }}
          />
          <Layout>
            <Component {...pageProps} />
          </Layout>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}

export default MyApp;
