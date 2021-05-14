// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';  // ROCK3T token
import { IUniswapV2Pair } from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
//import { LiquidVault } from "./rock3t/LiquidVault.sol";

/**
 * @notice - This contract has a role that yield farming and vesting for LPs
 * @notice - DGVC tokens are distributed as rewards
 */
contract LpVesting {

    IERC20 public dgvc;   // DGVC token
    address DGVC;         // DGVC token (contract address)

    uint VESTING_PERIOD;
    uint DEFAULT_VESTING_PERIOD = 24 weeks;  // Default vesting period is 6 months

    uint REWARD_TOKEN_AMOUNT_TO_BE_SUPPLED = 1e6 * 1e18;  // Reward tokens amount to be supplied is 6000000

    struct StakeData {
        IUniswapV2Pair lpToken;
        address staker;
        uint stakeAmount;
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

        // Distribute reward tokens
        claimRewards(staker);
    }

    /**
     * @notice - Claim reward tokens (DGVC tokens)
     * @notice - Vesting period is same for all stakers
     */
    function claimRewards(address receiver) public returns (bool) {
        // [Todo]: Add a logic to distribute reward tokens (DGVC tokens)
        uint distributedAmount;
        dgvc.transfer(receiver, distributedAmount);
    }
    

    //-----------
    // Getter
    //-----------
    function getVestingPeriod() public view returns (uint _vestingPeriod) {
        return VESTING_PERIOD;
    }
    

    
}