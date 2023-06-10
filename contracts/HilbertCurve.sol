// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library HilbertCurve {
    uint256 private constant MAX_UINT256 = 2**256 - 1;
    uint256 private constant TWO_POW_128 = 2**128;

    error HIndexOutOfRange(uint256 hIndex, uint256 n);
    error OrderGreaterThan128(uint256 n);
    error PointOutOfRange(uint256 x, uint256 y, uint256 n);
    error NotPowOf2(uint256 x);

    /// @notice Get last 2 bits of a uint256
    /// @param x uint256
    /// @return last2bits last 2 bits of x
    function _last2bits(uint256 x) private pure returns (uint256) {
        return x & 3;
    }

    /// @notice Check if uint256 x is power of 2
    /// @param x uint256
    /// @return _isPowOf2 true if x is power of 2
    function isPowOf2(uint256 x) internal pure returns (bool _isPowOf2) {
        if(x == 0) return false;
        return (x & (x - 1)) == 0;
    }

    /// @notice Get power of 2 of uint256 x
    /// @param x uint256
    /// @return pow power of 2 of x
    function getPowOf2(uint256 x) internal pure returns (uint256 pow) {
        if(!isPowOf2(x)) revert NotPowOf2(x);
        while(x > 1) {
            x >>= 1;
            pow++;
        }
        return pow;
    }

    /// @notice 1D Hilbert curve index to 2D cartesian coordinates (x,y) 
    /// @param hIndex 1D Hilbert curve index
    /// @param n order of length of 2D Hilbert curve
    /// @return x 2D cartesian coordinates x
    /// @return y 2D cartesian coordinates y
    function hIndex2xy(uint256 hIndex, uint256 n) internal pure returns (uint256 x, uint256 y) {
        if(n > 128) revert OrderGreaterThan128(n);

        // N: side length of 2D Hilbert curve
        uint256 N = 1 << n;

        // In the case of N = 2**128, the following check will fail due to overflow
        // and the check still work in uint256
        if(n != 128 && hIndex >= N * N) revert HIndexOutOfRange(hIndex, n);
        
        uint256 t = _last2bits(hIndex);
        hIndex >>= 2;

        // if(t == 0) x=0, y=0 (can be omitted)
        // if(t == 1) x=0, y=1 
        // if(t == 2) x=1, y=1
        // if(t == 3) x=1, y=0
        if(t == 1) {
            y = 1;
        } else if(t == 2) {
            x = 1;
            y = 1;
        } else if(t == 3) {
            x = 1;
        }

        uint256 temp;
        //    (s = 4; s <= N; s *= 2)
        // => (s = 2; s <= N / 2; s *= 2)
        // s2 = s / 2; N2 = N / 2;
        uint256 N2 = N / 2;
        for(uint256 s2 = 2; s2 <= N2; s2 <<= 1) {
            t = _last2bits(hIndex);
            hIndex >>= 2;
            if(t == 0) {
                temp = x;
                x = y;
                y = temp;
                continue;
            } else if(t == 1) {
                y = y + s2;
                continue;
            } else if(t == 2) {
                x = x + s2;
                y = y + s2;
                continue;
            } else if(t == 3) {
                temp = x;
                x = s2 - 1 - y;
                y = s2 - 1 - temp;
                x = x + s2;
                continue;
            }
        }
        return (x, y);
    }

    /// @notice 2D cartesian coordinates (x,y) to 1D Hilbert curve index
    /// @param x 2D cartesian coordinates x
    /// @param y 2D cartesian coordinates y
    /// @param n order of length of the 2D Hilbert curve
    /// @return hIndex 1D Hilbert curve index
    function xy2hIndex(uint256 x, uint256 y, uint256 n) internal pure returns (uint256 hIndex) {
        if(n > 128) revert OrderGreaterThan128(n);

        // N: side length of 2D Hilbert curve
        uint256 N = 1 << n;
        if(x >= N || y >= N) revert PointOutOfRange(x, y, n);

        uint256 temp;
        // (s = N; s > 1; s >>= 1), s2 = s / 2
        for(uint256 s2 = N / 2; s2 > 0; s2 >>= 1) {
            hIndex <<= 2;

            // right
            if(x >= s2) {
                // right-top
                if(y >= s2) {
                    hIndex = hIndex + 2;    
                    x = x - s2;
                    y = y - s2;
                    continue;

                // right-bottom
                } else {
                    hIndex = hIndex + 3;
                    temp = y;
                    x = x - s2;
                    y = s2 - 1 - x;
                    x = s2 - 1 - temp;
                    continue;           
                }

            // left
            } else {
                // left-top
                if(y >= s2) {
                    hIndex = hIndex + 1;
                    y = y - s2;
                    continue;

                // left-bottom
                } else {
                    temp = x;
                    x = y;
                    y = temp;
                    continue;
                }
            }
        }
        return hIndex;
    }

    /// @notice Get lead nodes from a Hilbert curve index
    /// @dev Max length of nodes is 128 in the case of n = 2**128
    /// @param hIndex Hilbert curve index
    /// @param n order of length of the 2D Hilbert curve
    /// @return leadNodes the hIndex of lead nodes
    function getLeadNodes(uint256 hIndex, uint256 n) internal pure returns (uint256[] memory leadNodes) {
        leadNodes = new uint256[](n);
        uint256 mask = MAX_UINT256;
        uint256 leadNode;
        for(uint256 i; i < n; i++) {
            // Shift 2 bits to get the next lead node
            mask = mask << 2;
            leadNode = hIndex & mask;
            leadNodes[i] = leadNode;
            // The last lead node is 0
            if(leadNode == 0) break;
        }
        return leadNodes;
    }

    /// @notice Get the node class of a Hilbert curve index
    /// @param hIndex Hilbert curve index
    /// @param n order of length of the 2D Hilbert curve
    /// @return nodeClass the node class of the Hilbert curve index
    function getNodeClass(uint256 hIndex, uint256 n) internal pure returns (uint256 nodeClass) {
        if(n > 128) revert OrderGreaterThan128(n);

        for(uint256 i; i < n; i++) {
            if(hIndex & 3 != 0) break;
            hIndex >>= 2;
            nodeClass++;
        }
        return nodeClass;
    }
}