import { upgrades, ethers } from "hardhat";

const main = async () => {
  const EventFactory = await ethers.getContractFactory("EventFactory");
  const eventFactory = await upgrades.deployProxy(EventFactory, [], { kind: "uups" });

  await eventFactory.waitForDeployment();

  const eventFactoryAddress = await eventFactory.getAddress();

  console.log(`Event Factory Proxy Deployed on Address: ${eventFactoryAddress}`);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
