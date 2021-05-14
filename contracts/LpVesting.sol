// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import { IUniswapV2Pair } from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';


/**
 * @notice - This contract has a role that  yield farming and vesting for LPs
 */
contract LpVesting {

    uint VESTING_PERIOD;
    uint DEFAULT_VESTING_PERIOD = 24 weeks;  // Default vesting period is 6 months

    uint REWARD_TOKEN_AMOUNT_TO_BE_SUPPLED = 1e6 * 1e18;  // Reward tokens amount to be supplied is 6000000

    constructor() public {}

    function depositRewardToken() public returns (bool) {
        // [Todo]: TransferFrom of RewardToken
    }

    function setVestingPeriod() public returns (bool) {
        VESTING_PERIOD = block.timestamp + DEFAULT_VESTING_PERIOD;   
    }

    // function updateVestingPeriod(uint newVestingPeriod) public returns (bool) {
    //     VESTING_PERIOD = newVestingPeriod;
    // }

    /**
     * @notice - All LP token that a user has is staked and vested
     */
    function stake(IUniswapV2Pair lpToken) public returns (bool) {
        address staker = msg.sender;
        uint stakeAmount = lpToken.balanceOf(staker);
        lpToken.transferFrom(staker, address(this), stakeAmount);
    }

    /**
     * @notice - Unstake LP tokens. (Only after vesting period is passed, unstaking is able to execute)
     */
    function unstake(IUniswapV2Pair lpToken) public returns (bool) {
        require (block.timestamp < VESTING_PERIOD, "It has not passed the vesting period");

        // Unstake
        address staker = msg.sender;
        uint unstakeAmount;  // [Todo]: Call from the UserStakeData struct
        lpToken.transfer(staker, unstakeAmount);

        // Distribute reward tokens
        claimRewards(staker);
    }

    /**
     * @notice - Claim reward tokens (RocketToken)
     * @notice - Vesting period is same for all stakers
     */
    function claimRewards(address receiver) public returns (bool) {
        // [Todo]: Add a logic to distribute reward tokens
    }
    

    //-----------
    // Getter
    //-----------
    function getVestingPeriod() public view returns (uint _vestingPeriod) {
        return VESTING_PERIOD;
    }
    

    
}