// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPriceOracleGetter.sol";
import "./interfaces/IProtocolDataProvider.sol";
import "./interfaces/ILendingPool.sol";

contract CollateralManager {
    ILendingPool public lendingPool;
    IProtocolDataProvider public dataProvider;
    IPriceOracleGetter public priceOracle;

    constructor(
        address _lendingPool,
        address _dataProvider,
        address _priceOracle
    ) {
        lendingPool = ILendingPool(_lendingPool);
        dataProvider = IProtocolDataProvider(_dataProvider);
        priceOracle = IPriceOracleGetter(_priceOracle);
    }

    /**
     * @notice Calculates the total collateral value of a user across all assets.
     * @param user The address of the user whose collateral is being calculated.
     * @return totalCollateralValue The total collateral value in ETH.
     */
    function getUserCollateralValue(
        address user
    ) external view returns (uint256 totalCollateralValue) {
        // Get the list of all assets in the lending pool
        address[] memory reserves = dataProvider.getAllReservesTokens();

        for (uint256 i = 0; i < reserves.length; i++) {
            address asset = reserves[i];

            // Get the user's collateral balance for each asset
            IProtocolDataProvider.UserReserveData memory userData = dataProvider
                .getUserReserveData(asset, user);

            // Skip if user has no collateral balance for this asset
            if (userData.currentATokenBalance == 0) {
                continue;
            }

            // Get the current price of the asset in ETH
            uint256 assetPrice = priceOracle.getAssetPrice(asset);

            // Calculate collateral value for this asset: balance * assetPrice
            uint256 collateralValue = userData.currentATokenBalance *
                assetPrice;

            // Accumulate the total collateral value
            totalCollateralValue += collateralValue;
        }
    }

    // Calculate the value of collateral in ETH
    function getCollateralValue(
        address asset,
        uint256 amount
    ) public view returns (uint256) {
        uint256 assetPrice = priceOracle.getAssetPrice(asset);
        return (amount * assetPrice) / 1e18;
    }

    // Calculate health factor
    function getHealthFactor(address user) external view returns (uint256) {
        (, , , , , uint256 healthFactor) = dataProvider.getUserAccountData(
            user
        );
        return healthFactor;
    }

    // Checks if user’s collateral is sufficient based on the required Loan-to-Value ratio
    function isCollateralSufficient(
        address asset,
        uint256 collateralAmount,
        uint256 loanAmount,
        uint256 requiredLTV
    ) public view returns (bool) {
        uint256 collateralValue = getCollateralValue(asset, collateralAmount);
        uint256 maxLoan = (collateralValue * requiredLTV) / 1e18;
        return loanAmount <= maxLoan;
    }
}

