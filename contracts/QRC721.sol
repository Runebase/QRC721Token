pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.1.3/contracts/token/ERC721/ERC721Enumerable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.1.3/contracts/token/ERC721/ERC721Metadata.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.1.3/contracts/token/ERC721/ERC721MetadataMintable.sol";
import "./IQRC721.sol";
import "./ImageStorage.sol";

contract QRC721 is IQRC721, ERC721Enumerable, ERC721Metadata, ERC721MetadataMintable {
    address public imageStorageAddress;

    // Struct to represent an attribute
    struct Attribute {
        string name;
        string value;
    }

    // Mapping from token ID to an array of attributes
    mapping(uint256 => Attribute[]) public tokenAttributes;

    constructor(string memory name, string memory symbol, address _imageStorageAddress) ERC721Metadata(name, symbol) public {
        imageStorageAddress = _imageStorageAddress;
    }

    event TokenMinted(uint256 indexed tokenId, string base64Image, string attributeData);

    function mintWithAttributes(
        uint256 tokenId,
        uint256 imageId,
        string memory attributeNames,
        string memory attributeValues
    ) public onlyMinter {
        require(imageId > 0, "Image ID must be greater than 0");

        // Ensure that the token with the specified tokenId does not already exist
        require(!_exists(tokenId), "Token with this ID already exists");

        // Mint the token
        _mint(msg.sender, tokenId);

        // Get the image from the storage contract
        string memory base64Image = ImageStorage(imageStorageAddress).getImage(imageId);

        // Split attributeNames and attributeValues into arrays
        string[] memory names = split(attributeNames, ',');
        string[] memory values = split(attributeValues, ',');

        // Store attributes in the mapping
        storeAttributes(tokenId, names, values);

        // Construct the full token URI using the retrieved image data and dynamic attributes
        string memory fullURI = generateTokenURI(tokenId, base64Image, names, values);

        // Set the token URI
        _setTokenURI(tokenId, fullURI);

        // Log the minting event
        emit TokenMinted(tokenId, base64Image, generateTokenURI(tokenId, base64Image, names, values));
    }

    function setImageStorageAddress(address _imageStorageAddress) external onlyMinter {
        imageStorageAddress = _imageStorageAddress;
    }

    // Helper function to split a string into an array based on a delimiter
    function split(string memory str, bytes1 delimiter) internal pure returns (string[] memory) {
        bytes memory strBytes = bytes(str);
        uint256 length = strBytes.length;
        uint256 count = 1;

        // Count the number of delimiters to determine the array length
        for (uint256 i = 0; i < length; i++) {
            if (strBytes[i] == delimiter) {
                count++;
            }
        }

        string[] memory parts = new string[](count);

        uint256 j = 0;
        uint256 start = 0;

        // Split the string into parts
        for (uint256 i = 0; i < length; i++) {
            if (strBytes[i] == delimiter) {
                parts[j] = substring(str, start, i);
                start = i + 1;
                j++;
            }
        }

        // Last part
        parts[j] = substring(str, start, length);

        return parts;
    }

    // Helper function to extract a substring from a string
    function substring(string memory str, uint256 startIndex, uint256 endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(startIndex < endIndex && endIndex <= strBytes.length, "Invalid indices");
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    // Helper function to store attributes in the mapping
    function storeAttributes(uint256 tokenId, string[] memory attributeNames, string[] memory attributeValues) internal {
        require(attributeNames.length == attributeValues.length, "Mismatched attribute names and values");

        uint256 numAttributes = attributeNames.length;

        // Store attributes in the mapping
        for (uint256 i = 0; i < numAttributes; i++) {
            tokenAttributes[tokenId].push(Attribute(attributeNames[i], attributeValues[i]));
        }
    }

    // Helper function to generate token URI
    function generateTokenURI(uint256 tokenId, string memory base64Image, string[] memory attributeNames, string[] memory attributeValues) internal pure returns (string memory) {
        // Retrieve the dynamic attributes for the token
        string memory uriAttributes = getAttributesString(attributeNames, attributeValues);

        // Construct the full token URI using the retrieved image data and dynamic attributes
        return string(abi.encodePacked("data:image;base64,", base64Image, "&tokenId=", toString(tokenId), uriAttributes));
    }

    // Helper function to get dynamic attributes as a string
    function getAttributesString(string[] memory attributeNames, string[] memory attributeValues) internal pure returns (string memory) {
        string memory result;

        // Concatenate attribute name-value pairs
        for (uint256 i = 0; i < attributeNames.length; i++) {
            result = string(abi.encodePacked(result, "&", attributeNames[i], "=", attributeValues[i]));
        }

        return result;
    }

    // Helper function to convert uint to string
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
