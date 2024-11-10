// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IInterestRateModel {
    function calculateInterestRate(
        uint256 totalBorrows,
        uint256 totalDeposits
    ) external view returns (uint256);
}
