// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/**
 * @notice - This contract has a role that  yield farming and vesting for LPs
 */
contract LpVesting {

    uint VESTING_PERIOD;
    uint DEFAULT_VESTING_PERIOD = 24 weeks;  // Default vesting period is 6 months

    constructor() public {
        VESTING_PERIOD = DEFAULT_VESTING_PERIOD;
    }

    function updateVestingPeriod(uint newVestingPeriod) public returns (bool) {
        VESTING_PERIOD = newVestingPeriod;
    }

    function stake() public returns (bool) {}

    function unstake() public returns (bool) {}

    //-----------
    // Getter
    //-----------
    function getVestingPeriod() public view returns (uint _vestingPeriod) {
        return VESTING_PERIOD;
    }
    

    
}