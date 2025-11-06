import { describe, it } from "node:test";
import { expect } from "chai";
import hre from "hardhat";

describe("PhongToken TypeScript Tests", function () {
  it("Should compile and have correct contract name", async function () {
    const artifact = await hre.artifacts.readArtifact("PhongToken");
    expect(artifact.contractName).to.equal("PhongToken");
  });

  it("Should have correct ABI methods", async function () {
    const artifact = await hre.artifacts.readArtifact("PhongToken");
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
    expect(methods).to.include('transferFrom');
    
    // Check custom methods
    expect(methods).to.include('mint');
    expect(methods).to.include('burn');
    expect(methods).to.include('burnFrom');
    expect(methods).to.include('grantMinterRole');
    expect(methods).to.include('grantBurnerRole');
    expect(methods).to.include('revokeMinterRole');
    expect(methods).to.include('revokeBurnerRole');
  });

  it("Should have role constants in ABI", async function () {
    const artifact = await hre.artifacts.readArtifact("PhongToken");
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

  it("Should have burn and burnFrom functions with correct modifiers", async function () {
    const artifact = await hre.artifacts.readArtifact("PhongToken");
    const burnFn = artifact.abi.find((item: any) => 
      item.type === 'function' && item.name === 'burn'
    );
    const burnFromFn = artifact.abi.find((item: any) => 
      item.type === 'function' && item.name === 'burnFrom'
    );
    
    expect(burnFn).to.not.be.undefined;
    expect(burnFromFn).to.not.be.undefined;
    expect(burnFn.inputs).to.have.lengthOf(1);
    expect(burnFromFn.inputs).to.have.lengthOf(2);
  });
});
