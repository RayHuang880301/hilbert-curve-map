// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IHilbertCurveMap {
    function index2xy(uint256 index) external pure returns (uint256 x, uint256 y);

    function xy2index(uint256 x, uint256 y) external pure returns (uint256 index);

    function ownerOf(uint256 index) external view returns (address owner);

    function balanceOf(address owner) external view returns (uint256 balance);
}