// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';  // ROCK3T token
import { IUniswapV2Pair } from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import { LiquidVault } from "./rock3t/LiquidVault.sol";

/**
 * @notice - This contract has a role that yield farming and vesting for LPs
 */
contract LpVesting {

    LiquidVault public liquidVault;
    IERC20 public r3t;  // ROCK3T token
    address LIQUID_VAULT;
    address R3T;

    uint VESTING_PERIOD;
    uint DEFAULT_VESTING_PERIOD = 24 weeks;  // Default vesting period is 6 months

    uint REWARD_TOKEN_AMOUNT_TO_BE_SUPPLED = 1e6 * 1e18;  // Reward tokens amount to be supplied is 6000000

    constructor(LiquidVault _liquidVault, IERC20 _r3t) public {
        liquidVault = _liquidVault;
        r3t = _r3t;

        LIQUID_VAULT = address(liquidVault);
        R3T = address (r3t);
    }

    /**
     * @notice - Deposit reward tokens (ROCK3T (R3T)) by a Rocket3T project owner
     */
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
        // [Todo]: Add a logic to distribute reward tokens (ROCK3T token)
        uint distributedAmount;
        r3t.transfer(receiver, distributedAmount);
    }
    

    //-----------
    // Getter
    //-----------
    function getVestingPeriod() public view returns (uint _vestingPeriod) {
        return VESTING_PERIOD;
    }
    

    
}