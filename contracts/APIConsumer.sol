// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */

contract APIConsumer is ChainlinkClient {
    using Chainlink for Chainlink.Request;
      
    address private oracle;
    bytes32 private boolJobId;
    bytes32 private stringJobId;
    uint256 private fee;
    bytes32 private requestIdentifier;  

    mapping(bytes32 => string) internal requestNFTmap;
    mapping(string => uint8) public nftVerificationMap;  

    mapping(bytes32 => address) internal requestTwitterAccountmap;
    mapping(address => string) public twitterAccountVerificationMap;

    event RequestComplete(
        string nftRequestString
    );

   
    constructor() {
        setPublicChainlinkToken();
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        boolJobId = "bc746611ebee40a3989bbe49e12a02b9"; 
        stringJobId = "7401f318127148a894c00c292e486ffd";
        fee = 0.1 * 10 ** 18; // (Varies by network and job)
    }

    // UTILS
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i =0;
        for (i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }    

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function requestNFTVerification(string memory _queryParams) public returns (bytes32 requestId)
    {
        Chainlink.Request memory request = buildChainlinkRequest(boolJobId, address(this), this.fulfillNFTRequest.selector);
        request.add("get", strConcat("https://the-collective-truth.herokuapp.com/nft/verify?",_queryParams,"","",""));
        
        request.add("path", "success");        
        requestIdentifier = sendChainlinkRequestTo(oracle, request, fee);
        requestNFTmap[requestIdentifier] = _queryParams;
        return requestIdentifier;
    }
    
    /**
     * Receive the response in the form of uint256
     */ 
    function fulfillNFTRequest(bytes32 _requestId, bool _result) public recordChainlinkFulfillment(_requestId)
    {
        string memory nftRequestString = requestNFTmap[_requestId];
        nftVerificationMap[nftRequestString] = _result ? 1 : 2; // update NFT verification result
        emit RequestComplete(nftRequestString); // event to be listened by the client
    }   

    function getNFTRequestStatus(string memory _queryParams) public view returns (uint8){
        return nftVerificationMap[_queryParams];
    }

    // Twitter Account Verification

    function requestTwitterVerification(string memory _tweet, string memory _randid) public returns (bytes32 requestId)
    {
        Chainlink.Request memory request = buildChainlinkRequest(stringJobId, address(this), this.fulfillTwitterAccountRequest.selector);
        request.add("get", strConcat("https://the-collective-truth.herokuapp.com/twitter/verify?randid=",_randid,"&tweet=",_tweet,""));        
        request.add("path", "username");        
        requestIdentifier = sendChainlinkRequestTo(oracle, request, fee);
        requestTwitterAccountmap[requestIdentifier] = msg.sender;
        return requestIdentifier;
    }

    /**
     * Receive the response in the form of uint256
     */ 
    function fulfillTwitterAccountRequest(bytes32 _requestId, bytes32 _username) public recordChainlinkFulfillment(_requestId)
    {
        address _user = requestTwitterAccountmap[_requestId];
        twitterAccountVerificationMap[_user] = bytes32ToString(_username); // update Twitter Account username
        emit RequestComplete("_user"); // event to be listened by the client
    }

    function getTwitterVerificationStatus(address _account) public view returns (string memory){
        return twitterAccountVerificationMap[_account];
    }

    function withdrawLink() external {
        ERC20 tokenContract = ERC20(0xa36085F69e2889c224210F603D836748e7dC0088);
        tokenContract.transfer(msg.sender, tokenContract.balanceOf(address(this)));
    } 
}
