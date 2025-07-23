/*
* Verifications of NFTMOCK.
*/

methods{
    function totalSupply() external returns uint256 envfree ;
    function balanceBefore() external returns uint256 envfree;
    function mint() external ;
}

// rule sanity{
//     satisfy:true;
// }

// invariant totalSupplyIsNotNegative()
// totalSupply() >= 0 ;

// rule Should_Mint_One_NFT() {
// //arrange
// env e;
// address minter ;
// require e.msg.value == 0 ;
// require e.msg.sender == minter ;
// mathint balanceBefore = to_mathint(balanceOf(minter)) ;

// //act
// currentContract.mint(e) ;

// //assert

// // assert to_mathint(balanceOf(minter)==balanceBefore+1, "Only 1 nft should be minted") ;
// assert to_mathint(balanceOf(minter)) == balanceBefore + 1, "Only 1 nft should be minted" ;

// }

//This is called parametric rule check
// rule no_change_to_total_supply(method f) {
// uint256 totalSupplyBefore = totalSupply();

// env e ;
// calldataarg args;
// f(e , args) ;

// assert(totalSupply==totalSupplyBefore , "Total Supply shouldn't change")
// }