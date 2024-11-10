// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IInterestRateModel.sol";

contract InterestRateCalculator is IInterestRateModel {
    // Example calculation for an interest rate model based on utilization rate
    function calculateInterestRate(
        uint256 totalBorrows,
        uint256 totalDeposits
    ) external pure override returns (uint256) {
        if (totalDeposits == 0) return 0;

        uint256 utilizationRate = (totalBorrows * 1e18) / totalDeposits;

        // A simple interest rate model
        if (utilizationRate < 0.5e18) {
            return 2e16; // 2% annual interest
        } else if (utilizationRate < 0.9e18) {
            return 5e16; // 5% annual interest
        } else {
            return 1e17; // 10% annual interest
        }
    }
}
