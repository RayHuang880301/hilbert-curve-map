import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { HilbertCurveMap, HilbertCurveMap__factory } from "../typechain-types";
import { Signer } from "ethers";
import { LandSize } from "./config";

describe("Approve", function () {
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
  it("Success to approve xsmall land", async function () {
    const index = 34;
    await HilbertCurveMap.connect(user1).mintLand(index, LandSize.XSMALL, "");
    await HilbertCurveMap.connect(user1).approve(user2Addr, index);
    expect(await HilbertCurveMap.getApproved(index)).to.equal(user2Addr);
    await HilbertCurveMap.connect(user2).transferFrom(
      user1Addr,
      user2Addr,
      index
    );
    expect(await HilbertCurveMap.ownerOf(index)).to.equal(user2Addr);
  });

  it("Success to approve xxlarge land", async function () {
    const index = 0;
    await HilbertCurveMap.connect(user1).mintLand(index, LandSize.XXLARGE, "");
    await HilbertCurveMap.connect(user1).approve(user2Addr, index);
    expect(await HilbertCurveMap.getApproved(index)).to.equal(user2Addr);
    await HilbertCurveMap.connect(user2).transferFrom(
      user1Addr,
      user2Addr,
      index
    );
    expect(await HilbertCurveMap.ownerOf(index)).to.equal(user2Addr);
  });
  it("Fail to approve occupied length is zero", async function () {
    const index = 0;
    await HilbertCurveMap.connect(user1).mintLand(index, LandSize.XXLARGE, "");
    await expect(
      HilbertCurveMap.connect(user1).approve(user2Addr, 1)
    ).to.be.revertedWithCustomError(HilbertCurveMap, "OccupiedLengthIsZero");
  });
});
