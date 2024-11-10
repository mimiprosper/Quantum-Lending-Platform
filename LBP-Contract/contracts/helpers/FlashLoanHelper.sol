// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ILendingPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FlashLoanHelper {
    ILendingPool public lendingPool;

    // Event to notify when a flash loan operation completes
    event FlashLoanExecuted(
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium
    );

    constructor(address _lendingPoolAddress) {
        lendingPool = ILendingPool(_lendingPoolAddress);
    }

    // Function to request a flash loan with custom parameters
    function executeFlashLoanWithParams(
        address asset,
        uint256 amount,
        bytes memory params
    ) external {
        // Initiate a flash loan from the Aave lending pool
        lendingPool.flashLoan(
            address(this), // Receiver address (this contract)
            asset, // Asset to be borrowed
            amount, // Amount to borrow
            params // Additional parameters passed as bytes
        );
    }

    // Callback function called by Aave after the flash loan is issued
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata // params
    ) external returns (bool) {
        // Ensure only the lending pool contract can call this function
        require(msg.sender == address(lendingPool), "Invalid lender");

        // Custom flash loan logic can be implemented here
        // Example: Use the borrowed amount for arbitrage, collateral swap, etc.

        // Repay the flash loan with the required premium (interest)
        uint256 totalRepayment = amount + premium;
        IERC20(asset).approve(address(lendingPool), totalRepayment);

        // Emit an event to log the flash loan execution details
        emit FlashLoanExecuted(initiator, asset, amount, premium);

        return true;
    }
}
