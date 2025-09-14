
import { Drosera } from "drosera";
import { ethers } from "ethers";
import NFTWashTradeSentinel from "./src/NFTWashTradeSentinel.sol";

const provider = new ethers.providers.JsonRpcProvider("http://localhost:8545");

const drosera = new Drosera({
  provider,
});

const sentinel = drosera.sentinel({
  abi: NFTWashTradeSentinel.abi,
  address: "0x5FbDB2315678afecb367f032d93F642f64180aa3", // Replace with your deployed sentinel address
});

sentinel.on("alert", (data) => {
  console.log("Wash trade detected!", data);
});

console.log("Listening for NFT wash trade alerts...");
