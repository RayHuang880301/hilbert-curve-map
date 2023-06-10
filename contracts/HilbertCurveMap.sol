// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {HilbertCurve} from "./HilbertCurve.sol";
import {IHilbertCurveMap} from "./IHilbertCurveMap.sol";
enum LandSize {
    XSMALL,  // 0: 1 * 1
    SMALL,   // 1: 2 * 2
    MEDIUM,  // 2: 4 * 4
    LARGE,   // 3: 8 * 8
    XLARGE,  // 4: 16 * 16
    XXLARGE  // 5: 32 * 32
}

contract HilbertCurveMap is ERC721, IHilbertCurveMap {
    uint256 private constant MAX_LENGTH_ORDER = 128;
    mapping (uint256 => string) private _tokenURIs;

    constructor() ERC721("HilbertCurveMap", "HCM") {
    }

    function mintLand(address to, uint256 index) external {
        _mint(to, index);
    }
    function index2xy(uint256 index) external pure returns (uint256 x, uint256 y) {
        return HilbertCurve.hIndex2xy(index, MAX_LENGTH_ORDER);
    }

    function xy2index(uint256 x, uint256 y) external pure returns (uint256 index) {
        return HilbertCurve.xy2hIndex(x, y, MAX_LENGTH_ORDER);
    }

    function ownerOf(uint256 index) public override(ERC721, IHilbertCurveMap) view returns (address owner) {
    }

    function balanceOf(address owner) public override(ERC721, IHilbertCurveMap) view returns (uint256 balance) {
    }

    function tokenURI(uint256 tokenId) public override view returns (string memory uri) {
        return _tokenURIs[tokenId];
    }
}