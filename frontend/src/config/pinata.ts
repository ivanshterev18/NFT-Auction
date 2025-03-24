// This file configures the Pinata SDK for IPFS file uploads which is used to keep track of the whitelist.

import { PinataSDK } from "pinata";
import { PINATA_GATEWAY, PINATA_JWT } from "../utils/constants";

export const pinata = new PinataSDK({
  pinataJwt: PINATA_JWT,
  pinataGateway: PINATA_GATEWAY,
});

export async function upload(updatedWhitelist: string[]) {
  const formData = new FormData();

  const file = new File([JSON.stringify(updatedWhitelist)], "whitelist.json", {
    type: "application/json",
  });

  formData.append("file", file);

  formData.append("network", "public");

  const request = await fetch("https://uploads.pinata.cloud/v3/files", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${PINATA_JWT}`,
    },
    body: formData,
  });
  return await request.json();
}

export const refreshIpfsUploadedData = async (updatedWhitelist: string[]) => {
  const {
    data: { cid },
  } = await upload(updatedWhitelist);
  localStorage.setItem("cid", cid);
};
