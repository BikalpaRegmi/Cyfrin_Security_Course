## [M-1] Looping through players array to check for duplicates in `PuppyRaffle::enterRaffle` is a potential DoS vector, incrementing gas costs for future entrants

### Description:
The `PuppyRaffle::enterRaffle` function has a duplicate checking mechanism that loops through the `players` array to check for duplicates. However, the longer the `PuppyRaffle::players` array is, the more checks a new player will have to make. This means that the gas costs for players who enter right when the raffle starts will be dramatically lower than those who enter later. Every additional play in the `players` array is an additional check the loop will have to make.

> **Note to students:** This next line would likely be its own finding itself. However, we haven’t taught you about MEV yet, so we are going to ignore it.

Additionally, this increased gas cost creates front-running opportunities where malicious users can front-run another raffle entrant’s transaction, increase its costs, so their enter transaction fails.

---

### Impact:
The impact is two-fold:

1. The gas costs for raffle entrants will greatly increase as more players enter the raffle.  
2. Front-running opportunities are created for malicious users to increase the gas costs of other users, so their transaction fails.

---

### Proof of Concept:

If we have 2 sets of 100 players enter, the gas costs will be as such:
- **1st 100 players**: 6,251,420  
- **2nd 100 players**: 18,066,229  

This is more than **3x** as expensive for the second set of 100 players!

This is due to the `for` loop in the `PuppyRaffle::enterRaffle` function.

Place the following test into `PuppyRaffleTest.t.sol`

```javascript

function testDenailOfService() public {
        vm.txGasPrice(1);
     address[] memory players = new address[](100);

     for(uint i = 0 ; i<100 ; ++i){
        players[i] = address(i);
     }
 uint gasStartFirst = gasleft();
     puppyRaffle.enterRaffle{value:entranceFee * players.length}(players);
     uint gasEndFirst = gasleft();
     uint gasUsedFirst = (gasStartFirst-gasEndFirst)*tx.gasprice ;
     console.log("gas cost of first 100 players is " , gasUsedFirst);

address[] memory newPlayers = new address[](100);
     for(uint i = 0 ; i<100 ; ++i){
        newPlayers[i] = address(i+100) ;
     }

uint gas2StartPrice = gasleft();

puppyRaffle.enterRaffle{value:entranceFee*newPlayers.length}(newPlayers);
uint gas2EndPrice = gasleft();

uint gasUsedSecond = (gas2StartPrice-gas2EndPrice)*tx.gasprice;

console.log("gas cost of second 100 players is ",gasUsedSecond);

assert(gasUsedSecond>gasUsedFirst);
    } 

```

**Recommendation**

1. Consider allowing duplicates. User can create new wallet anyways, so the duplicate check wont prevent a person to enter multiple times.
2. Consider using mappings to duplicate. This will allow you to check constant in constant time rather that linear time.

```solidity
mapping(address => uint256) public addressToRaffleId;
uint256 public raffleId = 0;

function enterRaffle(address[] memory newPlayers) public payable {
    require(msg.value == entranceFee * newPlayers.length, 
        "PuppyRaffle: Must send enough to enter raffle");

    for (uint256 i = 0; i < newPlayers.length; i++) {
        players.push(newPlayers[i]);
        addressToRaffleId[newPlayers[i]] = raffleId;
    }

    // Check for duplicates only from the new players
    for (uint256 i = 0; i < newPlayers.length; i++) {
        require(addressToRaffleId[newPlayers[i]] != raffleId, 
            "PuppyRaffle: Duplicate player");
    }

    emit RaffleEnter(newPlayers);
}
```

Removed Code:

```solidity
// Check for duplicates
for (uint256 i = 0; i < players.length; i++) {
    for (uint256 j = i + 1; j < players.length; j++) {
        require(players[i] != players[j], 
            "PuppyRaffle: Duplicate player");
    }
}
