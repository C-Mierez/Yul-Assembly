// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract YulTypes {
    // Basic example of type usage in Yul.
    // Yul only has one type, which is the 32-byte word.

    function getNumber() external pure returns (uint256) {
        uint256 num;

        assembly {
            num := 42
        }

        return num;
    } // Returns num: 42

    function getHex() external pure returns (uint256) {
        uint256 h;

        assembly {
            h := 0x2a
        }

        return h;
    } // Returns h: 42

    function getString() external pure returns (string memory) {
        bytes32 str;

        assembly {
            str := "Helllo from Yul"
        }

        return string(abi.encode(str));
    } // Returns str: "Helllo from Yul"

    function getBool() external pure returns (bool) {
        bool b;

        assembly {
            b := 1
        }

        return b;
    } // Returns b: true (Since bool is represented as a 32-byte 0...01)

    // All of these functions make use of the same underlying type. A 32-byte word.
}
