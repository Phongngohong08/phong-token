import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("PhongTokenModule", (m) => {
  // Deploy PhongToken contract
  const phongToken = m.contract("PhongToken");

  return { phongToken };
});
