// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ILendingPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FlashLoanManager {
    ILendingPool public lendingPool;

    constructor(address _lendingPool) {
        lendingPool = ILendingPool(_lendingPool);
    }

    function executeFlashLoan(address asset, uint256 amount) external {
        bytes memory params = ""; // Custom params for the flash loan
        lendingPool.flashLoan(address(this), asset, amount, params);
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address, //initiator,
        bytes calldata //params
    ) external returns (bool) {
        // Custom logic for using flash loan
        IERC20(asset).approve(address(lendingPool), amount + premium);
        return true;
    }
}
