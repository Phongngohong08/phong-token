import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("PTokenModule", (m) => {
  // Deploy ProToken contract
  const proToken = m.contract("ProToken");

  return { proToken };
});
