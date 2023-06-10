import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { HilbertCurveMap, HilbertCurveMap__factory } from "../typechain-types";
import { Signer } from "ethers";
import { LandSize } from "./config";

describe("Transfer", function () {
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
  it("Success to transfer xsmall land", async function () {
    const index = 34;
    await HilbertCurveMap.connect(user1).mintLand(index, LandSize.XSMALL, "");
    await HilbertCurveMap.connect(user1).transferFrom(
      user1Addr,
      user2Addr,
      index
    );
    expect(await HilbertCurveMap.ownerOf(index)).to.equal(user2Addr);
    expect(await HilbertCurveMap.balanceOf(user1Addr)).to.equal(0);
    expect(await HilbertCurveMap.balanceOf(user2Addr)).to.equal(1);
  });
  it("Success to transfer small land", async function () {
    const index = 32;
    await HilbertCurveMap.connect(user1).mintLand(index, LandSize.SMALL, "");
    await HilbertCurveMap.connect(user1).transferFrom(
      user1Addr,
      user2Addr,
      index
    );
    expect(await HilbertCurveMap.ownerOf(index)).to.equal(user2Addr);
    expect(await HilbertCurveMap.balanceOf(user1Addr)).to.equal(0);
    expect(await HilbertCurveMap.balanceOf(user2Addr)).to.equal(4);
  });
  it("Success to transfer medium land", async function () {
    const index = 32;
    await HilbertCurveMap.connect(user1).mintLand(index, LandSize.MEDIUM, "");
    await HilbertCurveMap.connect(user1).transferFrom(
      user1Addr,
      user2Addr,
      index
    );
    expect(await HilbertCurveMap.ownerOf(index)).to.equal(user2Addr);
    expect(await HilbertCurveMap.balanceOf(user1Addr)).to.equal(0);
    expect(await HilbertCurveMap.balanceOf(user2Addr)).to.equal(16);
  });
  it("Success to transfer xxlarge land", async function () {
    const index = 1024;
    await HilbertCurveMap.connect(user1).mintLand(index, LandSize.XXLARGE, "");
    await HilbertCurveMap.connect(user1).transferFrom(
      user1Addr,
      user2Addr,
      index
    );
    expect(await HilbertCurveMap.ownerOf(index)).to.equal(user2Addr);
    expect(await HilbertCurveMap.balanceOf(user1Addr)).to.equal(0);
    expect(await HilbertCurveMap.balanceOf(user2Addr)).to.equal(1024);
    for (let i = 0; i < 64 * 64; i++) {
      if (i >= 1024 && i <= 2047) {
        expect(await HilbertCurveMap.ownerOf(i)).to.equal(user2Addr);
      } else {
        expect(await HilbertCurveMap.ownerOf(i)).to.equal(
          ethers.constants.AddressZero
        );
      }
    }
  });
  it("Fail to transfer, occupied length is zero", async function () {
    const index = 1024;
    await HilbertCurveMap.connect(user1).mintLand(index, LandSize.XXLARGE, "");
    await expect(
      HilbertCurveMap.connect(user1).transferFrom(user1Addr, user2Addr, 1000)
    ).to.be.revertedWithCustomError(HilbertCurveMap, "OccupiedLengthIsZero");
    await expect(
      HilbertCurveMap.connect(user1).transferFrom(user1Addr, user2Addr, 1030)
    ).to.be.revertedWithCustomError(HilbertCurveMap, "OccupiedLengthIsZero");
  });
});
