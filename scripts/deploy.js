const hre = require("hardhat");
async function main() {
  const EscrowFactory = await hre.ethers.getContractFactory("ZenithGigEscrow");
  const escrow = await EscrowFactory.deploy();
  await escrow.deployed();
  console.log("-> Zenith Gig Escrow Engine live at:", escrow.address);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
