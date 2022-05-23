// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//Simple and gas efficient implementation of the ERC721 standard and ownable contract.
contract ERC721O {

    //Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    //Global Variables
    string public name;
    string public symbol;
    string public baseURI;
    address public owner;
    uint256 public maxSupply;
    uint256 public totalSupply;

    //Mappings
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    //Constructor
    constructor(string memory _name, string memory _symbol, uint256 _maxSupply) {
        name = _name;
        symbol = _symbol;
        maxSupply = _maxSupply;
        owner = msg.sender;
    }   

    //OpenZepplin "toString" Function
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    //Internal Functions
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(ownerOf[_tokenId] == _from);

        balanceOf[_from]--; 
        balanceOf[_to]++;
        ownerOf[_tokenId] = _to;

        emit Transfer(msg.sender, _to, _tokenId); 
        delete getApproved[_tokenId];
    }

    function _mint(address _to, uint256 _tokenId) internal {
        require(ownerOf[_tokenId] == address(0), "Token already minted!");
        require(totalSupply < maxSupply, "Max supply exceeded!");

        balanceOf[_to]++;
        ownerOf[_tokenId] = _to;
        totalSupply++;

        emit Transfer(address(0), _to, _tokenId); 
    }

    function _burn(uint256 _tokenId) internal {
        require(ownerOf[_tokenId] != address(0), "Must be minted to burn!");
        balanceOf[ownerOf[_tokenId]]--;
        totalSupply--;

        emit Transfer(ownerOf[_tokenId], address(0), _tokenId);
        delete ownerOf[_tokenId];
    }

    //ERC721 Implementation
    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function approve(address _to, uint256 _tokenId) external {
        require(msg.sender == ownerOf[_tokenId] || isApprovedForAll[(ownerOf[_tokenId])][msg.sender], "Not owner!");
        getApproved[_tokenId] = _to;

        emit Approval(ownerOf[_tokenId], _to, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender, "Cant approve to self!");
        isApprovedForAll[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(ownerOf[_tokenId] == msg.sender || getApproved[_tokenId] == msg.sender
                || isApprovedForAll[ownerOf[_tokenId]][msg.sender], "Not approved!");

        _transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(address, address to, uint256 tokenId) external {
        safeTransferFrom(address(0), to, tokenId, "");
    }
    
    function safeTransferFrom(address, address _to, uint256 _tokenId, bytes memory _data) public {
         transferFrom(address(0), _to, _tokenId);

         if (_to.code.length != 0) {
            // selector = `onERC721Received(address,address,uint,bytes)`
            (, bytes memory returned) = _to.staticcall(abi.encodeWithSelector(0x150b7a02,
                msg.sender, address(0), _tokenId, _data));
                
            bytes4 selector = abi.decode(returned, (bytes4));
            
            require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
        }
    }

    function tokenURI(uint256 _tokenId) external view virtual returns (string memory) {
        require(ownerOf[_tokenId] != address(0), "Token is not minted!");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, toString(_tokenId))) : "";
    }

    //Ownable Implementation
    modifier onlyOwner { 
        require(owner == msg.sender, "Owner only!"); 
        _; 
    }

    function transferOwnership(address _newOwner) external onlyOwner { 
        owner = _newOwner; 
    }
}
