import { upgrades, ethers } from "hardhat";

const main = async () => {
  const EventFactory = await ethers.getContractFactory("EventFactory");
  const eventFactory = await upgrades.deployProxy(EventFactory, [], { kind: "uups" });

  await eventFactory.waitForDeployment();

  const eventFactoryAddress = await eventFactory.getAddress();

  console.log(`Event Factory Version -- ${await eventFactory.version()} --  Proxy Deployed on Address: ${eventFactoryAddress}`);

  const tx = await eventFactory.createEvent([
    { id: 1, price: ethers.parseEther("1"), maxSupply: 200 },
    { id: 2, price: ethers.parseEther("2"), maxSupply: 100 },
    { id: 3, price: ethers.parseEther("10"), maxSupply: 500 },
  ]);
  const receipt = await tx.wait();
  const eventAddress = receipt.logs[receipt.logs.length - 1].args[0];
  const event = await ethers.getContractAt("Event", eventAddress);

  console.log(`Created Event Version is: ${await event.version()}`);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
