pragma solidity >=0.5.0;

import "./owned.sol";
import "./BasOwnership.sol";
import "./BasAsset.sol";
import "./BasDNS.sol";
import "./ERC20.sol";
import "./BasOwned.sol";
import "./BasOANN.sol";
import "./BasMarket.sol";

contract BasTransCheck {
    
    ERC20 private t;
    BasOwnership private o;
    BasAsset private a;
    BasDNS private d;
    BasOANN private oann;
    BasMarket private market;

    constructor(address _t, address _o, address _a, address _d, address _oann, address _market)
    public
    {
        t = ERC20(_t);
        a = BasAsset(_a);
        d = BasDNS(_d);
        o = BasOwnership(_o);
        oann = BasOANN(_oann);
        market = BasMarket(_market);
    }
    
    function checkUserState(address addr) public view returns (uint256 ethBalance,uint256 basBalance, uint256 allowanceOANN, uint256 allowanceMarket){
        ethBalance = addr.balance;
        basBalance = t.balanceOf(addr);
        allowanceOANN = t.allowance(msg.sender,address(oann));
        allowanceMarket = t.allowance(msg.sender,address(market));
    }
    
    function queryRootInfo(bytes32 nameHash) public view returns (
        address owner,
        uint256 expiration,
        bytes memory rootName,
        bool isOpen,
        bool isCustomed,
        uint256 isCustomedPrice,
        bytes4 ipv4,
        bytes16 ipv6,
        bytes memory bca,
        bytes memory opData,
        string memory aliasName
        ){
        owner = o.ownerOf(nameHash);
        expiration = o.expirationOf(nameHash);
        (rootName,isOpen,isCustomed,isCustomedPrice) = a.Root(nameHash);
        (ipv4,ipv6,bca,opData,aliasName) = d.DNS(nameHash);
    }
    
    function querySubInfo(bytes32 nameHash) external view returns (
        address owner,
        uint256 expiration,
        bytes memory totalName,
        bytes4 ipv4,
        bytes16 ipv6,
        bytes memory bca,
        bytes memory opData,
        string memory aliasName,
        bytes32 rootHash,
        address rootOwner
        ){
        owner = o.ownerOf(nameHash);
        expiration = o.expirationOf(nameHash);
        (ipv4,ipv6,bca,opData,aliasName) = d.DNS(nameHash);
        (totalName,rootHash) = a.Sub(nameHash);
        rootOwner = o.ownerOf(rootHash);
        }
        
    function checkBuyFromSell(bytes32 nameHash, address seller, address buyer) external view returns (
        bool sellerOwns,
        bool sellerAllows,
        bool sellOrderExist,
        uint256 buyerEth,
        uint256 buyerBalance,
        uint256 buyerAllowance
        ){
        sellerOwns = o.isValid(nameHash,seller);
        sellerAllows = o.allowance(seller,nameHash) == address(market);
        sellOrderExist = market.SellOrders(seller,nameHash) > 0;
        (buyerEth,buyerBalance,,buyerAllowance) = checkUserState(buyer);
        }
        
    function checkSellToAsk(bytes32 nameHash, address seller, address buyer) external view returns (
        bool sellerOwns,
        bool sellerAllows,
        bool askOrderExist,
        uint256 sellerEth,
        uint256 buyerBalance,
        uint256 buyerAllowance
        ){
        sellerOwns = o.isValid(nameHash,seller);
        sellerAllows = o.allowance(seller,nameHash) == address(market);
        (uint256 price,) = market.AskOrders(buyer,nameHash);
        askOrderExist = price > 0;
        sellerEth = seller.balance;
        (,buyerBalance,,buyerAllowance) = checkUserState(buyer);
        }
        
}
