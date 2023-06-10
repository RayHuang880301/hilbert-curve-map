// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {HilbertCurve} from  "./HilbertCurve.sol";
import {IHilbertCurveMap} from "./IHilbertCurveMap.sol";

contract SimpleMap is Context, ERC165, IERC721, IERC721Metadata, Ownable, IHilbertCurveMap {
    // Token name
    string private _name;
    // Token symbol
    string private _symbol;
    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;
    // Mapping owner address to token count
    mapping(address => uint256) private _balances;
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 constant LENGTH_ORDER = 32;
    uint256 constant MAX_H_INDEX = 1 << (LENGTH_ORDER * 2); // 2^LENGTH_ORDER * 2^LENGTH_ORDER - 1
    uint8 constant MAX_LAND_SIZE = uint8(type(LandSize).max);
    // hIndex => occupyInfo
    mapping (uint256 => OccupyInfo) internal _occupyInfos;
    mapping (uint256 => string) internal _tokenURIs;

    enum LandSize {
        XSMALL,  // 0: 1 * 1
        SMALL,   // 1: 2 * 2
        MEDIUM,  // 2: 4 * 4
        LARGE,   // 3: 8 * 8
        XLARGE,  // 4: 16 * 16
        XXLARGE  // 5: 32 * 32
    }

    struct OccupyInfo {
        uint128 length; // LENGTH_ORDER must be less than 64
        uint128 occupiedClass;
    }

    error HIndexOutOfRange(uint256 hIndex);
    error NodeClassLtSize(uint256 nodeClass, uint256 size);
    error LandIsNotFree(uint256 hIndex, uint256 size);

    event LandMinted(address indexed owner, uint256 indexed tokenId, uint256 hIndex, LandSize landSize);

    constructor() {
        _name = "SimpleMap";
        _symbol = "SIMPLEMAP";
    }

    function mintLand(uint256 hIndex, LandSize landSize, string memory _tokenURI) external payable {
        if(hIndex >= MAX_H_INDEX) revert HIndexOutOfRange(hIndex);

        uint256 size = uint256(landSize);
        uint256 nodeClass = HilbertCurve.getNodeClass(hIndex, LENGTH_ORDER);
        if(nodeClass < size) revert NodeClassLtSize(nodeClass, size);

        uint256[] memory leadNodes = HilbertCurve.getLeadNodes(hIndex, LENGTH_ORDER);
        if(!_isFreeLand(hIndex, leadNodes, size)) revert LandIsNotFree(hIndex, size);
        _occupy(hIndex, leadNodes, size);

        address sender = _msgSender();
        uint256 tokenId = hIndex;
        _tokenURIs[tokenId] = _tokenURI;
        uint256 num = 1 << (size * 2);
        _safeMint(sender, tokenId, num);

        emit LandMinted(sender, tokenId, hIndex, landSize);
    }

    function _isFreeLand(uint256 hIndex, uint256[] memory leadNodes, uint256 size) internal view returns(bool) {
        // Someone has bought this land
        uint256 mask = 1 << size;
        if(_occupyInfos[hIndex].occupiedClass | mask == _occupyInfos[hIndex].occupiedClass)
            return false;

        uint256 leadNode;
        OccupyInfo storage occupyInfo;
        for (uint256 classIndex; classIndex < MAX_LAND_SIZE; classIndex++) {
            leadNode = leadNodes[classIndex];
            occupyInfo = _occupyInfos[leadNode];
            // Someone has bought a larger land which containing your chosen land
            if(occupyInfo.length > 0 && occupyInfo.length > hIndex - leadNode) 
                return false;
        }
        return true;
    }

    function _occupy(uint256 hIndex, uint256[] memory leadNodes, uint256 size) internal {
        // 1D Hilbert curve length
        uint128 hLength = uint128(1 << (size * 2));
        _occupyInfos[hIndex].length = hLength;

        // occupy self
        uint128 mask = 1;
        _occupyInfos[hIndex].occupiedClass = _occupyInfos[hIndex].occupiedClass | mask;
        
        uint256 leadNode;
        for (uint256 classIndex; classIndex < MAX_LAND_SIZE ; classIndex++) {
            leadNode = leadNodes[classIndex];
            mask = uint128(1 << (classIndex + 1));
            OccupyInfo storage occupyInfo = _occupyInfos[leadNode];
            occupyInfo.occupiedClass = occupyInfo.occupiedClass | mask;
        }
    }

    function isFreeLand(uint256 hIndex, LandSize landSize) external view returns (bool) {
        uint256 size = uint256(landSize);
        uint256[] memory leadNodes = HilbertCurve.getLeadNodes(hIndex, LENGTH_ORDER);
        return _isFreeLand(hIndex, leadNodes, size);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    function index2xy(uint256 hIndex) external pure returns (uint256 x, uint256 y) {
        return HilbertCurve.hIndex2xy(hIndex, LENGTH_ORDER);
    }

    function xy2index(uint256 x, uint256 y) external pure returns (uint256 hIndex) {
        return HilbertCurve.xy2hIndex(x, y, LENGTH_ORDER);
    }

    function getLeadNodes(uint256 hIndex) external pure returns (uint256[] memory leadNodes) {
        return HilbertCurve.getLeadNodes(hIndex, LENGTH_ORDER);
    }

    function getNodeClass(uint256 hIndex) external pure returns (uint256 nodeClass) {
        return HilbertCurve.getNodeClass(hIndex, LENGTH_ORDER);
    }

    function ownerOf(uint256 hIndex) public view virtual override(IERC721, IHilbertCurveMap) returns (address) {
        uint256[] memory leadNodes = HilbertCurve.getLeadNodes(hIndex, LENGTH_ORDER);
        // if occupy length is 1, the 1x1 land is owned by the owner of hIndex
        if(_occupyInfos[hIndex].length == 1) return _ownerOf(hIndex);
        
        uint256 leadNode;
        OccupyInfo storage occupyInfo;
        for(uint256 i; i < MAX_LAND_SIZE; i++) {
            leadNode = leadNodes[i];
            occupyInfo = _occupyInfos[leadNode];
            // if occupy length includes hIndex, the land is owned by the owner of leadNode
            if(occupyInfo.length > hIndex - leadNode) return _ownerOf(leadNode);
        }
        return address(0);
    }

    function _safeMint(address to, uint256 tokenId, uint256 num) internal {
        _mint(to, tokenId, num);
        require(
            _checkOnERC721Received(address(0), to, tokenId, ""),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId, uint256 num) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += num;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    function _burn(uint256 tokenId, uint256 num) internal {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= num;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        uint256 num = _occupyInfos[tokenId].length;

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= num;
            _balances[to] += num;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

        function balanceOf(address owner) public view virtual override(IERC721, IHilbertCurveMap) returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }


    /* ========== REFERENCES FROM OPENZEPPELIN ERC721 ========== */

    function name() external view virtual returns (string memory) {
        return _name;
    }

    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }


    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}