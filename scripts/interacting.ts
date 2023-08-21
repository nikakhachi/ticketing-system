import { upgrades, ethers } from "hardhat";

const main = async () => {
  const [user1, user2, user3, user4, user5] = await ethers.getSigners();

  const EventFactory = await ethers.getContractFactory("EventFactory");
  const eventFactory = await upgrades.deployProxy(EventFactory, [], { kind: "uups" });
  await eventFactory.waitForDeployment();

  // User1 wants to make a musical event and for the ticketing system he wants to use the EventFactory contract.
  // He wants 3 types of tickets: Silver, Gold and Platinum. Price and the supply is respective to the type.
  const tx1 = await eventFactory.createEvent([
    { id: 1, price: ethers.parseEther("1"), maxSupply: 200 },
    { id: 2, price: ethers.parseEther("2"), maxSupply: 100 },
    { id: 3, price: ethers.parseEther("10"), maxSupply: 10 },
  ]);
  const receipt1 = await tx1.wait();
  const eventAddress = receipt1.logs[receipt1.logs.length - 1].args[0];
  const event = await ethers.getContractAt("Event", eventAddress);

  // User2 wants to buy 2 tickets of Gold type (id 2) for him and his wife (User3).
  // He buys them and then transfers the ownership of one of the tickets to his wife.
  const tx2 = await event.connect(user2).buyTickets(user2.address, 2, 2, { value: ethers.parseEther("4") });
  await tx2.wait();
  const tx3 = await event.connect(user2).safeTransferFrom(user2.address, user3.address, 2, 1, ethers.toUtf8Bytes(""));
  await tx3.wait();

  // User3 and User4 want to buy tickets for their whole class so they can enjoy the concert together
  // But They want to have Platinum tickets while there classmates will have Silver tickets. They split the cost
  const tx4 = await user4.sendTransaction({ to: user3.address, value: ethers.parseEther("20") });
  await tx4.wait();
  const tx5 = await event.connect(user3).buyTicketsBatch(user3.address, [3, 1], [2, 20], { value: ethers.parseEther("40") });
  await tx5.wait();

  // The Event organizer wants to see how many tickets are sold and how much money he made and after that
  // He decides to stop the sale of tickets
  const tickets1Sold = await event.soldTickets(1);
  const tickets2Sold = await event.soldTickets(2);
  const tickets3Sold = await event.soldTickets(3);
  const tx6 = await event.endSales();
  await tx6.wait();

  // User5 checks the remaining tickets for Gold type and he's excited that the tickets are available
  // He wants to buy them but he didn't check that the sales has already ended
  const tickets2Left = await event.remainingTickets(2);
  // Commented because it will revert
  //   const tx7 = await event.connect(user5).buyTickets(user5.address, 2, 1, { value: ethers.parseEther("2") });
  //   await tx7.wait();

  // The concert was succesfull, fans are happy and the organizer wants to withdraw the money
  const tx8 = await event.withdrawFunds();
  await tx8.wait();
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
