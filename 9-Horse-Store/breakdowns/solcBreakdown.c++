// 0x6080604052

//34801561000f575f80fd5b506101718061001d5f395ff3fe608060405234801561000f575f80fd5b506004361061003f575f3560e01c806313c2e77214610043578063b364ca2a14610061578063cdfead2e1461007f575b5f80fd5b61004b61009b565b60405161005891906100c9565b60405180910390f35b6100696100a0565b60405161007691906100c9565b60405180910390f35b61009960048036038101906100949190610110565b6100a8565b005b5f5481565b5f8054905090565b805f8190555050565b5f819050919050565b6100c3816100b1565b82525050565b5f6020820190506100dc5f8301846100ba565b92915050565b5f80fd5b6100ef816100b1565b81146100f9575f80fd5b50565b5f8135905061010a816100e6565b92915050565b5f60208284031215610125576101246100e2565b5b5f610132848285016100fc565b9150509291505056fea264697066735822122044a10ae73c411e24362c029d268ee8d576f2550c178ddd6b61a2395e5a6ecd4164736f6c63430008140033

// Every 2 of the hex character will be an opcode. 

/*
3 section of a bytecode

1. Contract creation -- EntryPoint

2. Runtime code -- What actully gets stored on a blockchain

3. Metadata -- Compiler version and anyother metadatas.

*/

// 1. Contract creation code 
PUSH1 0x80 // [0x80]
PUSH1 0x40 // [0x40 , 0x80]
MSTORE // memory[0x40] = 0x80

/*What is free memory pointer
--> Free memory pointer is the pointer that points the free memory space in the stack. It starts at 0x80 and is stored at 0x40. The value at 0x40 gets automatically updated if we store anything in the memory. It changes from 0x80 to example 0x81 like it.
*/

// what this opcode does is that it reverts if the contract deployment is sent with any bytecodes because it doesn't contain any bytecodes on the constructor.
CALLVALUE // [msg.value]  //2b include in notes
DUP1 // [msg.value , msg.value]
ISZERO // [msg.value == 0 , msg.value]
PUSH2 0x000f // [0x000f, msg.value==0, msg.value]
JUMPI // [msg.value] --> jump to JUMPDEST
PUSH0 // [0x00  , msg.value]
DUP1 // [0x00 , 0x00 , msg.value]
REVERT //[msg.value]


JUMPDEST //[msg.value] 
POP //[]
PUSH2 0x0171 // [0x0171]
DUP1   // [0x0171 , 0x0171]
PUSH2 0x001d // [0x001d , 0x0171 , 0x0171]
PUSH0       // [0x00, 0x001d , 0x0171 , 0x0171]
CODECOPY    //2b included in notes // copies runtime code onto the chain
PUSH0 // [0x00,0x00, 0x001d , 0x0171 , 0x0171]
RETURN 
INVALID

PUSH1 0x80 //[0x80]
PUSH1 0x40 //[0x40, 0x80]
MSTORE //memory[0x40] = 0x80

CALLVALUE // [msg.value]
DUP1 // [msg.value,msg.value]
ISZERO // [msg.value==0 , msg.value]
PUSH2 0x000f //[0x00f , msg.value==0 , msg.value]
JUMPI // [msg.value]
PUSH0
DUP1
REVERT

JUMPDEST //[msg.value]
POP //[]
PUSH1 0x04 //[0x04]
CALLDATASIZE //[size , 0x04]
LT // [size<0x04] // checks if parameters is sent empty

 // This is done to check because this contrct doesn't have any fallback function so if sent any data then reverts. It means there is no any 0x04 is the size of a function selector so if the calldata size is less than function selector then jumpi & revert.

PUSH2 0x003f // [0x003f ,size<0x04]
JUMPI

PUSH0 //[0]
CALLDATALOAD //[calldata]
PUSH1 0xe0 // [0xe0, calldata]
SHR // [function_selector]
DUP1 //[function_selector , function_selector]
PUSH4 0x13c2e772 //[update_horse_num , function_selector, function_selector]
EQ //[update_horse_num==function_selector, function_selector]
PUSH2 0x0043 //[0x0043 , update_horse_num==function_selector, function_selector]
JUMPI 

DUP1 //[function_selector,function_selector]
PUSH4 0xb364ca2a // [read_num_of_horses , function_selector,function_selector]
EQ 
PUSH2 0x0061 // [read_numOf_horses==function_selector , function_selector]
JUMPI //[function_selector]

DUP1 //[function_selector,function_selector]
PUSH4 0xcdfead2e //
EQ
PUSH2 0x007f
JUMPI

JUMPDEST // reverts if the calldata size doesn't matches 0x04(function selector size)
PUSH0
DUP1
REVERT

JUMPDEST //[function_selector]
PUSH2 0x004b //[0x004b, function_selector]
PUSH2 0x009b  //[0x009b, 0x004b, function_selector]
JUMP

JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x0058
SWAP2
SWAP1
PUSH2 0x00c9
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
PUSH2 0x0069
PUSH2 0x00a0
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x0076
SWAP2
SWAP1
PUSH2 0x00c9
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
PUSH2 0x0099
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
DUP2
ADD
SWAP1
PUSH2 0x0094
SWAP2
SWAP1
PUSH2 0x0110
JUMP
JUMPDEST
PUSH2 0x00a8
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH0
SLOAD
DUP2
JUMP
JUMPDEST
PUSH0
DUP1
SLOAD
SWAP1
POP
SWAP1
JUMP
JUMPDEST
DUP1
PUSH0
DUP2
SWAP1
SSTORE
POP
POP
JUMP
JUMPDEST
PUSH0
DUP2
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH2 0x00c3
DUP2
PUSH2 0x00b1
JUMP
JUMPDEST
DUP3
MSTORE
POP
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x20
DUP3
ADD
SWAP1
POP
PUSH2 0x00dc
PUSH0
DUP4
ADD
DUP5
PUSH2 0x00ba
JUMP
JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH0
DUP1
REVERT
JUMPDEST
PUSH2 0x00ef
DUP2
PUSH2 0x00b1
JUMP
JUMPDEST
DUP2
EQ
PUSH2 0x00f9
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
JUMP
JUMPDEST
PUSH0
DUP2
CALLDATALOAD
SWAP1
POP
PUSH2 0x010a
DUP2
PUSH2 0x00e6
JUMP
JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x20
DUP3
DUP5
SUB
SLT
ISZERO
PUSH2 0x0125
JUMPI
PUSH2 0x0124
PUSH2 0x00e2
JUMP
JUMPDEST
JUMPDEST
PUSH0
PUSH2 0x0132
DUP5
DUP3
DUP6
ADD
PUSH2 0x00fc
JUMP
JUMPDEST
SWAP2
POP
POP
SWAP3
SWAP2
POP
POP
JUMP
INVALID
LOG2
PUSH5 0x6970667358
INVALID
SLT
KECCAK256
PREVRANDAO
LOG1
EXP
INVALID
EXTCODECOPY
COINBASE
INVALID
INVALID
CALLDATASIZE
INVALID
MUL
SWAP14
INVALID
DUP15
INVALID
INVALID
PUSH23 0xf2550c178ddd6b61a2395e5a6ecd4164736f6c63430008
EQ
STOP
CALLER