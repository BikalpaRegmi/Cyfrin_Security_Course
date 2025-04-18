### [H-1] The variables stored in a blockchain are visible to anyone even if the visibility keywords are private.

**Description :** Every data on a blockchain is visible to anyone, and can be read directly from blockchain. The `PasswordStore::s_password` is intended to be a private variable and can only be accesed through `PasswordStore::getPassword` function which is intended to be the owner.

We show one such method of reading any offchain data below.

**Impact :** Any one can read the private password , severly breaking the functionality of the protocol.

**Proof of Concept :** (Proof of code)

The below test case shows how anyone can read the password directly from the blockchain

1.Create a locally running chain
```bash 
make anvil
```

2.Deploy the contract to the chain
```
make deploy
```

3.Run the storage tool
We use `1` because thats the storage slot for `s_password` in the contract.
```
cast storage <ADDRESS_HERE> 1 --rpc-url http://127.0.0.1:8545

```

you will get an hash output

you can then parse that hex to a string with : 
```
 cast parse-bytes32-string _Above_hash_string 
```

And get an output of: 
```
myPassword
```


**Recommended Mitigation :** Due to this, the overall architecture of a contract should be rethought. One can encrypt the password offchain and then encrypt the password onchain. This would require the user to remember the password offchain to decrypt the password. However, you would also likely want to remove the view function as you would not want the user to accidently send a transaction with the password that decrypt your password. 

<hr><br>

### [H-2] `PasswordStore::setPassword` has no access control, meaning the non owner can easily change the password.

**Description :** The `PasswordStore::setPassword` function is set to be an `external` function, However, the natspecs of the function and overall function of a smart contract is that `This function allows only the owner to set the new password`.

```javascript
function setPassword(string memory newPassword) external {
@>//@audit there are no access controls
        s_password = newPassword;
        emit SetNetPassword();
    }
```

**Impact :** Anyone can change the password of a contract, severly breaking the contract intended functionality. 

**Proof of Concept :** Add the following to the PasswordStore.t.sol file :

<details>
<summary>Code</summary>

```javascript
 function test_anyone_can_set_password (address randomAddress) public {
        vm.assume(randomAddress!=owner);
        vm.prank(randomAddress);
        string memory expectedPassword = "MYNEWPASSWORD";
        passwordStore.setPassword(expectedPassword);
        vm.prank(owner);
        string memory actualPassword = passwordStore.getPassword();
        assertEq(actualPassword,expectedPassword);
    }
```
</details>

**Recommended Mitigation:** Add an access control condition to `PasswordStore::setPassword` function.

```javascript
if(msg.sender!=owner){
    revert PasswordStore_NotOwner();
}
```
<hr><br>


### [I-1] The `PasswordStore::getPassword()` natspec indicates a parameter that doesn't exists, causing the natspec be incorrect.

**Description:** 
```javascript
/*
     * @notice This allows only the owner to retrieve the password.
@>    * @param newPassword The new password to set.
     * @audit This function lacks params and it is not required.
     */
    function getPassword() external view returns (string memory) {}
         
```
The `PasswordStore::getPassword` function signature is `getPassword()` which the natspec says it should be `getPassword(string)`.

**Impact:**  The natspec is incorrect.

**Recommended Mitigation:** Remove the incorrect natspec line.
```diff
- * @param newPassword The new password to set.
```
