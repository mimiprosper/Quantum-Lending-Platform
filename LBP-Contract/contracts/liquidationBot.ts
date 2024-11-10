import { ethers } from "ethers";
import * as dotenv from "dotenv";
dotenv.config();

// Load environment variables
const INFURA_RPC_URL = process.env.INFURA_RPC_URL || "";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";

if (!INFURA_RPC_URL || !PRIVATE_KEY) {
    throw new Error("Please set INFURA_RPC_URL and PRIVATE_KEY in your .env file");
}

const provider = new ethers.providers.JsonRpcProvider(INFURA_RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

// Contract Addresses and ABI
const lendingPoolAddress = "0x..."; // Replace with the LendingPool contract address
const lendingPoolABI = [ /* LendingPool contract ABI with UserEligibleForLiquidation event */ ];

// Contract instance
const lendingPoolContract = new ethers.Contract(lendingPoolAddress, lendingPoolABI, wallet);

// Main function to listen for events and trigger liquidation
async function main() {
    console.log("Listening for liquidation events...");

    // Listen for the UserEligibleForLiquidation event
    lendingPoolContract.on("UserEligibleForLiquidation", async (user: string, asset: string, debt: ethers.BigNumber) => {
        console.log(`Eligible user detected for liquidation: ${user}`);

        // Optional: Verify eligibility by fetching health factor
        const healthFactor = await lendingPoolContract.getHealthFactor(user);
        if (healthFactor.gte(ethers.utils.parseEther("1"))) {
            console.log("User's health factor is sufficient, skipping liquidation");
            return;
        }

        // Execute liquidation
        try {
            const tx = await lendingPoolContract.liquidate(
                user,
                asset,         // collateralAsset
                asset,         // debtAsset (assuming debt is the same asset for simplicity)
                debt,          // debtToCover
            );
            console.log(`Liquidation transaction sent: ${tx.hash}`);
            await tx.wait();
            console.log("Liquidation successful");
        } catch (error) {
            console.error("Error during liquidation transaction:", error);
        }
    });
}

main().catch((error) => {
    console.error("Error starting bot:", error);
    process.exit(1);
});


// import { ethers } from "ethers";
// import LiquidationManager from "./build/contracts/LiquidationManager.json";

// const provider = new ethers.providers.JsonRpcProvider("<RPC_URL>");
// const wallet = new ethers.Wallet("<PRIVATE_KEY>", provider);
// const contract = new ethers.Contract("<LIQUIDATION_MANAGER_ADDRESS>", LiquidationManager.abi, wallet);

// async function monitorLiquidationEvents() {
//   contract.on("UserEligibleForLiquidation", async (user, asset) => {
//     console.log(`User ${user} is eligible for liquidation.`);
//     await contract.liquidatePosition(user, asset);
//   });
// }

// monitorLiquidationEvents();

