// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IProtocolDataProvider.sol";
import "./interfaces/IPriceOracleGetter.sol";

contract LiquidationManager {
    ILendingPool public lendingPool;
    IProtocolDataProvider public dataProvider;
    IPriceOracleGetter public priceOracle;

    event UserEligibleForLiquidation(
        address indexed user,
        address indexed asset,
        uint256 debtAmount
    );

    constructor(address _lendingPool, address _dataProvider) {
        lendingPool = ILendingPool(_lendingPool);
        dataProvider = IProtocolDataProvider(_dataProvider);
    }

    /**
     * @dev Checks if a user is eligible for liquidation based on health factor
     * @param user The address of the user to check
     * @return bool indicating if the user is eligible for liquidation
     */
    function isUserEligibleForLiquidation(
        address user
    ) external view returns (bool) {
        (, , , , , uint256 healthFactor) = dataProvider.getUserAccountData(
            user
        );
        return healthFactor < 1 ether; // A health factor below 1 indicates liquidation eligibility
    }

    // Check if the user's health factor is below 1 (eligible for liquidation) internal function check
    function canLiquidate(address user) internal view returns (bool) {
        (, , , , , uint256 healthFactor) = dataProvider.getUserAccountData(
            user
        );
        return healthFactor < 1e18;
    }

    // Calculate the amount that should be liquidated based on user's debt and collateral
    function getLiquidationAmount(
        address user,
        address asset
    ) external view returns (uint256) {
        (, uint256 totalDebtETH, , , , ) = dataProvider.getUserAccountData(
            user
        );
        uint256 assetPrice = priceOracle.getAssetPrice(asset);

        // Calculate amount to liquidate based on some percentage, e.g., 50% of debt
        uint256 debtAmountInAsset = (totalDebtETH * 1e18) / assetPrice;
        uint256 liquidationAmount = debtAmountInAsset / 2; // Example: liquidate 50% of debt

        return liquidationAmount;
    }

    // Manually liquidate a user's position by transferring collateral and covering debt
    function manualLiquidation(
        address user,
        address collateralAsset,
        address debtAsset,
        uint256 debtToCover
    ) external {
        require(canLiquidate(user), "User is not eligible for liquidation");

        // Transfer the debt asset from the liquidator to this contract
        IERC20(debtAsset).transferFrom(msg.sender, address(this), debtToCover);

        // Approve the lending pool to use this debt amount to repay
        IERC20(debtAsset).approve(address(lendingPool), debtToCover);
        lendingPool.repay(debtAsset, debtToCover, 2, user); // Repay the debt on behalf of the user

        // Transfer the equivalent collateral to the liquidator
        uint256 collateralAmount = calculateCollateralToSeize(
            collateralAsset,
            debtAsset,
            debtToCover
        );
        IERC20(collateralAsset).transfer(msg.sender, collateralAmount);

        emit UserEligibleForLiquidation(user, collateralAsset, debtToCover);
    }

    // Calculate the collateral amount to seize based on the debt covered
    function calculateCollateralToSeize(
        address collateralAsset,
        address debtAsset,
        uint256 debtToCover
    ) internal view returns (uint256) {
        uint256 debtAssetPrice = priceOracle.getAssetPrice(debtAsset);
        uint256 collateralAssetPrice = priceOracle.getAssetPrice(
            collateralAsset
        );

        // Calculate collateral amount based on asset prices
        return (debtToCover * debtAssetPrice) / collateralAssetPrice;
    }
}
