// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LendingPool.sol";
import "./helpers/FlashLoanHelper.sol";
import "./CollateralManager.sol";
import "./LiquidationManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DecentralizedLendingBorrowing {
    LendingPool public lendingPool;
    FlashLoanHelper public flashLoanHelper;
    CollateralManager public collateralManager;
    LiquidationManager public liquidationManager;

    event Deposited(address indexed user, address asset, uint256 amount);
    event Borrowed(address indexed user, address asset, uint256 amount);
    event Repaid(address indexed user, address asset, uint256 amount);
    event Liquidated(address indexed user, address asset, uint256 amount);
    event FlashLoanExecuted(
        address indexed user,
        address asset,
        uint256 amount
    );

    constructor(
        address _lendingPoolAddress,
        address _flashLoanHelperAddress,
        address _collateralManagerAddress,
        address _liquidationManagerAddress //address _priceOracleAddress
    ) {
        lendingPool = LendingPool(_lendingPoolAddress);
        flashLoanHelper = FlashLoanHelper(_flashLoanHelperAddress);
        collateralManager = CollateralManager(_collateralManagerAddress);
        liquidationManager = LiquidationManager(_liquidationManagerAddress);
    }

    function deposit(address asset, uint256 amount) external {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        IERC20(asset).approve(address(lendingPool), amount);
        lendingPool.deposit(asset, amount);
        emit Deposited(msg.sender, asset, amount);
    }

    function borrow(address asset, uint256 amount) external {
        lendingPool.borrow(asset, amount);
        emit Borrowed(msg.sender, asset, amount);
    }

    function repay(address asset, uint256 amount) external {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        IERC20(asset).approve(address(lendingPool), amount);
        lendingPool.repay(asset, amount);
        emit Repaid(msg.sender, asset, amount);
    }

    function liquidate(
        address user,
        address collateralAsset,
        address asset
    ) external {
        require(
            liquidationManager.isUserEligibleForLiquidation(user),
            "User is not eligible for liquidation"
        );
        uint256 debtToCover = liquidationManager.getLiquidationAmount(
            user,
            asset
        );
        liquidationManager.manualLiquidation(
            user,
            collateralAsset,
            asset,
            debtToCover
        );
        emit Liquidated(user, asset, debtToCover);
    }

    function executeFlashLoan(
        address asset,
        uint256 amount,
        bytes calldata params
    ) external {
        flashLoanHelper.executeFlashLoanWithParams(asset, amount, params);
        emit FlashLoanExecuted(msg.sender, asset, amount);
    }

    // Retrieve account data using Aave's getUserAccountData
    function getAccountData(
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
        return lendingPool.getUserAccountData(user);
    }
}
