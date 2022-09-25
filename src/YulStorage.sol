// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract YulStorage {
    uint144[3] public arr1;
    uint256[] public arr2;
    mapping(uint256 => bool) public m;

    mapping(uint256 => uint256[]) public marr;

    constructor() {
        arr1 = [10, 11, 12];

        arr2 = [1, 2, 3, 4, 5];

        m[1] = true;
        m[3] = true;

        marr[1] = [11, 12, 13];
        marr[2] = [21, 22, 23];

        msa[1] = Str(8, arr2);
    }

    function readSlot(uint256 s) external view returns (bytes32 v) {
        assembly {
            v := sload(s)
        }
    }

    function readArr1(uint256 i) external view returns (bytes32 v) {
        assembly {
            v := sload(add(arr1.slot, i))
        }
    }

    function readArr2(uint256 i) external view returns (bytes32 v) {
        bytes32 slot;

        assembly {
            slot := arr2.slot
        }

        bytes32 location = keccak256(abi.encode(slot));

        assembly {
            v := sload(add(location, i))
        }
    }

    function readM(uint256 k) external view returns (bytes32 v) {
        bytes32 slot;

        assembly {
            slot := m.slot
        }

        bytes32 location = keccak256(abi.encode(k, slot));

        assembly {
            v := sload(location)
        }
    }

    function readMarr(uint256 k, uint256 i) external view returns (bytes32 v) {
        bytes32 slot;

        assembly {
            slot := marr.slot
        }

        bytes32 location = keccak256(
            abi.encode(keccak256(abi.encode(k, slot)))
        );

        assembly {
            v := sload(add(location, i))
        }
    }

    struct Str {
        uint256 a;
        uint256[] b;
    }

    mapping(uint256 => Str) public msa;

    function readMsa(uint256 k, uint256 i) external view returns (bytes32 v) {
        bytes32 slot;

        assembly {
            slot := msa.slot
        }

        bytes32 location = keccak256(abi.encode(k, slot));

        assembly {
            location := add(location, 1)
        }
        location = keccak256(abi.encode(location));

        assembly {
            v := sload(add(location, i))
        }
    }
}
