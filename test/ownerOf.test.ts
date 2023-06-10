import { expect } from "chai";
import { ethers } from "hardhat";
import { HilbertCurveMap, HilbertCurveMap__factory } from "../typechain-types";
import { Signer } from "ethers";
import { LandSize } from "./config";

describe("OwnerOf", function () {
  let HilbertCurveMapFactory: HilbertCurveMap__factory;
  let HilbertCurveMap: HilbertCurveMap;
  let [deployer, user1, user2]: Signer[] = [];
  let [deployerAddr, user1Addr, user2Addr]: string[] = [];
  beforeEach(async function () {
    [deployer, user1, user2] = await ethers.getSigners();
    [deployerAddr, user1Addr, user2Addr] = await Promise.all([
      deployer.getAddress(),
      user1.getAddress(),
      user2.getAddress(),
    ]);
    HilbertCurveMapFactory = await ethers.getContractFactory(
      "HilbertCurveMap",
      deployer
    );
    HilbertCurveMap = await HilbertCurveMapFactory.deploy();
    await HilbertCurveMap.deployed();
  });
  it("Success to check ownership xsmall", async function () {
    const index = 34;
    await HilbertCurveMap.connect(user1).mintLand(index, LandSize.XSMALL, "");
    for (let i = 0; i < 32 * 32; i++) {
      if (i == 34) {
        expect(await HilbertCurveMap.ownerOf(i)).to.equal(user1Addr);
      } else {
        expect(await HilbertCurveMap.ownerOf(i)).to.equal(
          ethers.constants.AddressZero
        );
      }
    }
  });
  it("Success to check ownership small", async function () {
    const index = 32;
    await HilbertCurveMap.connect(user1).mintLand(index, LandSize.SMALL, "");
    for (let i = 0; i < 32 * 32; i++) {
      if (i >= 32 && i <= 35) {
        expect(await HilbertCurveMap.ownerOf(i)).to.equal(user1Addr);
      } else {
        expect(await HilbertCurveMap.ownerOf(i)).to.equal(
          ethers.constants.AddressZero
        );
      }
    }
  });
  it("Success to check ownership medium", async function () {
    const index = 0;
    await HilbertCurveMap.connect(user1).mintLand(index, LandSize.MEDIUM, "");
    for (let i = 0; i < 32 * 32; i++) {
      if (i >= 0 && i <= 15) {
        expect(await HilbertCurveMap.ownerOf(i)).to.equal(user1Addr);
      } else {
        expect(await HilbertCurveMap.ownerOf(i)).to.equal(
          ethers.constants.AddressZero
        );
      }
    }
  });
  it("Success to check ownership xxlarge (index 0)", async function () {
    const index = 0;
    await HilbertCurveMap.connect(user1).mintLand(index, LandSize.XXLARGE, "");
    for (let i = 0; i < 64 * 64; i++) {
      if (i >= 0 && i <= 1023) {
        expect(await HilbertCurveMap.ownerOf(i)).to.equal(user1Addr);
      } else {
        expect(await HilbertCurveMap.ownerOf(i)).to.equal(
          ethers.constants.AddressZero
        );
      }
    }
  });
  it("Success to check ownership xxlarge (index 1024)", async function () {
    const index = 1024;
    await HilbertCurveMap.connect(user1).mintLand(index, LandSize.XXLARGE, "");
    for (let i = 0; i < 64 * 64; i++) {
      if (i >= 1024 && i <= 2047) {
        expect(await HilbertCurveMap.ownerOf(i)).to.equal(user1Addr);
      } else {
        expect(await HilbertCurveMap.ownerOf(i)).to.equal(
          ethers.constants.AddressZero
        );
      }
    }
  });
});
