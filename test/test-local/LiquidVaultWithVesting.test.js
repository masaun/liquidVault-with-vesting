const Web3 = require('web3')
const web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:8545'))

/// Openzeppelin test-helper
const { time } = require('@openzeppelin/test-helpers')

const Ganache = require('./rock3t/helpers/ganache');
const deployUniswap = require('./rock3t/helpers/deployUniswap');
const { expectEvent, expectRevert, constants } = require("@openzeppelin/test-helpers");

const FeeDistributor = artifacts.require('FeeDistributor');
const RocketToken = artifacts.require('RocketToken');
const DGVCToken = artifacts.require('DGVCToken');
const LiquidVaultWithVesting = artifacts.require('LiquidVaultWithVesting');
//const LiquidVault = artifacts.require('LiquidVault');
const IUniswapV2Pair = artifacts.require('IUniswapV2Pair');
const FeeApprover = artifacts.require('FeeApprover');
const PriceOracle = artifacts.require('PriceOracle');


contract('LiquidVaultWithVesting', function(accounts) {
  const ganache = new Ganache(web3);
  afterEach('revert', ganache.revert);

  const bn = (input) => web3.utils.toBN(input);
  const assertBNequal = (bnOne, bnTwo) => assert.equal(bnOne.toString(), bnTwo.toString());

  const OWNER = accounts[0];
  const NOT_OWNER = accounts[1];
  //const USER_1 = accounts[2];
  const INITIAL_DGVC_HOLDER = accounts[2];
  const baseUnit = bn('1000000000000000000');
  const startTime = Math.floor(Date.now() / 1000);

  const treasury = accounts[7];

  let uniswapOracle;
  let uniswapPair;     /// LP token (ROCK3T - ETH pair)
  let uniswapFactory;
  let uniswapRouter;
  let weth;            /// WETH token
  //let pair;            /// LP token (ROCK3T - ETH pair)

  let feeDistributor;
  let feeApprover;
  let rocketToken;     /// Rock3T token
  let dgvcToken;       /// DGVC token
  let liquidVault;


  before('setup others', async function() {
    const contracts = await deployUniswap(accounts);
    uniswapFactory = contracts.uniswapFactory;
    uniswapRouter = contracts.uniswapRouter;
    weth = contracts.weth;

    // deploy and setup main contracts
    feeApprover = await FeeApprover.new();
    feeDistributor = await FeeDistributor.new();
    rocketToken = await RocketToken.new(feeDistributor.address, feeApprover.address, uniswapRouter.address, uniswapFactory.address);
    dgvcToken = await DGVCToken.new({ from: INITIAL_DGVC_HOLDER });
    //dgvcToken = await DGVCToken.new({ from: OWNER });
    liquidVault = await LiquidVaultWithVesting.new(dgvcToken.address);

    await rocketToken.createUniswapPair();
    uniswapPair = await rocketToken.tokenUniswapPair();
    uniswapOracle = await PriceOracle.new(uniswapPair, rocketToken.address, weth.address);

    await feeApprover.initialize(uniswapPair, liquidVault.address);
    await feeApprover.unPause();
    await feeApprover.setFeeMultiplier(0);

    await feeDistributor.seed(rocketToken.address, liquidVault.address, OWNER, 0);

    await liquidVault.seed(
      rocketToken.address,
      feeDistributor.address,
      uniswapRouter.address,
      uniswapPair,
      treasury,
      uniswapOracle.address
    );

    await ganache.snapshot();
  });

  describe('General tests', async () => {
    it('should set all values after LV setup', async () => {
      const config = await liquidVault.config();

      assert.equal(config.R3T, rocketToken.address);
      assert.equal(config.feeDistributor, feeDistributor.address);
      assert.equal(config.tokenPair, uniswapPair);
      assert.equal(config.uniswapRouter, uniswapRouter.address);
      assert.equal(config.weth, weth.address);
      assert.equal(treasury, treasury);
      assert.equal(config.uniswapOracle, uniswapOracle.address);
    });

    it('should be possible to flush to treasury from owner', async () => {
      const amount = 10000;
      await rocketToken.transfer(liquidVault.address, amount);

      assertBNequal(await rocketToken.balanceOf(liquidVault.address), amount);
      assertBNequal(await rocketToken.balanceOf(treasury), 0);

      await liquidVault.flushToTreasury(amount);

      assertBNequal(await rocketToken.balanceOf(liquidVault.address), 0);
      assertBNequal(await rocketToken.balanceOf(treasury), amount);
    });

    it('should be possible to add liquidity on pair', async () => {
      const liquidityTokensAmount = bn('10000').mul(baseUnit); // 10.000 tokens
      const liquidityEtherAmount = bn('5').mul(baseUnit);      // 5 ETH

      const pair = await IUniswapV2Pair.at(uniswapPair);

      const reservesBefore = await pair.getReserves();
      assertBNequal(reservesBefore[0], 0);
      assertBNequal(reservesBefore[1], 0);

      await rocketToken.approve(uniswapRouter.address, liquidityTokensAmount);
      await uniswapRouter.addLiquidityETH(
        rocketToken.address,
        liquidityTokensAmount,
        0,
        0,
        OWNER,
        new Date().getTime() + 3000,
        {value: liquidityEtherAmount}
      );

      const reservesAfter = await pair.getReserves();

      if (await pair.token0() == rocketToken.address) {
        assertBNequal(reservesAfter[0], liquidityTokensAmount);
        assertBNequal(reservesAfter[1], liquidityEtherAmount);
      } else {
        assertBNequal(reservesAfter[0], liquidityEtherAmount);
        assertBNequal(reservesAfter[1], liquidityTokensAmount);
      }
    });

    it('should be possible to swapExactETHForTokens directly', async () => {
      const liquidityTokensAmount = bn('10000').mul(baseUnit); // 10.000 tokens
      const liquidityEtherAmount = bn('5').mul(baseUnit); // 5 ETH

      const pair = await IUniswapV2Pair.at(uniswapPair);

      const reservesBefore = await pair.getReserves();
      assertBNequal(reservesBefore[0], 0);
      assertBNequal(reservesBefore[1], 0);

      await rocketToken.approve(uniswapRouter.address, liquidityTokensAmount);

      await uniswapRouter.addLiquidityETH(
        rocketToken.address,
        liquidityTokensAmount,
        0,
        0,
        OWNER,
        new Date().getTime() + 3000,
        {value: liquidityEtherAmount}
      );

      const amount = bn('890000').mul(baseUnit);
      await rocketToken.transfer(liquidVault.address, amount);

      assertBNequal(await rocketToken.balanceOf(uniswapPair), '10000000000000000000000');

      await uniswapRouter.swapExactETHForTokens(0, [weth.address, rocketToken.address], liquidVault.address, 7258118400, {value: 100})

      assertBNequal(await rocketToken.balanceOf(uniswapPair), '9999999999999999800601');
    });


    it('should be possible to purchaseLP', async () => {
      const liquidityTokensAmount = bn('1000').mul(baseUnit); // 1.000 tokens
      const liquidityEtherAmount = bn('10').mul(baseUnit);    // 10 ETH

      const pair = await IUniswapV2Pair.at(uniswapPair);

      const reservesBefore = await pair.getReserves();
      assertBNequal(reservesBefore[0], 0);
      assertBNequal(reservesBefore[1], 0);

      await rocketToken.approve(uniswapRouter.address, liquidityTokensAmount);

      await uniswapRouter.addLiquidityETH(
        rocketToken.address,
        liquidityTokensAmount,
        0,
        0,
        OWNER,
        new Date().getTime() + 3000,
        {value: liquidityEtherAmount}
      );

      const amount = bn('890000').mul(baseUnit);
      await rocketToken.transfer(liquidVault.address, amount);

      const balanceBefore = await rocketToken.balanceOf(liquidVault.address);

      const result = await liquidVault.purchaseLP({ value: '10000' });
      const expectedLockPeriod = await liquidVault.getLockedPeriod();

      expectEvent(result, 'LPQueued', {
        lockPeriod: expectedLockPeriod.toString()
      });

      assert.equal(result.logs.length, 1);
      const rocketRequired = result.logs[0].args.r3t;

      const balanceAfter = await rocketToken.balanceOf(liquidVault.address);
      // eth fee is 0, so liquidVault did not receive tokens from fee swap
      assert.equal(balanceAfter.add(rocketRequired).eq(balanceBefore), true);
    });
  });

  describe('Claim LPs. Then, Stake (Vesting) LPs. Then, unStake LPs + Receive rewards', async () => {
      let lpToken  /// [Note]: Rock3T - ETH pair

      it('Claim LPs after the purchase. Then, Stake (Vesting) LPs. Then, unStake LPs + Receive rewards', async () => {
          const liquidityTokensAmount = bn('1000').mul(baseUnit); // 10.000 tokens
          const liquidityEtherAmount = bn('10').mul(baseUnit);    // 5 ETH

          lpToken = await IUniswapV2Pair.at(uniswapPair);
          //const lpToken = await IUniswapV2Pair.at(uniswapPair);

          const reservesBefore = await lpToken.getReserves();
          assertBNequal(reservesBefore[0], 0);
          assertBNequal(reservesBefore[1], 0);

          await rocketToken.approve(uniswapRouter.address, liquidityTokensAmount);

          await uniswapRouter.addLiquidityETH(
              rocketToken.address,
              liquidityTokensAmount,
              0,
              0,
              OWNER,
              new Date().getTime() + 3000,
            {value: liquidityEtherAmount}
          );

          const amount = bn('890000').mul(baseUnit);
          await rocketToken.transfer(liquidVault.address, amount);

          const lockTime = await liquidVault.getLockedPeriod.call();
          
          await ganache.setTime(startTime);
          const result = await liquidVault.purchaseLP({ value: '10000' });
          assert.equal(result.logs.length, 1);

          const lockedLPLength = await liquidVault.lockedLPLength(OWNER);
          assertBNequal(lockedLPLength, 1);

          const resultSecondPurchase = await liquidVault.purchaseLP({ value: '20000' });
          assert.equal(resultSecondPurchase.logs.length, 1);

          const lockedLPLengthSecondPurchase = await liquidVault.lockedLPLength(OWNER);
          assertBNequal(lockedLPLengthSecondPurchase, 2);

          await uniswapOracle.update();

          const lpBalanceBefore = await lpToken.balanceOf(OWNER);
          const claimTime = bn(startTime).add(bn(lockTime)).add(bn(1)).toString();
          await ganache.setTime(claimTime);
          await uniswapOracle.update();
          const oracleUpdateTimestamp = Number(claimTime) + 7 * 1800;
          await ganache.setTime(oracleUpdateTimestamp);

          const lockedLP = await liquidVault.getLockedLP(OWNER, 0);
          const claim = await liquidVault.claimLP();

          const lpBalanceAfter = await lpToken.balanceOf(OWNER);
          const lockedLPLengthAfterClaim = await liquidVault.lockedLPLength(OWNER);


          ///----------------------------------------------------------------
          /// Deposit reward tokens (5000 DGVC tokens) into the LiquidVault (Depositor: Initial DGVC token holder)
          ///----------------------------------------------------------------
          console.log('\n--------------- Deposit reward tokens (5000 DGVC tokens) into the LiquidVault (Depositor: Initial DGVC token holder) ---------------')
          const depositAmount = web3.utils.toWei('5000', 'ether')  /// 5000 DGVC 
          let txReceipt1 = await dgvcToken.approve(liquidVault.address, depositAmount, { from: INITIAL_DGVC_HOLDER })
          let txReceipt2 = await liquidVault.depositRewardToken(depositAmount, { from: INITIAL_DGVC_HOLDER })

          ///----------------------------------------------------------------
          /// Set the vesting period (24 weeks) of LP
          ///----------------------------------------------------------------
          console.log('\n--------------- Set the vesting period (24 weeks) of LP ---------------')
          let txReceipt3 = await liquidVault.setVestingPeriod({ from: OWNER })

          ///----------------------------------------------------------------
          /// Check balances before stake
          ///----------------------------------------------------------------
          console.log('\n--------------- Check balances before stake ---------------')
          let lpBalanceBeforeStake = await lpToken.balanceOf(OWNER)
          let dgvcBalanceBeforeStake = await dgvcToken.balanceOf(OWNER)
          console.log('=== LP Balance before stake ===', web3.utils.fromWei(String(lpBalanceBeforeStake), 'ether'))
          console.log('=== DGVC balance before stake ===', web3.utils.fromWei(String(dgvcBalanceBeforeStake), 'ether'))


          ///----------------------------------------------------------------
          /// Stake LPs into the LiquidVault for the vesting period (??? All LPs which user hold are staked)
          ///----------------------------------------------------------------
          console.log('\n--------------- Stake LPs into the LiquidVault for the vesting period (??? All LPs which user hold are staked) ---------------')
          const LP_TOKEN = lpToken.address  /// LP token (ROCK3T - ETH pair)
          let txReceipt4 = await lpToken.approve(liquidVault.address, lpBalanceBeforeStake, { from: OWNER })
          let txReceipt5 = await liquidVault.stake(LP_TOKEN, { from: OWNER })
          //console.log('=== txReceipt4 (stake) ===', txReceipt4)

          ///----------------------------------------------------------------
          /// Time goes to 25 week ahead (by using openzeppelin-test-helper)
          ///----------------------------------------------------------------
          console.log('\n--------------- Time goes to 25 week ahead (by using openzeppelin-test-helper) ---------------')
          const day = 60 * 60 * 24
          const week = day * 7
          await time.increase(week * 25)  // 25 weeks

          ///----------------------------------------------------------------
          /// Check distributed-reward amount
          ///----------------------------------------------------------------
          console.log('\n--------------- Check distributed-reward amount ---------------')
          const receiver = OWNER
 
          const stakeData = await liquidVault.getStakeData(receiver)
          console.log('=== stakeData ===', stakeData)        

          const rewardAmountPerSecond = await liquidVault.getRewardAmountPerSecond()
          console.log('=== rewardAmountPerSecond (DGVC) ===', web3.utils.fromWei(String(rewardAmountPerSecond), 'ether'))

          const currentTimestamp = await liquidVault.getCurrentTimestamp()
          console.log('=== currentTimestamp ===', String(currentTimestamp))          

          const startTimeOfStaking = await liquidVault.getStartTimeOfStaking(receiver)
          console.log('=== startTimeOfStaking ===', String(startTimeOfStaking))        

          const stakingShare = await liquidVault.getStakingShare(receiver)
          console.log('=== stakingShare (%) ===', String(stakingShare))

          const distributedRewardAmount = await liquidVault.getDistributedRewardAmount(receiver, startTimeOfStaking)
          console.log('=== distributedRewardAmount (DGVC) ===', web3.utils.fromWei(String(distributedRewardAmount), 'ether'))

          ///-----------------------------------------------------------------------
          /// unStake LPs from the LiquidVault after the vesting period is passed
          ///-----------------------------------------------------------------------
          console.log('\n--------------- unStake LPs from the LiquidVault after the vesting period is passed ---------------')
          let txReceipt6 = await liquidVault.unstake(LP_TOKEN, { from: OWNER })

          ///----------------------------------------------------------------
          /// Check balances after unstake
          ///----------------------------------------------------------------
          console.log('\n--------------- Check balances after unstake ---------------')
          let lpBalanceAfterUnstake = await lpToken.balanceOf(OWNER);
          let dgvcBalanceAfterUnstake = await dgvcToken.balanceOf(OWNER)
          console.log('=== LP Balance after unstake ===', web3.utils.fromWei(String(lpBalanceAfterUnstake), 'ether'))
          console.log('=== DGVC balance after unstake ===', web3.utils.fromWei(String(dgvcBalanceAfterUnstake), 'ether'))
      });
  })

});
