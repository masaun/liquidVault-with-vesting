// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import { SafeMath } from '@openzeppelin/contracts/math/SafeMath.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';  // ROCK3T token
import { IUniswapV2Pair } from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

/**
 * @notice - This contract has a role that yield farming and vesting for LPs
 * @notice - DGVC tokens are distributed as rewards
 */
contract LpVesting {
    using SafeMath for uint;

    IERC20 public dgvc;   // DGVC token
    address public DGVC;         // DGVC token (contract address)

    uint public VESTING_PERIOD;
    uint public DEFAULT_VESTING_PERIOD = 24 weeks;  // Default vesting period is 6 months
    //uint public REWARD_TOKEN_AMOUNT_TO_BE_SUPPLED = 1e6 * 1e18;  // Reward tokens amount to be supplied is 6000000

    uint public totalStakedAmount;               // amount
    uint public totalRewardAmount;
    uint public lastUpdated;

    struct StakeData {
        IUniswapV2Pair lpToken;
        address staker;
        uint stakeAmount;
        uint startTimeOfStaking;  // Timestamp when a user staked
    }
    mapping (address => StakeData) stakeDatas;

    constructor(IERC20 _dgvc) public {
         dgvc = _dgvc;
         DGVC = address(dgvc);
    }

    /**
     * @notice - Deposit reward tokens (DGVC tokens) by a Rocket3T project owner
     */
    function depositRewardToken(uint depositAmount) public returns (bool) {
        address projectOwner = msg.sender;
        dgvc.transferFrom(projectOwner, address(this), depositAmount);

        // Set total reward amount
        totalRewardAmount = depositAmount;
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

        // Save stake data of a staker
        _stake(lpToken, staker, stakeAmount);
    }

    function _stake(IUniswapV2Pair _lpToken, address _staker, uint _stakeAmount) internal returns (bool) {
        StakeData storage stakeData = stakeDatas[_staker];
        stakeData.lpToken = _lpToken;
        stakeData.staker = _staker;
        stakeData.stakeAmount = _stakeAmount;
        stakeData.startTimeOfStaking = block.timestamp;

        // Update total staking amount
        totalStakedAmount += _stakeAmount;
    }

    /**
     * @notice - Unstake LP tokens. (Only after vesting period is passed, unstaking is able to execute)
     */
    function unstake(IUniswapV2Pair lpToken) public returns (bool) {
        require (block.timestamp < VESTING_PERIOD, "It has not passed the vesting period");

        address staker = msg.sender;
        StakeData memory stakeData = stakeDatas[staker];

        // Unstake
        uint unstakeAmount = stakeData.stakeAmount;
        lpToken.transfer(staker, unstakeAmount);

        // Update total staking amount
        totalStakedAmount.sub(unstakeAmount);

        // Distribute reward tokens
        uint _startTimeOfStaking = stakeData.startTimeOfStaking;
        claimRewards(staker, _startTimeOfStaking);
    }

    /**
     * @notice - Claim reward tokens (DGVC tokens)
     * @notice - Vesting period is same for all stakers
     */
    function claimRewards(address receiver, uint startTimeOfStaking) public returns (bool) {
        // [Formula of reward]: Total reward amount * Share of staked-LPs (%) * Total staking time (seconds)
        uint rewardAmountPerSecond = getRewardAmountPerSecond();
        uint totalStakingTime = block.timestamp.sub(startTimeOfStaking);
        uint stakingShare = getStakingShare(receiver);
        uint distributedRewardAmount = rewardAmountPerSecond.mul(startTimeOfStaking).mul(stakingShare).div(100);

        // Distribute reward tokens (DGVC tokens)
        dgvc.transfer(receiver, distributedRewardAmount);
    }
    

    //-----------
    // Getter
    //-----------
    function getVestingPeriod() public view returns (uint _vestingPeriod) {
        return VESTING_PERIOD;
    }

    function getStakingShare(address staker) public view returns (uint _stakingShare) {
        StakeData memory stakeData = getStakeData(staker);
        uint stakedAmount = stakeData.stakeAmount;
        uint stakingShare = stakedAmount.mul(1e18).div(totalStakedAmount);
        //uint stakingShare = stakedAmount.mul(100).div(totalStakedAmount);   // Original
        return stakingShare; // Unit is percentage (%)
    }

    function getRewardAmountPerSecond() public view returns (uint _rewardAmountPerSecond) {
        return totalRewardAmount.div(VESTING_PERIOD);  // Reward amount per second
    }

    function getStakeData(address staker) public view returns (StakeData memory _stakeData) {
        StakeData memory stakeData = stakeDatas[staker];
        return stakeData;
    }

    function getStartTimeOfStaking(address staker) public view returns (uint _startTimeOfStaking) {
        StakeData memory stakeData = stakeDatas[staker];
        uint startTimeOfStaking = stakeData.startTimeOfStaking;
        return startTimeOfStaking; // Unit is second
    }

    function getDistributedRewardAmount(address receiver, uint startTimeOfStaking) public view returns (uint _distributedRewardAmount) {
        // [Formula of reward]: Total reward amount * Share of staked-LPs (%) * Total staking time (seconds)
        uint rewardAmountPerSecond = getRewardAmountPerSecond();
        uint totalStakingTime = block.timestamp.sub(startTimeOfStaking);
        uint stakingShare = getStakingShare(receiver);
        uint distributedRewardAmount = rewardAmountPerSecond.mul(startTimeOfStaking).mul(stakingShare).div(100);

        return distributedRewardAmount;
    }
    
    
}