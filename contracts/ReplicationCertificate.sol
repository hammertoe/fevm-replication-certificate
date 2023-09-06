// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import { MarketAPI } from "@zondax/filecoin-solidity/contracts/v0.8/MarketAPI.sol";
import { CommonTypes } from "@zondax/filecoin-solidity/contracts/v0.8/types/CommonTypes.sol";
import { MarketTypes } from "@zondax/filecoin-solidity/contracts/v0.8/types/MarketTypes.sol";
import "base64-sol/base64.sol";

contract ReplicationCertificate is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    mapping (uint256 => string) public tokenIdToPieceCid;
    mapping (string => uint64[]) public pieceCidToDealIds;

    constructor() ERC721("ReplicationCertificate", "REP") {}

    function safeMint(address to, string memory pieceCid, uint64[] memory dealIds) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        tokenIdToPieceCid[tokenId] = pieceCid;
        pieceCidToDealIds[pieceCid] = dealIds;
    }

    function addDealId(string memory pieceCid, uint64 dealId) public {
        uint64[] storage dealIds = pieceCidToDealIds[pieceCid];
        
        // Check if the array is empty
        if (dealIds.length == 0) {
            // Initialize the array if it's empty
            pieceCidToDealIds[pieceCid] = [dealId];
        } else {
            // Append the dealId to the existing array
            dealIds.push(dealId);
        }
    }

    function getDealIds(uint256 tokenId) public view returns (uint64[] memory) {
        return pieceCidToDealIds[tokenIdToPieceCid[tokenId]];
    }

    function getProviders(uint256 tokenId) public view returns (uint64[] memory) {
        uint64[] memory dealIds = getDealIds(tokenId);
        uint64[] memory providers = new uint64[](dealIds.length);

        for (uint256 i = 0; i < dealIds.length; i++) {     
            providers[i]= MarketAPI.getDealProvider(dealIds[i]);
        }

        return providers;
    }

    function getActiveProviders(uint256 tokenId) public view returns (uint64[] memory) {
        uint256 j = 0;
        uint256 grace = 100;

        uint64[] memory dealIds = getDealIds(tokenId);
        uint64[] memory providers = new uint64[](dealIds.length);

        for (uint256 i = 0; i < dealIds.length; i++) {     
            MarketTypes.GetDealTermReturn memory dealTerm = MarketAPI.getDealTerm(dealIds[i]);
            int64 end = CommonTypes.ChainEpoch.unwrap(dealTerm.end);

            if (true || block.timestamp < uint64(end) + grace) {
                providers[j] = MarketAPI.getDealProvider(dealIds[i]);
                j++;
            }
        }

        // Resize the array to the actual number of providers found
        uint64[] memory result = new uint64[](j);
        for (uint256 k = 0; k < j; k++) {
            result[k] = providers[k];
        }

        return result;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint64[] memory providers = getActiveProviders(tokenId);
        uint256 copies = providers.length;
        string memory pieceCid = tokenIdToPieceCid[tokenId];      
        string memory copiesStr = Strings.toString(copies);

        string memory providersStr = "";
        for (uint256 i = 0; i < copies; i++) {
            if (i > 0) {
                providersStr = string(abi.encodePacked(providersStr, ",")); // Add comma separator
            }
            providersStr = string(abi.encodePacked(providersStr, Strings.toString(providers[i])));
        }
        providersStr = string(abi.encodePacked('[', providersStr, ']'));

        string memory svgImage = generateSVGImage(pieceCid, copies, copiesStr, providersStr);


        string memory json = string(
            abi.encodePacked(
                '{"name": "', name(), '", ',
                '"description": "Certificate of Replication", ',
                '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svgImage)), '",',
                '"attributes": [',
                '{"trait_type": "Copies", "value":', copiesStr, '},',
                '{"trait_type": "Providers", "value":', providersStr, '}',
                ']}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function generateSVGImage(string memory pieceCid, uint256 copies, string memory copiesStr, string memory providersStr) internal pure returns (string memory) {
        // Generate your SVG here using the tokenId or any other dynamic data
        string memory svg1 = string(
            abi.encodePacked(
                '<?xml version="1.0"?>'
                '<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" width="800" height="800" viewBox="0 0 512 335">'
                '<path d="M395 264.707c-26.4 0-48-21.6-48-48.24.24-26.4 21.6-48 48.24-47.76 26.4.24 47.76 21.6 47.76 48.48-.24 26.16-21.6 47.52-48 47.52" style="clip-rule:evenodd;fill:#0090ff;fill-rule:evenodd;stroke-width:2.4" mask="url(#b-logo_1_1_)"/>'
                '<path d="m398.648 212.099-1.152 6.144 10.944 1.536-.768 2.88-10.752-1.536c-.768 2.496-1.152 5.184-2.112 7.488-.96 2.688-1.92 5.376-3.072 7.872-1.536 3.264-4.224 5.568-7.872 6.144-2.112.384-4.416.192-6.144-1.152-.576-.384-1.152-1.152-1.152-1.728 0-.768.384-1.728.96-2.112.384-.192 1.344 0 1.92.192a8.525 8.525 0 0 1 1.536 2.112c1.152 1.536 2.688 1.728 4.224.576 1.728-1.536 2.688-3.648 3.264-5.76 1.152-4.608 2.304-9.024 3.264-13.632v-.768l-10.176-1.536.384-2.88 10.56 1.536 1.344-5.952-10.944-1.728.384-3.072 11.328 1.536c.384-1.152.576-2.112.96-3.072.96-3.456 1.92-6.912 4.224-9.984 2.304-3.072 4.992-4.992 9.024-4.8 1.728 0 3.456.576 4.608 1.92.192.192.576.576.576.96 0 .768 0 1.728-.576 2.304-.768.576-1.728.384-2.496-.384-.576-.576-.96-1.152-1.536-1.728-1.152-1.536-2.88-1.728-4.224-.384-.96.96-1.92 2.304-2.496 3.648-1.344 4.032-2.304 8.256-3.648 12.48l10.56 1.536-.768 2.88-10.176-1.536" style="stroke-width:1.92;fill-rule:evenodd;clip-rule:evenodd;fill:#fff"/>'
                '<path fill="#0090ff" d="M370 261.707h50v50h-50z"/>'
                '<path d="M503.332 0H8.668A8.668 8.668 0 0 0 0 8.668v302.808a8.668 8.668 0 0 0 8.668 8.668h352.294v6.602a8.671 8.671 0 0 0 8.667 8.668c1.801 0 3.59-.559 5.1-1.659l20.327-14.787 20.333 14.781a8.671 8.671 0 0 0 9.031.712 8.666 8.666 0 0 0 4.734-7.724v-6.594h74.176a8.668 8.668 0 0 0 8.668-8.668V8.668A8.665 8.665 0 0 0 503.332 0Zm-20.927 17.336-11.558 11.558H41.152L29.594 17.336Zm-28.987 185.501c-.962-1.425-2.05-3.04-2.351-3.964-.346-1.061-.422-3.013-.496-4.902-.17-4.341-.383-9.743-3.821-14.468-3.463-4.758-8.556-6.626-12.65-8.128-1.753-.644-3.567-1.308-4.431-1.938-.832-.604-2.056-2.172-3.137-3.554-2.702-3.457-6.065-7.759-11.726-9.596-5.493-1.782-10.653-.326-14.799.844-1.854.524-3.772 1.063-4.949 1.063s-3.095-.541-4.949-1.063c-4.15-1.171-9.313-2.625-14.799-.844-5.66 1.838-9.024 6.141-11.726 9.597-1.082 1.382-2.307 2.949-3.138 3.554-.864.63-2.678 1.296-4.431 1.938-4.094 1.501-9.187 3.371-12.65 8.128-3.438 4.724-3.65 10.127-3.821 14.468-.073 1.887-.15 3.841-.496 4.902-.301.925-1.389 2.539-2.351 3.964-2.468 3.656-5.537 8.205-5.537 14.232 0 6.028 3.07 10.578 5.537 14.233.962 1.425 2.051 3.04 2.351 3.964.346 1.061.422 3.014.496 4.903.17 4.341.383 9.743 3.821 14.468 3.463 4.757 8.556 6.626 12.65 8.128 1.753.644 3.565 1.308 4.431 1.938.157.114.333.273.514.448v8.762H46.23V46.231h419.54v227.684h-36.614v-8.762c.183-.177.358-.335.516-.45.866-.629 2.678-1.294 4.431-1.938 4.092-1.501 9.186-3.371 12.647-8.127 3.44-4.725 3.651-10.128 3.822-14.47.074-1.887.15-3.839.495-4.899.301-.925 1.39-2.54 2.352-3.965 2.468-3.656 5.537-8.206 5.537-14.233 0-6.027-3.07-10.578-5.538-14.234zM28.894 278.991l-11.558 11.558V29.594l11.558 11.558zm332.067 23.817H29.594l11.558-11.558h319.809zm50.858 6.915-11.668-8.482a8.667 8.667 0 0 0-10.195.002l-11.657 8.48v-31.198c.818.109 1.627.165 2.422.165 3.442 0 6.638-.901 9.388-1.677 1.854-.524 3.774-1.063 4.95-1.063 1.177 0 3.095.541 4.949 1.063 3.385.955 7.448 2.1 11.811 1.52zm16.31-63.233c-2.737 1.004-5.839 2.143-8.66 4.197-2.793 2.033-4.813 4.616-6.595 6.894-.985 1.26-2.615 3.346-3.397 3.769-.87.075-3.203-.584-4.764-1.024-2.85-.803-6.079-1.714-9.655-1.714-3.576 0-6.806.911-9.655 1.714-1.563.44-3.9 1.093-4.763 1.024-.781-.423-2.413-2.509-3.397-3.768-1.782-2.279-3.801-4.862-6.594-6.894-2.822-2.054-5.926-3.192-8.662-4.197-1.486-.545-3.949-1.449-4.593-2.051-.362-.799-.464-3.388-.526-4.949-.114-2.923-.245-6.235-1.328-9.575-1.054-3.245-2.869-5.935-4.47-8.309-.94-1.392-2.511-3.72-2.572-4.522.061-.828 1.632-3.155 2.572-4.547 1.602-2.374 3.416-5.063 4.469-8.309 1.084-3.34 1.216-6.653 1.329-9.575.062-1.561.164-4.15.526-4.949.643-.602 3.107-1.506 4.593-2.051 2.737-1.004 5.839-2.143 8.661-4.197 2.793-2.033 4.813-4.616 6.595-6.894.985-1.26 2.617-3.347 3.397-3.769.865-.074 3.201.584 4.763 1.024 2.85.804 6.08 1.715 9.655 1.715 3.575 0 6.805-.911 9.655-1.715 1.563-.44 3.89-1.098 4.764-1.024.781.422 2.412 2.508 3.396 3.768 1.782 2.279 3.8 4.862 6.595 6.895 2.822 2.054 5.924 3.192 8.661 4.195 1.485.546 3.949 1.449 4.593 2.052.362.797.463 3.388.526 4.949.114 2.922.245 6.235 1.329 9.575 1.053 3.245 2.867 5.934 4.469 8.308.94 1.392 2.511 3.72 2.572 4.524-.06.828-1.632 3.156-2.572 4.549-1.602 2.373-3.416 5.061-4.47 8.308-1.084 3.34-1.215 6.653-1.328 9.575-.061 1.563-.163 4.151-.526 4.948-.641.601-3.107 1.506-4.593 2.05zm1.026 56.318V291.25h41.693l11.558 11.558zm65.509-12.259-11.558-11.558V41.153l11.558-11.558z"/>'
                '<text x="256" y="72" dominant-baseline="middle" text-anchor="middle" font-family="Brush Script MT" font-size="36">Certificate of Replication</text>'
                '<text x="60" y="111" dominant-baseline="middle" text-anchor="left" font-family="Courier" font-size="10">'
                '<tspan x="60" dy="0">Piece CID:</tspan>'
                '<tspan x="60" dy="10">',
                pieceCid,
                '</tspan>'
                '<tspan x="60" dy="20">Copies:</tspan>'
                '<tspan x="60" dy="10">',
                copiesStr,
                '</tspan>'
                '<tspan x="60" dy="20">Providers:</tspan>'
                '<tspan x="60" dy="10">',
                providersStr,
                '</tspan>'
                '</text>'
            )
        );

        string memory svg2 = "";
        if (copies < 2) {
            svg2 = string(
                abi.encodePacked(
                    '<text xml:space="preserve" style="font-weight:700;font-size:40px;font-family:Courier;fill:red;stroke-width:.64" x="78" y="241">'
                    '<tspan>DANGER</tspan>'
                    '</text>'
                )
            );
        }

        string memory svg = string(
            abi.encodePacked(
                svg1,
                svg2,
                '</svg>'
            )
        );

        return svg;
    }

}