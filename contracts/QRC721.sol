// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/access/Ownable.sol";

import "./IQRC721.sol";
import "./ImageStorage.sol";

contract QRC721 is ERC721, Ownable {
    address public imageStorageAddress;
    address[] public minters;

    // Struct to represent an attribute
    struct Attribute {
        string name;
        string value;
    }

    // Mapping from token ID to an array of attributes
    mapping(uint256 => Attribute[]) public tokenAttributes;

    // Mapping from token ID to item name
    mapping(uint256 => string) public tokenItemNames;

    constructor(string memory name, string memory symbol, address _imageStorageAddress) ERC721(name, symbol) public {
        imageStorageAddress = _imageStorageAddress;
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Sender is not a minter");
        _;
    }

    function isMinter(address _address) public view returns (bool) {
        for (uint256 i = 0; i < minters.length; i++) {
            if (minters[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function addMinter(address _minter) external onlyOwner {
        require(!isMinter(_minter), "Address is already a minter");
        minters.push(_minter);
    }

    function removeMinter(address _minter) external onlyOwner {
        require(isMinter(_minter), "Address is not a minter");

        for (uint256 i = 0; i < minters.length; i++) {
            if (minters[i] == _minter) {
                // Remove the minter from the array by swapping with the last element
                minters[i] = minters[minters.length - 1];
                minters.pop();
                break;
            }
        }
    }

    event TokenMinted(uint256 indexed tokenId, string base64Image, string itemName, string attributeData);

    function mintWithAttributes(
        uint256 tokenId,
        string memory itemImageName,
        string memory itemName,
        string memory attributeNames,
        string memory attributeValues
    ) public onlyMinter {
        // Ensure that the token with the specified tokenId does not already exist
        require(!_exists(tokenId), "Token with this ID already exists");

        // Mint the token
        _mint(msg.sender, tokenId);

        // Get the image from the storage contract using itemImageName
        string memory base64Image = ImageStorage(imageStorageAddress).getImage(itemImageName);

        // Split attributeNames into an array
        string[] memory names = split(attributeNames, '|');

        // Convert comma-separated attributeValues to an array of strings
        string[] memory values = split(attributeValues, '|');

        // Ensure that the number of attribute names matches the number of attribute values
        require(names.length == values.length, "Mismatched attribute names and values");

        // Store attributes in the mapping
        storeAttributes(tokenId, names, values);

        // Store the item name for the token
        tokenItemNames[tokenId] = itemName;

        // Construct the full token URI using the retrieved image data and dynamic attributes
        string memory fullURI = generateTokenURI(tokenId, base64Image, names, values, itemName);

        // Set the token URI
        _setTokenURI(tokenId, fullURI);

        // Log the minting event
        emit TokenMinted(tokenId, base64Image, itemName, generateTokenURI(tokenId, base64Image, names, values, itemName));
    }

    function setImageStorageAddress(address _imageStorageAddress) external onlyMinter {
        imageStorageAddress = _imageStorageAddress;
    }

    // Helper function to split a string into an array based on a delimiter
    function split(string memory str, bytes1 delimiter) internal pure returns (string[] memory) {
        uint256 length = bytes(str).length;
        uint256 count = 1;

        // Count the number of delimiters to determine the array length
        for (uint256 i = 0; i < length; i++) {
            if (bytes(str)[i] == delimiter) {
                count++;
            }
        }

        string[] memory parts = new string[](count);

        uint256 j = 0;
        uint256 start = 0;

        // Split the string into parts
        for (uint256 i = 0; i < length; i++) {
            if (bytes(str)[i] == delimiter) {
                // Avoid empty strings
                if (i > start) {
                    // Convert the part to a bytes memory and then to a string
                    bytes memory partBytes = new bytes(i - start);
                    for (uint256 k = start; k < i; k++) {
                        partBytes[k - start] = bytes(str)[k];
                    }
                    parts[j] = string(partBytes);
                    j++;
                }
                start = i + 1;
            }
        }

        // Last part
        if (start < length) {
            // Convert the last part to a bytes memory and then to a string
            bytes memory partBytes = new bytes(length - start);
            for (uint256 k = start; k < length; k++) {
                partBytes[k - start] = bytes(str)[k];
            }
            parts[j] = string(partBytes);
        }

        return parts;
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
    function generateTokenURI(uint256 tokenId, string memory base64Image, string[] memory attributeNames, string[] memory attributeValues, string memory itemName) internal pure returns (string memory) {
        // Retrieve the dynamic attributes for the token
        string memory uriAttributes = getAttributesString(attributeNames, attributeValues);

        // Include itemName in the URI
        return string(abi.encodePacked("data:image;base64,", base64Image, "&tokenId=", toString(tokenId), "&name=", itemName, uriAttributes));
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
