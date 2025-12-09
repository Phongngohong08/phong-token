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
npx hardhat ignition deploy ignition/modules/ProToken.ts
npx hardhat ignition deploy --network sepolia ignition/modules/ProToken.ts

## Verify commands
npx hardhat verify --network sepolia 0x4e8b6c32dba1A5EA9b32D4C6388b93067C91c4b5