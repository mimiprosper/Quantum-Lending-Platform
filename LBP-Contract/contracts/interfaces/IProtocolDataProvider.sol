// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProtocolDataProvider {
    struct ReserveData {
        uint256 availableLiquidity;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        uint256 liquidityRate;
        uint256 variableBorrowRate;
        uint256 stableBorrowRate;
        uint256 averageStableBorrowRate;
        uint256 liquidityIndex;
        uint256 variableBorrowIndex;
        uint40 lastUpdateTimestamp;
    }

    struct UserReserveData {
        uint256 currentATokenBalance;
        uint256 currentStableDebt;
        uint256 currentVariableDebt;
        uint256 principalStableDebt;
        uint256 scaledVariableDebt;
        uint256 stableBorrowRate;
        uint256 liquidityRate;
        uint40 stableRateLastUpdated;
        bool usageAsCollateralEnabled;
    }

    function getUserAccountData(
        address user
    )
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    /**
     * @notice Returns reserve data for the specified asset.
     * @param asset The address of the underlying asset of the reserve.
     * @return ReserveData containing details like liquidity and interest rates.
     */
    function getReserveData(
        address asset
    ) external view returns (ReserveData memory);

    /**
     * @notice Returns user-specific reserve data for the specified asset.
     * @param asset The address of the underlying asset of the reserve.
     * @param user The address of the user.
     * @return UserReserveData containing details on user debt and collateralization.
     */
    function getUserReserveData(
        address asset,
        address user
    ) external view returns (UserReserveData memory);

    /**
     * @notice Returns the list of all reserves in the protocol.
     * @return List of addresses for each reserve asset.
     */
    function getAllReservesTokens() external view returns (address[] memory);

    /**
     * @notice Returns the interest rate strategy address for the specified asset.
     * @param asset The address of the underlying asset of the reserve.
     * @return The address of the interest rate strategy.
     */
    function getInterestRateStrategyAddress(
        address asset
    ) external view returns (address);

    /**
     * @notice Returns the token addresses used in the Aave protocol.
     * @return List of token addresses associated with the protocol.
     */
    function getATokenAddress(address asset) external view returns (address);

    function getStableDebtTokenAddress(
        address asset
    ) external view returns (address);

    function getVariableDebtTokenAddress(
        address asset
    ) external view returns (address);
}
