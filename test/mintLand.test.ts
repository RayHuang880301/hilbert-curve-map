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
  it("Success to mint land xsmall", async function () {});
});
