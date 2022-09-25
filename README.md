# ⚡ YUL

>Assembly-like Intermediate low-level language that can be compiled into EVM bytecode.

The EVM executes bytecode, and this is the output of the Solidity compiler and it is what is stored on the blockchain when a contract is deployed.

However, it is possible to *inject* low-level instructions into Solidity code, using the keyword `assembly` which, despite the name, marks the beginning of a `Yul` block.

### Types

Yul has only one underlying type, which is a 32-byte word.

All other types can and are represented on this. Solidity, for example, is just forcing an interpretation on the data. An example of this can seen with the following code: 

```solidity
function myFunc() external pure returns (type) {
    type x;

    assembly {
        x  := 1
    }
    return x;
}
```

If a *bool* is assigned, the value returned would be interpreted *true*, since bool is represented as 32 bytes ending in either 1 or 0;

If an *address* is assigned, the value returned would be interpreted as *0x0...01*.

Similar behaviour happens with *Int*, *Uint*...

### Basic Operations

Yul has many different basic [instructions](https://docs.soliditylang.org/en/v0.8.16/yul.html#evm-dialect), though different to usual Assembly-like languages, it also includes support for loops.

```yul
for { let i := 0 } lt(i, 5) { i := add(i, 1) }
{
    // Do something
}
```

When it comes to boolean operation, Yul does thing slightly differently, since the truthy evaluation is just one simple rule: 0 = False, otherwise True.

This brings the use of instructions like `iszero()` to negate results from other evaluations, for example.

### Storage Variables

As already mentioned, variables are stored in 32-byte words. These words are assigned a particular `slot`, which is used to reference the position in storage.

In Yul we have access to two main instructions:
- `sload(slot)`: Loads the value stored in the slot.
- `sstore(slot, value)`: Stores the value in the slot.

Inside a Yul block, it is also possible to access a variable's slot by using `.slot` notation. Slots are calculated at compile time.

The following code is an example of these tools in use:

```solidity
uint256 a;
uint256 b;

function getA() external view returns (uint256 val) {
    assembly  {
        val := sload(a.slot)
    }
}

function getSlot(uint256 slot) external view returns (uint256 val) {
    assembly {
        val := sload(slot)
    }
}

function writeSlot(uint256 slot, uint256 val) external {
    assembly {
        sstore(slot, val)
    }
}
```

> However, it is also worth noting that given the code above, it is possible to write and read data from *any* storage slot, regardless of whether it is part of the space used by the contract's declared variables.

Another common situation is having to deal with variables that share the same storage slot:
```solidity
uint128 a; // Slot 0
uint128 b; // Slot 0
```
In order to access these, we would need to make use of the `offset` notation to (dynamically) know how much a certain slot needs to be shifted in order to access the expected value.

> Though these values are also known at compile-time and won't change through time, so they could just be hardcoded instead.

It is possible to do the following:

```solidity
uint128 a = 1;
uint128 b = 2;

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
```
Writing variables can be tricky, because Yul does not work with smaller sizes than 32 bytes when it comes to writing data.

This means that bit-masks and bit-shifting will need to be used.

```solidity
uint128 a = 1;
uint32 b = 2;
uint96 c = 3;

function writeA(uint128 _a) external {
    assembly {
        let cleared := and(shl(mul(8,16), 0xffffffffffffffffffffffffffffffff), sload(0))
        
        sstore(0, or(cleared, _a))
    }
}

function writeB(uint32 _b) external {
    assembly {
        let mask := not(shr(mul(8,16),0xffffffff))
        let cleared := and(mask, sload(0))

        sstore(0, or(cleared, shl(mul(8,b.offset), _b)))
    }
}

function writeC(uint96 _c) external {
    assembly {
        let mask := not(shl(mul(8, c.offset), 0xffffffffffffffffffffffff))
        let cleared := and(mask, sload(0))

        sstore(0, or(cleared, shl(mul(8, c.offset), _c)))
    }
}
```

> Even when the parameter is defined as a uint128, uint96... the value used in Yul is still the 32-byte word, hence the need to shift it into place.

### Dynamic Storage

When it comes to Solidity's data structures, accessing and writing becomes a little bit tricky. Knowledge on how Solidity encodes these is necessary, but fortunately it is a pretty straight forward process.

When it comes to Fixed-Length Arrays, each variable is stored in a sequential manner, just as if they had been declared independently.

In order to access them, it is as simple as adding the index of the variable to the slot of the array. That is:

```solidity
uint256[3] arr = [1,2,3];

function readArr(uint256 i) external view returns (bytes32 v) {
    assembly {
        v := sload(add(arr1.slot, i))
    }
}
```
> And just as in a normal scenario, if the variables don't completely fill the slot, special consideration will be needed when trying to access/write them.

For Dynamic-Size Arrays, it is now needed to follow Solidity's encoding rules. We must first find the array's slot. At this location, the array's length will be stored. The values, however, are found sequentially at a different location, obtained through hashing (keccak256) the array's slot.

```solidity
uint256[] public arr2;

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
```

For Mappings, we must hash (keccak256) the key with the slot, and that will give us the slot in which the value is stored.

```solidity
mapping(uint256 => bool) public m;

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
```

Things get fun when nested dynamic structures happen, but the concept is still the same.

```solidity
mapping(uint256 => uint256[]) public marr;

function readMarr(uint256 k, uint256 i) external view returns (bytes32 v) {
    bytes32 slot;

    assembly {
        slot := marr.slot
    }

    bytes32 location = keccak256(abi.encode(keccak256(abi.encode(k, slot))));

    assembly {
        v := sload(add(location, i))
    }
}
```

or even more fun

```solidity
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

```

Writing to storage in these situations is nothing special. The process of finding the location slot is all that matters.