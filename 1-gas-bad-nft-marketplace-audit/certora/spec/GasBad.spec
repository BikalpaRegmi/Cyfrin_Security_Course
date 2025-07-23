/*
* Verification of GasBad nft marketplace
*/

using GasBadNftMarketplace as gasBadNftMarketplace ;
using NftMarketplace as nftMarketplace ;

methods{
    function getListing(address nftAddress, uint256 tokenId) external returns(INftMarketplace.Listing) envfree;
    function getProceeds(address seller) external returns(uint256) envfree;

    function _.safeTransferFrom(address,address,uint256) external => DISPATCHER(true) ;
    function _.onERC721Received(address, address, uint256, bytes) external => DISPATCHER(true) ; 
}

ghost mathint listingUpdateCount {
    init_state axiom listingUpdateCount == 0;
    //initial state will be zero
    //require such to be true
}
ghost mathint log4Count {
    init_state axiom log4Count ==0;
}

hook Sstore s_listings[KEY address nftAddress][KEY uint256 tokenId].price uint256 price {
    listingUpdateCount=listingUpdateCount+1 ;
}

//syntax from certora docs
hook LOG4(uint256 offset , uint256 size , bytes32 t1, bytes32 t2, bytes32 t3, bytes32 t4){
    log4Count = log4Count+1 ;
}

/////////rules////////////

invariant anytime_mapping_updated_emit_event() 
listingUpdateCount <= log4Count ;

rule calling_each_function_should_result_in_each_contract_having_same_state(method f , method f2){
//ARRANGE
require(f.selector == f2.selector) ;

env e ;
calldataarg args ;

address listAddr ;
uint256 tokenId ;
address seller ;

require(gasBadNftMarketplace.getProceeds(e,seller) == nftMarketplace.getProceeds(e,seller)) ;
require(gasBadNftMarketplace.getListing(e,listAddr,tokenId).price == nftMarketplace.getListing(e,listAddr,tokenId).price) ;
require(gasBadNftMarketplace.getListing(e,listAddr,tokenId).seller == nftMarketplace.getListing(e,listAddr,tokenId).seller) ;

//ACT
gasBadNftMarketplace.f(e,args) ;
nftMarketplace.f2(e,args) ;

//ASSERT
assert(gasBadNftMarketplace.getProceeds(e,seller) == nftMarketplace.getProceeds(e,seller)) ;
assert(gasBadNftMarketplace.getListing(e,listAddr,tokenId).price == nftMarketplace.getListing(e,listAddr,tokenId).price) ;
assert(gasBadNftMarketplace.getListing(e,listAddr,tokenId).seller == nftMarketplace.getListing(e,listAddr,tokenId).seller) ;

}