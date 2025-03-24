import MerkleTree from "merkletreejs";
import { keccak256 } from "viem";

export const generateMerkleProof = (address: string, addresses: string[]) => {
  const leaves = addresses.map((addr) => keccak256(addr as `0x${string}`));
  const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
  const proof = tree.getHexProof(keccak256(address as `0x${string}`));
  return proof;
};

export function generateMerkleRoot(addresses: string[]) {
  const leaves = addresses.map((addr) => keccak256(addr as `0x${string}`));
  const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
  return tree.getHexRoot();
}
