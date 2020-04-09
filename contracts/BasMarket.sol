pragma solidity >=0.5.0;

import "./ERC20.sol";
import "./BasOwned.sol";

contract BasMarket is BasOwned {
    ERC20 public t;
    uint256 public constant AT_LEAST_REMAIN_TIME = 7 days;

    constructor(address _t, address _o) public BasOwned(_o){
        t = ERC20(_t);
    }

    struct AskOrder {
        uint256 price;
        uint256 protectiveRemainTime;
    }
    
    event SoldBySell(bytes32 nameHash,address from,address to,uint256 price);
    event SoldByAsk(bytes32 nameHash,address from,address to,uint256 price);
    event SellAdded(bytes32 nameHash,address operator,uint256 price);
    event SellChanged(bytes32 nameHash, address operator, uint256 price);
    event SellRemoved(bytes32 nameHash, address operator);
    event AskAdded(bytes32 nameHash,address operator,uint256 price, uint256 time);
    event AskChanged(bytes32 nameHash, address operator, uint256 price, uint256 time);
    event AskRemoved(bytes32 nameHash, address operator);
    
    mapping(address => mapping(bytes32 => uint256)) public  SellOrders;
    mapping(address => mapping(bytes32 => AskOrder)) public AskOrders;
    
    function _sellOrderExist(address addr, bytes32 nameHash) internal view returns (bool){
        return SellOrders[addr][nameHash] > 0;
    }

    function _askOrderExist(address addr, bytes32 nameHash) internal view returns (bool){
        return AskOrders[addr][nameHash].price > 0;
    }
    
    modifier SellOrderOwner(bytes32 nameHash){
        require(_sellOrderExist(msg.sender,nameHash),"sell order not owned");
        _;
    }
    
    modifier AskOrderOwner(bytes32 nameHash){
        require(_askOrderExist(msg.sender,nameHash),"ask order not owned");
        _;
    }
    
    function AddToSells(bytes32 nameHash, uint256 price) external Allowed(nameHash){
        require(!_sellOrderExist(msg.sender,nameHash), "record exists");
        require(price > 0, "price can't be zero");
        require(o.expirationOf(nameHash) > now + AT_LEAST_REMAIN_TIME,"expiration less than 7 days");
        SellOrders[msg.sender][nameHash] = price;
        emit SellAdded(nameHash, msg.sender, price);
    }

    function ChangeSellPrice(bytes32 nameHash, uint256 price) external Allowed(nameHash) SellOrderOwner(nameHash){
        require(price > 0, "price can't be zero");
        SellOrders[msg.sender][nameHash] = price;
        emit SellChanged(nameHash, msg.sender,price);
    }
    
    function RemoveSellOrder(bytes32 nameHash) SellOrderOwner(nameHash) public {
        delete SellOrders[msg.sender][nameHash];
        emit SellRemoved(nameHash, msg.sender);
    }

    function AddToAsks(bytes32 nameHash,uint256 price,uint256 protectiveRemainTime) external {
        address owner = o.ownerOf(nameHash);
        require(owner != address(0), "should just register or takeover");
        require(!_askOrderExist(msg.sender,nameHash), "already added");
        require(!_sellOrderExist(owner,nameHash), "domain on sell");
        require(price > 0, "price can't be zero");
        uint256 time = protectiveRemainTime;
        if (protectiveRemainTime == 0) {
            time = AT_LEAST_REMAIN_TIME;
        }
        AskOrders[msg.sender][nameHash] = AskOrder(price, time);
        emit AskAdded(nameHash, msg.sender, price, protectiveRemainTime);
    }

    function ChangeAsksData(bytes32 nameHash,uint256 price,uint256 protectiveRemainTime) external {
        require(_askOrderExist(msg.sender,nameHash), "not exist");
        require(price > 0, "price can't be zero");
        uint256 time = protectiveRemainTime;
        if (protectiveRemainTime == 0) {
            time = AskOrders[msg.sender][nameHash].protectiveRemainTime;
        }
        AskOrders[msg.sender][nameHash] = AskOrder(price, time);
        emit AskChanged(nameHash, msg.sender,price, protectiveRemainTime);
    }
    
    function RemoveAskOrder(bytes32 nameHash) AskOrderOwner(nameHash) external {
        delete AskOrders[msg.sender][nameHash];
        emit AskRemoved(nameHash, msg.sender);
    }

    function _exchangeDomainAndToken(address domainHolder, address tokenHolder, bytes32 nameHash,uint256 aggreedPirce) internal {
        t.transferFrom(tokenHolder, domainHolder, aggreedPirce);
        o.transferFrom(nameHash, domainHolder, tokenHolder);
    }
    
    function BuyFromSells(bytes32 nameHash, address owner) Valid(nameHash,owner) external {
        require(msg.sender != owner, "can't buy from self");
        uint256 price = SellOrders[owner][nameHash];
        require(price > 0, "not exist");
        _exchangeDomainAndToken(owner,msg.sender,nameHash,price);
        delete SellOrders[owner][nameHash];
        delete AskOrders[msg.sender][nameHash];
        emit SoldBySell(nameHash, owner, msg.sender, price);
    }
    
    function SellToAsks(bytes32 nameHash, address to) Allowed(nameHash) external {
        AskOrder memory item = AskOrders[to][nameHash];
        require(item.price > 0, "ask not exist");
        require(o.expirationOf(nameHash) > now + item.protectiveRemainTime,"not enough time left");
        _exchangeDomainAndToken(msg.sender,to,nameHash,item.price);
        delete AskOrders[to][nameHash];
        delete SellOrders[msg.sender][nameHash];
        emit SoldByAsk(nameHash, msg.sender, to, item.price);
    }
}