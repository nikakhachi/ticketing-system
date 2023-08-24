import { upgrades, ethers } from "hardhat";

const PROXY = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

const main = async () => {
  const EventFactoryV2 = await ethers.getContractFactory("EventFactoryV2");
  const eventFactoryV2 = await upgrades.upgradeProxy(PROXY, EventFactoryV2);

  await eventFactoryV2.waitForDeployment();

  console.log(`Event Factory Version -- ${await eventFactoryV2.version()} --  Implementation has been Deployed`);

  const tx = await eventFactoryV2.createEvent("", [
    { id: 1, price: ethers.parseEther("1"), maxSupply: 200 },
    { id: 2, price: ethers.parseEther("2"), maxSupply: 100 },
    { id: 3, price: ethers.parseEther("10"), maxSupply: 500 },
  ]);
  const receipt = await tx.wait();
  const eventV2Address = receipt.logs[receipt.logs.length - 1].args[0];
  const eventV2 = await ethers.getContractAt("Event", eventV2Address);

  console.log(`Created Event Version is: ${await eventV2.version()}`);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
