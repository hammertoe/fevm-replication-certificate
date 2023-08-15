// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { MarketAPI } from "@zondax/filecoin-solidity/contracts/v0.8/MarketAPI.sol";
import { CommonTypes } from "@zondax/filecoin-solidity/contracts/v0.8/types/CommonTypes.sol";
import { MarketTypes } from "@zondax/filecoin-solidity/contracts/v0.8/types/MarketTypes.sol";

contract ReplicationCertificate is ERC721, Ownable {

    mapping (uint256 => string) public tokenIdToPieceCid;
    mapping (string => uint64[]) public pieceCidToDealIds;
    mapping (uint64 => int64) public dealIdToEnd;

    constructor() ERC721("ReplicationCertificate", "REP") {}

    function safeMint(address to, uint256 tokenId, string memory pieceCid, uint64[] memory dealIds) public onlyOwner {
        _safeMint(to, tokenId);
        tokenIdToPieceCid[tokenId] = pieceCid;
        pieceCidToDealIds[pieceCid] = dealIds;
        uint64 dealId = dealIds[0];
        MarketTypes.GetDealTermReturn memory dealTerm = MarketAPI.getDealTerm(dealId);
        dealIdToEnd[dealId] = CommonTypes.ChainEpoch.unwrap(dealTerm.end);
    }

    function verify(uint256 tokenId) public view returns (uint32) {
        uint32 replicas = 0;
        uint64 grace = 100;
        for (uint i = 0; i < pieceCidToDealIds[tokenIdToPieceCid[tokenId]].length; i++) {     
            uint64 dealId = pieceCidToDealIds[tokenIdToPieceCid[tokenId]][i];
            int64 end = dealIdToEnd[dealId];
            if (block.timestamp > uint64(end) + grace) {
                replicas++;
            }
        }

       return replicas;
 //       MarketTypes.GetDealTermReturn memory dealTerm = MarketAPI.getDealTerm(dealId);
 //       return CommonTypes.ChainEpoch.unwrap(dealTerm.end);
    }
}