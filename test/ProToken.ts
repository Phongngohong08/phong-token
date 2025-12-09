import { describe, it } from "node:test";
import { expect } from "chai";
import hre from "hardhat";

describe("ProToken TypeScript Tests", function () {
  it("Should compile and have correct contract name", async function () {
    const artifact = await hre.artifacts.readArtifact("ProToken");
    expect(artifact.contractName).to.equal("ProToken");
  });

  it("Should have correct ABI methods", async function () {
    const artifact = await hre.artifacts.readArtifact("ProToken");
    const methods = artifact.abi.filter((item: any) => item.type === 'function')
      .map((item: any) => item.name);
    
    // Check essential ERC20 methods
    expect(methods).to.include('name');
    expect(methods).to.include('symbol');
    expect(methods).to.include('decimals');
    expect(methods).to.include('totalSupply');
    expect(methods).to.include('balanceOf');
    expect(methods).to.include('transfer');
    expect(methods).to.include('approve');
    
    // Check custom system methods
    expect(methods).to.include('systemMint');
    expect(methods).to.include('systemBurn');
    expect(methods).to.include('systemTransfer');
    expect(methods).to.include('grantMinterRole');
    expect(methods).to.include('grantBurnerRole');
    expect(methods).to.include('revokeMinterRole');
    expect(methods).to.include('revokeBurnerRole');
  });

  it("Should have role constants in ABI", async function () {
    const artifact = await hre.artifacts.readArtifact("ProToken");
    const constants = artifact.abi.filter((item: any) => 
      item.type === 'function' && 
      item.stateMutability === 'view' &&
      item.outputs?.length > 0 &&
      item.outputs[0].type === 'bytes32'
    ).map((item: any) => item.name);
    
    expect(constants).to.include('MINTER_ROLE');
    expect(constants).to.include('BURNER_ROLE');
    expect(constants).to.include('DEFAULT_ADMIN_ROLE');
  });

  it("Should have systemMint function with correct signature", async function () {
    const artifact = await hre.artifacts.readArtifact("ProToken");
    const systemMintFn = artifact.abi.find((item: any) => 
      item.type === 'function' && item.name === 'systemMint'
    );
    
    expect(systemMintFn).to.not.be.undefined;
    expect(systemMintFn!.inputs).to.have.lengthOf(2);
    expect(systemMintFn!.inputs[0].type).to.equal('address');
    expect(systemMintFn!.inputs[1].type).to.equal('uint256');
  });

  it("Should have systemBurn function with correct signature", async function () {
    const artifact = await hre.artifacts.readArtifact("ProToken");
    const systemBurnFn = artifact.abi.find((item: any) => 
      item.type === 'function' && item.name === 'systemBurn'
    );
    
    expect(systemBurnFn).to.not.be.undefined;
    expect(systemBurnFn!.inputs).to.have.lengthOf(2);
    expect(systemBurnFn!.inputs[0].type).to.equal('address');
    expect(systemBurnFn!.inputs[1].type).to.equal('uint256');
  });

  it("Should have systemTransfer function with correct signature", async function () {
    const artifact = await hre.artifacts.readArtifact("ProToken");
    const systemTransferFn = artifact.abi.find((item: any) => 
      item.type === 'function' && item.name === 'systemTransfer'
    );
    
    expect(systemTransferFn).to.not.be.undefined;
    expect(systemTransferFn!.inputs).to.have.lengthOf(3);
    expect(systemTransferFn!.inputs[0].type).to.equal('address'); // from
    expect(systemTransferFn!.inputs[1].type).to.equal('address'); // to
    expect(systemTransferFn!.inputs[2].type).to.equal('uint256'); // value
    expect(systemTransferFn!.outputs[0].type).to.equal('bool');
  });
});
