// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/core-v3/contracts/interfaces/IPriceOracleGetter.sol";

contract PriceOracle {
    IPriceOracleGetter public priceOracle;

    constructor(address _priceOracle) {
        priceOracle = IPriceOracleGetter(_priceOracle);
    }

    function getAssetPrice(address asset) external view returns (uint256) {
        return priceOracle.getAssetPrice(asset);
    }
}
