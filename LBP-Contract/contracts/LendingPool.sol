// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ILendingPool.sol";
import "./interfaces/ILendingPoolAddressesProvider.sol";
import "./interfaces/IPriceOracleGetter.sol";
import "./interfaces/IProtocolDataProvider.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendingPool {
    ILendingPoolAddressesProvider public addressesProvider;
    ILendingPool public lendingPool;
    IPriceOracleGetter public priceOracle;
    IProtocolDataProvider public dataProvider;

    event Deposited(address indexed user, address asset, uint256 amount);
    event Withdrawn(address indexed user, address asset, uint256 amount);
    event Borrowed(address indexed user, address asset, uint256 amount);
    event Repaid(address indexed user, address asset, uint256 amount);
    event FlashLoanExecuted(
        address indexed initiator,
        address asset,
        uint256 amount
    );

    event UserEligibleForLiquidation(
        address indexed user,
        address asset,
        uint256 debt
    );

    constructor(
        address _provider,
        address _priceOracle,
        address _dataProvider
    ) {
        addressesProvider = ILendingPoolAddressesProvider(_provider);
        lendingPool = ILendingPool(addressesProvider.getLendingPool());
        priceOracle = IPriceOracleGetter(_priceOracle);
        dataProvider = IProtocolDataProvider(_dataProvider);
    }

    // Deposit assets into the lending pool
    function deposit(address asset, uint256 amount) external {
        require(
            IERC20(asset).transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        IERC20(asset).approve(address(lendingPool), amount);
        lendingPool.deposit(asset, amount, msg.sender, 0); // Updated to deposit
        emit Deposited(msg.sender, asset, amount);
    }

    // Withdraw assets from the lending pool
    function withdraw(address asset, uint256 amount) external {
        uint256 withdrawnAmount = lendingPool.withdraw(
            asset,
            amount,
            msg.sender
        );
        emit Withdrawn(msg.sender, asset, withdrawnAmount);
    }

    // Borrow assets from the lending pool
    function borrow(address asset, uint256 amount) external {
        //uint256 price = getAssetPrice(asset);
        uint256 collateralValue = getCollateralValue(msg.sender);

        uint256 maxLoan = (collateralValue * 75) / 100; // Example 75% LTV ratio
        require(amount <= maxLoan, "Loan exceeds collateral value");

        lendingPool.borrow(asset, amount, 2, 0, msg.sender);
        emit Borrowed(msg.sender, asset, amount);
    }

    // Repay borrowed assets
    function repay(address asset, uint256 amount) external {
        IERC20(asset).approve(address(lendingPool), amount);
        lendingPool.repay(asset, amount, 2, msg.sender);
        emit Repaid(msg.sender, asset, amount);
    }

    function getInterestRates(
        address asset
    )
        external
        view
        returns (
            uint256 depositAPY,
            uint256 stableBorrowRateAPY,
            uint256 variableBorrowAPY
        )
    {
        IProtocolDataProvider.ReserveData memory reserveData = dataProvider
            .getReserveData(asset);
        uint256 liquidityRate = reserveData.liquidityRate;
        uint256 stableBorrowRate = reserveData.stableBorrowRate;
        uint256 variableBorrowRate = reserveData.variableBorrowRate;

        // Convert liquidity and borrow rates from Ray (27 decimals) to a standard percentage format (assuming 2 decimal points for clarity)
        depositAPY = liquidityRate / 1e25; // Converts from Ray to percentage with 2 decimal points
        stableBorrowRateAPY = stableBorrowRate / 1e25; // Converts from Ray to percentage with 2 decimal points
        variableBorrowAPY = variableBorrowRate / 1e25; // Converts from Ray to percentage with 2 decimal points
    }

    // Check if a user is eligible for liquidation
    function checkLiquidationEligibility(
        address user,
        address asset,
        uint256 debtAsset
    ) external {
        // Fetch user account data from Aave to determine health factor
        (, , , , , uint256 healthFactor) = dataProvider.getUserAccountData(
            user
        );

        // If the health factor is less than 1, user is eligible for liquidation
        if (healthFactor < 1e18) {
            // health factor in Aave is scaled by 1e18
            emit UserEligibleForLiquidation(user, asset, debtAsset);
        }
    }

    // Get user account data directly for better insights
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
        )
    {
        return dataProvider.getUserAccountData(user);
    }

    // Check if a user's position is eligible for liquidation
    function isLiquidatable(address user) external view returns (bool) {
        uint256 healthFactor = getHealthFactor(user);
        return healthFactor < 1 ether;
    }

    // Get the current price of an asset
    function getAssetPrice(address asset) public view returns (uint256) {
        return priceOracle.getAssetPrice(asset);
    }

    // Get the collateral value of a user
    function getCollateralValue(address user) internal view returns (uint256) {
        (, uint256 collateralETH, , , , ) = dataProvider.getUserAccountData(
            user
        );
        return collateralETH; // Returns the collateral in ETH
    }

    // Get the health factor of a user
    function getHealthFactor(address user) public view returns (uint256) {
        (, , , , , uint256 healthFactor) = dataProvider.getUserAccountData(
            user
        );
        return healthFactor;
    }

    // Flash loan function (example)
    function executeFlashLoan(address asset, uint256 amount) external {
        bytes memory params = ""; // Custom params for the flash loan
        lendingPool.flashLoan(address(this), asset, amount, params);
        emit FlashLoanExecuted(msg.sender, asset, amount);
    }
}
