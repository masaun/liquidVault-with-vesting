# Liquid Vault with Vesting

***
## 【Introduction of the Liquid Vault with Vesting】
- This smart contract is customized-contract of the rock3t-core-contracts that:
  - allow a user to stake LP tokens as `"early LP staking"` and get opportunity to `earn rewards` (as incentive of "early LP staking") after general process of the `rock3t-core-contracts` ( https://github.com/masaun/liquidVault-with-vesting#overview )
  - Staking LP also means `LP vesting` .
    - Once a user stake LP, they can not withdraw until the vesting period is passed.
      (Default vesting period are 6 months (=24 weeks) at the moment)
    
  - After vesting period is passed, a user can withdraw and receive rewards. 
     - Rewards is `DGVC` token.
     - Rewards are calculated every seconds during vesting period.

<br>

(※ rock3t-core-contracts: https://github.com/degen-vc/rock3t-core-contracts )

&nbsp;

***

## 【Workflow】
- Workflow: 
  - ① A user sending ETH into the `LiquidVault (LiquidVaulWithVesting.sol)` and pooling it with R3T to create LP tokens, FeeApprover that calculates FOT, FeeDistributor that distributes fees on LiquidVault. 
  - ② LiquidVault allows users to send ETH and pool it with R3T, while certain percentage of fee that is calculated using buy pressure formula is swapped on Uniswap market. Minted LP tokens are locked in LiquidVault for a period that is calculated based on the system health.
    ③ A user claim LP tokens and receive them.
    ④ At the same time, certain percentage of LP tokens is donated.
  - ⑤ A user stake LP tokens (= `Vesting of LP tokens` . Default vesting period is 24 weeks)
  - ⑥ After vesting period is passed, a user can withdraw and receive `reward tokens` (= `DGVC tokens` )

<br>

- Diagram of workflow 
![【Diagram】Liquid Vault with Vesting](https://user-images.githubusercontent.com/19357502/118573058-c1e9ed00-b7bc-11eb-9097-c31ba17eea1a.jpg)


&nbsp;

***

## 【Demo Video】
- https://youtu.be/94P_t9BVC_s

<br>


***

## 【Remarks】
- Version for following the `Degen.VC` smart contract
  - Solidity (Solc): v0.7.1
  - Truffle: v5.1.60
  - web3.js: v1.2.9
  - openzeppelin-solidity: v3.2.0
  - ganache-cli: v6.9.1 (ganache-core: 2.10.2)


&nbsp;

***

## 【Setup】
### ① Install modules
- Install npm modules in the root directory
```
$ npm install
```

<br>

### ② Test (Using Ganache-CLI)
- 1: Start ganache-cli
```
$ npm run ganache
```

<br>

- 2: Execute test of the LiquidVaultWithVesting contract
```
npm run test:LiquidVaultWithVesting
```

<br>


***

## 【References】
- Degen.VC  
  - Website: https://www.degen.vc/
  - Github: https://github.com/degen-vc

<br>

- Rock3T
  - rock3t-core-contracts: https://github.com/degen-vc/rock3t-core-contracts  
  - Structure: https://medium.com/rock3t/breaking-down-rock3ts-economic-levers-1dd32b04e9e1

<br>

- Liquid Vault Gitcoin Hackathon Prizes  
  - Best new implementation of a Liquid Vault   
    https://gitcoin.co/issue/degen-vc/liquid-vault/1/100025592
