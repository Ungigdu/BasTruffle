pragma solidity >=0.5.0;
import "./safemath.sol";
import "./owned.sol";

contract BasOwnership is owned{
    using SafeMath for uint256;

    event Add(bytes32 nameHash, address owner);
    event Update(bytes32 nameHash, address owner);
    event Extend(bytes32 nameHash, uint256 time);
    event Takeover(bytes32 nameHash, address from, address to);
    event Transfer(bytes32 nameHash, address from, address to);
    event TransferFrom(bytes32 nameHash, address from, address to, address by);
    event Remove(bytes32 nameHash);

    mapping(bytes32 => address) public ownerOf;
    mapping(bytes32 => uint256) public expirationOf;
    mapping(address => mapping(bytes32 => address)) private _allowed;
    
    function query(bytes32 nameHash) public view returns (address,uint256){
        return (ownerOf[nameHash],expirationOf[nameHash]);
    }

    function isWild(bytes32 nameHash) public view returns (bool) {
        return ownerOf[nameHash] == address(0) || expirationOf[nameHash] < now;
    }

    function exist(bytes32 nameHash) public view returns (bool) {
        return ownerOf[nameHash] != address(0);
    }

    function expired(bytes32 nameHash) public view returns (bool) {
        return exist(nameHash) && expirationOf[nameHash] < now;
    }

    function isValid(bytes32 nameHash, address check)
        public
        view
        returns (bool)
    {
        return ownerOf[nameHash] == check && expirationOf[nameHash] > now;
    }

    modifier Owner(bytes32 nameHash) {
        require(isValid(nameHash, msg.sender), "owner only");
        _;
    }

    modifier Wild(bytes32 nameHash) {
        require(isWild(nameHash), "not Wild");
        _;
    }

    modifier Exist(bytes32 nameHash) {
        require(exist(nameHash), "not exist");
        _;
    }

    modifier NotExist(bytes32 nameHash) {
        require(!exist(nameHash), "exist");
        _;
    }

    modifier Expired(bytes32 nameHash) {
        require(expired(nameHash), "not expired");
        _;
    }

    modifier NotExpired(bytes32 nameHash) {
        require(!expired(nameHash), "expired");
        _;
    }

    modifier Valid(bytes32 nameHash, address check) {
        require(isValid(nameHash, check), "not valid");
        _;
    }

    function _a_update(bytes32 nameHash, address owner, uint256 expire)
        external
        Admin
    {
        ownerOf[nameHash] = owner;
        expirationOf[nameHash] = expire;
        emit Update(nameHash, owner);
    }

    function _c_add(bytes32 nameHash, address owner, uint256 expire)
        external
        ContractCaller
        NotExist(nameHash)
    {
        ownerOf[nameHash] = owner;
        expirationOf[nameHash] = expire;
        emit Add(nameHash, owner);
    }

    function _c_takeover(bytes32 nameHash, address owner, uint256 expire)
        external
        ContractCaller
        Expired(nameHash)
    {
        emit Takeover(nameHash, ownerOf[nameHash], owner);
        ownerOf[nameHash] = owner;
        expirationOf[nameHash] = expire;
    }

    function _c_extend(bytes32 nameHash, uint256 extend)
        external
        ContractCaller
        Exist(nameHash)
    {
        if (expired(nameHash)) {
            expirationOf[nameHash] = extend.add(now);
        } else {
            expirationOf[nameHash] = extend.add(expirationOf[nameHash]);
        }
        emit Extend(nameHash,extend);
    }

    function remove(bytes32 nameHash) external Owner(nameHash) {
        delete ownerOf[nameHash];
        delete expirationOf[nameHash];
        emit Remove(nameHash);
    }

    function removeExpired(bytes32 nameHash) external Expired(nameHash) {
        delete ownerOf[nameHash];
        delete expirationOf[nameHash];
        emit Remove(nameHash);
    }

    function transfer(bytes32 nameHash, address to) external Owner(nameHash) {
        require(msg.sender != to, "transfer to self");
        ownerOf[nameHash] = to;
        emit Transfer(nameHash, msg.sender, to);
    }

    function approve(bytes32 nameHash, address spender)
        external
        Owner(nameHash)
    {
        _allowed[msg.sender][nameHash] = spender;
    }

    function allowance(address owner, bytes32 nameHash)
        external
        view
        returns (address)
    {
        return _allowed[owner][nameHash];
    }

    function revoke(bytes32 nameHash) external Owner(nameHash) {
        delete _allowed[msg.sender][nameHash];
    }

    function transferFrom(bytes32 nameHash, address from, address to)
        external
        Valid(nameHash, from)
    {
        require(_allowed[from][nameHash] == msg.sender, "not allowed");
        require(from != to, "transfer to self");
        ownerOf[nameHash] = to;
        emit TransferFrom(nameHash, from, to, msg.sender);
    }

}
