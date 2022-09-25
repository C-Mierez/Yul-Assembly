// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract YulBasicOps {
    uint128 public a = 1;
    uint32 public b = 2;
    uint96 public c = 3;

    function getSlot() external view returns (bytes32 val) {
        assembly {
            val := sload(c.slot)
        }
    }

    function getSlot2() external view returns (bytes32 val) {
        assembly {
            val := sload(1)
        }
    }

    function getAYul() external view returns (bytes32 val) {
        assembly {
            val := and(0xffffffffffffffffffffffffffffffff, sload(a.slot))
        }
    }

    function getBYul() external view returns (bytes32 val) {
        assembly {
            val := shr(mul(8, b.offset), sload(a.slot))
        }
    }

    function writeA(uint128 _a) external {
        assembly {
            let cleared := and(
                shl(mul(8, 16), 0xffffffffffffffffffffffffffffffff),
                sload(0)
            )

            sstore(0, or(cleared, _a))
        }
    }

    function writeB(uint32 _b) external {
        assembly {
            let mask := not(shr(mul(8, 16), 0xffffffff))
            let cleared := and(mask, sload(0))

            sstore(0, or(cleared, shl(mul(8, b.offset), _b)))
        }
    }

    function writeC(uint96 _c) external {
        assembly {
            let mask := not(shl(mul(8, c.offset), 0xffffffffffffffffffffffff))
            let cleared := and(mask, sload(0))

            sstore(0, or(cleared, shl(mul(8, c.offset), _c)))
        }
    }
}
