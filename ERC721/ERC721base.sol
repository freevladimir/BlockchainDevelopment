pragma solidity ^0.4.18;

library SafeMath {

    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

contract Ownable {

    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}

contract AssetRegistryStorage {

    string public constant _name;
    string public constant _symbol;
    string public constant _description;


    uint256 internal _count;

    uint256 commonId = 100000;

    mapping(address => uint256[]) internal _assetsOf;


    mapping(uint256 => address) internal _holderOf;


    mapping(uint256 => uint256) internal _indexOfAsset;


    mapping(uint256 => string) internal _assetData;


    mapping(address => mapping(address => bool)) internal _operators;


    mapping(uint256 => address) internal _approval;

    mapping(uint256 => uint256) internal _priseOfAsset;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed assetId,
        address operator
    );
    event ApprovalForAll(
        address indexed operator,
        address indexed holder,
        bool authorized
    );
    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed assetId
    );
    event setPrise(
        uint256 indexed assetId,
        uint256 indexed prise
    );
}


contract ERC721Base is AssetRegistryStorage, Ownable {
    using SafeMath for uint256;


    function name() external view returns (string) {
        return _name;
    }
    function symbol() external view returns (string) {
        return _symbol;
    }
    function description() external view returns (string) {
        return _description;
    }
    function tokenMetadata(uint256 assetId) external view returns (string) {
        return _assetData[assetId];
    }
    function _update(uint256 assetId, string data) onlyHolder(assetId) internal {
        _assetData[assetId] = data;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply();
    }
    function _totalSupply() internal view returns (uint256) {
        return _count;
    }




    function ownerOf(uint256 assetId) external view returns (address) {
        return _ownerOf(assetId);
    }
    function _ownerOf(uint256 assetId) internal view returns (address) {
        return _holderOf[assetId];
    }



    function balanceOf(address owner) external view returns (uint256) {
        return _balanceOf(owner);
    }
    function balanceOfIndex(address owner, uint256 _index) external view returns (uint256) {
        return _assetsOf[owner][_index];
    }
    function _balanceOf(address owner) internal view returns (uint256) {
        return _assetsOf[owner].length;
    }


    function isApprovedForAll(address operator, address assetHolder) external view returns (bool)
    {
        return _isApprovedForAll(operator, assetHolder);
    }
    function _isApprovedForAll(address operator, address assetHolder) internal view returns (bool)
    {
        return _operators[assetHolder][operator];
    }

    function getApprovedAddress(uint256 assetId) external view returns (address) {
        return _getApprovedAddress(assetId);
    }
    function _getApprovedAddress(uint256 assetId) internal view returns (address) {
        return _approval[assetId];
    }

    function isAuthorized(address operator, uint256 assetId) external view returns (bool) {
        return _isAuthorized(operator, assetId);
    }
    function _isAuthorized(address operator, uint256 assetId) internal view returns (bool)
    {
        require(operator != 0);
        address owner = _ownerOf(assetId);
        if (operator == owner) {
            return true;
        }
        return _isApprovedForAll(operator, owner) || _getApprovedAddress(assetId) == operator;
    }

    function setApprovalForAll(address operator, bool authorized) external {
        return _setApprovalForAll(operator, authorized);
    }
    function _setApprovalForAll(address operator, bool authorized) internal {
        if (authorized) {
            require(!_isApprovedForAll(operator, msg.sender));
            _addAuthorization(operator, msg.sender);
        } else {
            require(_isApprovedForAll(operator, msg.sender));
            _clearAuthorization(operator, msg.sender);
        }
        emit ApprovalForAll(operator, msg.sender, authorized);
    }


    function approve(address operator, uint256 assetId) onlyHolder(assetId) external {
        address holder = _ownerOf(assetId);
        require(operator != holder);
        if (_getApprovedAddress(assetId) != operator) {
            _approval[assetId] = operator;
            emit Approval(holder, operator, assetId);
        }
    }

    function _addAuthorization(address operator, address holder) private {
        _operators[holder][operator] = true;
    }

    function _clearAuthorization(address operator, address holder) private {
        _operators[holder][operator] = false;
    }

    function getPriseOfAsset(uint256 _assetId) public view returns(uint256){
        return _priseOfAsset[_assetId];
    }

    function setPriseOfAsset(uint256 _assetId, uint256 _prise) onlyHolder(_assetId) public returns(bool){
        _priseOfAsset[_assetId] = _prise;
        emit setPrise(_assetId, _prise);
    }

    function _addAssetTo(address to, uint256 assetId) internal {
        _holderOf[assetId] = to;

        uint256 length = _balanceOf(to);

        _assetsOf[to].push(assetId);

        _indexOfAsset[assetId] = length;

        _count = _count.add(1);
    }

    function mint(address beneficiary, uint256 _prise, string data) onlyOwner public{
        commonId += 1;
        _addAssetTo(beneficiary, commonId);
        _priseOfAsset[commonId] = _prise;
        _assetData[assetId] = data;
        emit Transfer(0, beneficiary, commonId, msg.sender);
        emit setPrise(commonId, _prise);
    }

    function _removeAssetFrom(address from, uint256 assetId) internal {
        uint256 assetIndex = _indexOfAsset[assetId];
        uint256 lastAssetIndex = _balanceOf(from).sub(1);
        uint256 lastAssetId = _assetsOf[from][lastAssetIndex];

        _holderOf[assetId] = 0;

        _assetsOf[from][assetIndex] = lastAssetId;

        // Resize the array
        _assetsOf[from][lastAssetIndex] = 0;
        _assetsOf[from].length--;

        if (_assetsOf[from].length == 0) {
            delete _assetsOf[from];
        }

        _indexOfAsset[assetId] = 0;
        _indexOfAsset[lastAssetId] = assetIndex;

        _count = _count.sub(1);
    }

    function _clearApproval(address holder, uint256 assetId) internal {
        if (_ownerOf(assetId) == holder && _approval[assetId] != 0) {
            _approval[assetId] = 0;
            emit Approval(holder, 0, assetId);
        }
    }


    modifier onlyHolder(uint256 assetId) {
        require(_ownerOf(assetId) == msg.sender);
        _;
    }

    modifier onlyAuthorized(uint256 assetId) {
        require(_isAuthorized(msg.sender, assetId));
        _;
    }

    modifier isCurrentOwner(address from, uint256 assetId) {
        require(_ownerOf(assetId) == from);
        _;
    }

    modifier isDestinataryDefined(address destinatary) {
        require(destinatary != 0);
        _;
    }

    modifier destinataryIsNotHolder(uint256 assetId, address to) {
        require(_ownerOf(assetId) != to);
        _;
    }

    function transfer(address _to, uint256 _assetId) external {
        _moveToken(msg.sender, _to, _assetId, 0);
    }

    function transferFrom(address from, address to, uint256 assetId) external {
        return _moveToken(from, to, assetId, msg.sender);
    }

    function _moveToken(
        address from,
        address to,
        uint256 assetId,
        address operator
    )
    onlyAuthorized(assetId)
    isDestinataryDefined(to)
    destinataryIsNotHolder(assetId, to)
    isCurrentOwner(from, assetId)
    internal
    {
        address holder = _holderOf[assetId];
        _clearApproval(holder, assetId);
        _removeAssetFrom(holder, assetId);
        _addAssetTo(to, assetId);


        emit Transfer(holder, to, assetId, operator);
    }


}
