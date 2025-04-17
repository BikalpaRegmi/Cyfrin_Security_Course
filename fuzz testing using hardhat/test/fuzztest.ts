import { ethers } from "hardhat";
import { expect } from "chai";
import { faker } from "@faker-js/faker";
import { MyContract } from "../typechain-types";

describe("Fuzz Testing Example", function () {
  let contract: MyContract;
  let owner, addr1;

  before(async function () {
    [owner, addr1] = await ethers.getSigners();
    const Contract = await ethers.getContractFactory("MyContract");
    contract = await Contract.deploy();
    await contract.waitForDeployment();
  });

  it("should handle random inputs correctly", async function () {
    for (let i = 0; i < 100; i++) {
      const randomValue: number = faker.number.int({ min: 1, max: 1000 });

      console.log(randomValue);

      const tx = await contract.setNumber(randomValue);
      await tx.wait();

      const storedValue = await contract.getNumber();
      expect(storedValue).to.equal(randomValue);
    }
  });
});
