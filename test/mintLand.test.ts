import { expect } from "chai";
import { ethers } from "hardhat";
import { HilbertCurveMap, HilbertCurveMap__factory } from "../typechain-types";
import { Signer } from "ethers";
import { LandSize } from "./config";

describe("Mint land", function () {
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
  it("Fail to mint land case1", async function () {
    await expect(
      HilbertCurveMap.connect(user1).mintLand(34, LandSize.SMALL, "")
    ).to.be.revertedWithCustomError(HilbertCurveMap, "NodeClassLtSize");
  });
  it("Fail to mint land case2", async function () {
    await HilbertCurveMap.connect(user1).mintLand(43, LandSize.XSMALL, "");
    await expect(
      HilbertCurveMap.connect(user1).mintLand(0, LandSize.LARGE, "")
    ).to.be.revertedWithCustomError(HilbertCurveMap, "LandIsNotFree");
  });
  it("Fail to mint land case3", async function () {
    await HilbertCurveMap.connect(user1).mintLand(40, LandSize.SMALL, "");
    await expect(
      HilbertCurveMap.connect(user1).mintLand(42, LandSize.XSMALL, "")
    ).to.be.revertedWithCustomError(HilbertCurveMap, "LandIsNotFree");
  });
  it("Fail to mint land case4", async function () {
    await HilbertCurveMap.connect(user1).mintLand(8192, LandSize.XSMALL, "");
    await expect(
      HilbertCurveMap.connect(user1).mintLand(8192, LandSize.XSMALL, "")
    ).to.be.revertedWithCustomError(HilbertCurveMap, "LandIsNotFree");
  });
  it("Success to mint land case1", async function () {
    await HilbertCurveMap.connect(user1).mintLand(34, LandSize.XSMALL, "");
    await HilbertCurveMap.connect(user1).mintLand(32, LandSize.XSMALL, "");
    expect(await HilbertCurveMap.ownerOf(34)).to.equal(user1Addr);
    expect(await HilbertCurveMap.ownerOf(32)).to.equal(user1Addr);
    expect(await HilbertCurveMap.balanceOf(user1Addr)).to.equal(2);
  });
  it("Success to mint land case2", async function () {
    await HilbertCurveMap.connect(user1).mintLand(32, LandSize.SMALL, "");
    expect(await HilbertCurveMap.ownerOf(32)).to.equal(user1Addr);
    expect(await HilbertCurveMap.balanceOf(user1Addr)).to.equal(4);
  });
  it("Success to mint land case3", async function () {
    await HilbertCurveMap.connect(user1).mintLand(32, LandSize.SMALL, "");
    expect(await HilbertCurveMap.ownerOf(32)).to.equal(user1Addr);
    expect(await HilbertCurveMap.balanceOf(user1Addr)).to.equal(4);
  });
  it("Success to mint land case4", async function () {
    await HilbertCurveMap.connect(user1).mintLand(32, LandSize.SMALL, "");
    await HilbertCurveMap.connect(user1).mintLand(41, LandSize.XSMALL, "");
    expect(await HilbertCurveMap.balanceOf(user1Addr)).to.equal(5);
  });
  it("Success to mint land case5", async function () {
    await HilbertCurveMap.connect(user1).mintLand(0, LandSize.MEDIUM, "");
    await HilbertCurveMap.connect(user1).mintLand(41, LandSize.XSMALL, "");
    expect(await HilbertCurveMap.balanceOf(user1Addr)).to.equal(17);
  });
  it("Success to mint land case6", async function () {
    await HilbertCurveMap.connect(user1).mintLand(0, LandSize.MEDIUM, "");
    await HilbertCurveMap.connect(user1).mintLand(32, LandSize.SMALL, "");
    expect(await HilbertCurveMap.balanceOf(user1Addr)).to.equal(20);
  });
  it("Success to mint land case7", async function () {
    await HilbertCurveMap.connect(user1).mintLand(8192, LandSize.XXLARGE, "");
    expect(await HilbertCurveMap.balanceOf(user1Addr)).to.equal(1024);
  });
  it("Success to mint land case8", async function () {
    await HilbertCurveMap.connect(user1).mintLand(8192, LandSize.XLARGE, "");
    await HilbertCurveMap.connect(user1).mintLand(9215, LandSize.XSMALL, "");
    expect(await HilbertCurveMap.balanceOf(user1Addr)).to.equal(257);
  });
  it("Success to mint land case9", async function () {
    await HilbertCurveMap.connect(user1).mintLand(32, LandSize.XSMALL, "");
    await HilbertCurveMap.connect(user1).mintLand(33, LandSize.XSMALL, "");
    await HilbertCurveMap.connect(user1).mintLand(34, LandSize.XSMALL, "");
    await HilbertCurveMap.connect(user1).mintLand(35, LandSize.XSMALL, "");
    expect(await HilbertCurveMap.balanceOf(user1Addr)).to.equal(4);
  });
});
