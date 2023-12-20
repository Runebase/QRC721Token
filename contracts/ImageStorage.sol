pragma solidity ^0.5.0;

contract ImageStorage {
    mapping(uint256 => string) public images;
    uint256[] public imageIds;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function storeImage(string memory _base64Image) public onlyOwner returns (uint256) {
        uint256 imageId = imageIds.length + 1;
        images[imageId] = _base64Image;
        imageIds.push(imageId);
        return imageId;
    }

    function getImage(uint256 _imageId) public view returns (string memory) {
        return images[_imageId];
    }

    function getAllImageIds() public view returns (uint256[] memory) {
        return imageIds;
    }

    function getImageIdsLength() public view returns (uint256) {
        return imageIds.length;
    }
}
