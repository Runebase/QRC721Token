// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract ImageStorage {
    mapping(string => string) public images;
    string[] public itemNames;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function storeImage(string memory itemName, string memory base64Image) public onlyOwner {
        // Check if the item already exists
        require(bytes(images[itemName]).length == 0, "Item with this name already exists");

        images[itemName] = base64Image;
        itemNames.push(itemName);
    }

    function updateImage(string memory itemName, string memory base64Image) public onlyOwner {
        // Check if the item exists
        require(bytes(images[itemName]).length != 0, "Item with this name does not exist");

        images[itemName] = base64Image;
    }

    function getImage(string memory itemName) public view returns (string memory) {
        return images[itemName];
    }

    function getAllItemNamesCount() public view returns (uint256) {
        return itemNames.length;
    }

    function getItemNameAtIndex(uint256 index) public view returns (string memory) {
        require(index < itemNames.length, "Index out of bounds");
        return itemNames[index];
    }
}
