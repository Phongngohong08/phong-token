# Phong Token

## Initialize Hardhat project
npx hardhat --init

## Build command
npx hardhat build

## Install dependencies
npm i @openzeppelin/contracts
npm i dotenv

## Test commands
npx hardhat test
npx hardhat test solidity
npx hardhat test nodejs

## Deployment commands
npx hardhat ignition deploy ignition/modules/PhongToken.ts
npx hardhat ignition deploy --network sepolia ignition/modules/PhongToken.ts

## Verify commands
npx hardhat verify --network sepolia 0x7772ee35E5B0d8EaE15460DCEf7BdC13ca1B311F