pragma solidity >=0.5.0;

import "./owned.sol";
import "./BasOwnership.sol";
import "./BasAsset.sol";
import "./BasDNS.sol";
import "./BasMiner.sol";
import "./ERC20.sol";
import "./BasRule.sol";

contract BasOANN is owned {
    using SafeMath for uint256;

    uint256 public AROOT_GAS = 500 * (10**18);
    uint256 public BROOT_GAS = 20 * (10**18);
    uint256 public SUB_GAS = 4 * (10**18);
    uint256 public CUSTOMED_PRICE_GAS = 100 * (10**18);
    uint256 public MAX_YEAR = 5;
    uint256 public RARE_TYPE_LENGTH = 6;

    event Paid(address payer,bytes name , string option, uint256 amount, bytes32 receipt);
    event SettingChanged();
    
    function emitPaid(address payer, bytes memory name, string memory option, uint256 amount) 
        internal returns (bytes32){
            
        bytes32 receipt =  keccak256(abi.encodePacked(payer,name, option, amount,now));
        emit Paid(payer,name,option,amount,receipt);
        
        return receipt;
    }
    
    
    function setARootGas(uint256 newGas) external Admin {
        AROOT_GAS = newGas;
        emit SettingChanged();
    }
    function setBRootGas(uint256 newGas) external Admin {
        BROOT_GAS = newGas;
        emit SettingChanged();
    }
    function setSubGas(uint256 newGas) external Admin {
        SUB_GAS = newGas;
        emit SettingChanged();
    }
    function setCustomedPriceGas(uint256 newGas) external Admin {
        CUSTOMED_PRICE_GAS = newGas;
        emit SettingChanged();
    }
    function setMaxYear(uint256 year) external Admin {
        MAX_YEAR = year;
        emit SettingChanged();
    }
    function setRareTypeLength(uint8 len) external Admin {
        RARE_TYPE_LENGTH = len;
        emit SettingChanged();
    }

    string private constant REGISTERROOT = "REGISTERROOT";
    string private constant REGISTERSUB = "REGISTERSUB";
    string private constant OPENCUSTOMEDPRICE = "OPENCUSTOMEDPRICE";
    string private constant RECHARGE = "RECHARGE";

    ERC20 private t;
    BasOwnership private o;
    BasAsset private a;
    BasDNS private d;
    BasMiner private m;
    BasRule private r;

    constructor(address _t, address _o, address _a, address _d, address _m, address _r)
        public
    {
        t = ERC20(_t);
        o = BasOwnership(_o);
        a = BasAsset(_a);
        d = BasDNS(_d);
        m = BasMiner(_m);
        r = BasRule(_r);
    }
    
    function checkAssociatedContractAddress() external view returns (
        address BasToken,
        address BasOwnership,
        address BasAsset,
        address BasDNS,
        address BasMiner,
        address BasRule){
            BasToken = address(t);
            BasOwnership = address(o);
            BasAsset = address(a);
            BasDNS = address(d);
            BasMiner = address(m);
            BasRule = address(r);
        }
    
    modifier Owner(bytes32 nameHash) {
        require(o.isValid(nameHash, msg.sender), "owner only");
        _;
    }

    
    function validDuration(uint8 y) public view returns (bool) {
        return (y <= MAX_YEAR && y > 0);
    }

    function evalueRootPrice(
        bytes memory name,
        bool isCustomed,
        uint8 durationInYear
    )
        public
        view
        returns (bytes32 nameHash, bool isValid, uint256 cost, bool exist)
    {
        nameHash = a.Hash(name);
        bool isRare;
        (isValid, isRare) = r.classifyRoot(name,RARE_TYPE_LENGTH);
        exist = o.exist(nameHash);
        isValid =
            isValid &&
            validDuration(durationInYear) &&
            o.isWild(nameHash);
        if (isValid) {
            if (isRare) {
                cost = AROOT_GAS.mul(durationInYear);
            } else {
                cost = BROOT_GAS.mul(durationInYear);
            }
            if (isCustomed) {
                cost  = cost.add(CUSTOMED_PRICE_GAS);
            }
        }
    }

    function evalueSubPrice(
        bytes memory rName,
        bytes memory sName,
        uint8 durationInYear
    )
        public
        view
        returns (
            bytes32 nameHash,
            bytes memory totalName,
            bytes32 rootHash,
            bool isValid,
            address rootOwner,
            bool isCustomed,
            uint256 cost,
            bool exist
        )
    {
        nameHash = a.TotalNameHash(sName, rName);
        totalName = abi.encodePacked(sName, ".", rName);
        rootHash = a.Hash(rName);
        rootOwner = o.ownerOf(rootHash);
        exist = o.exist(nameHash);
        (bool rValid, ) = r.classifyRoot(rName,RARE_TYPE_LENGTH);
        bool sValid = r.verifySub(sName,rName.length);
        isValid =
            rValid &&
            sValid &&
            validDuration(durationInYear) &&
            o.isWild(nameHash);
        (, bool isOpen, bool _isCustomed, uint256 customedPrice) = a.Root(
            rootHash
        );
        isValid =
            isValid &&
            (rootOwner == msg.sender || isOpen || o.isWild(rootHash));
        isCustomed = _isCustomed;
        if (isValid) {
            if (isCustomed) {
                cost = customedPrice.mul(durationInYear);
            } else {
                cost = SUB_GAS.mul(durationInYear);
            }
        }
    }

    function registerRoot(
        bytes calldata name,
        bool isOpen,
        bool isCustomed,
        uint256 cusPrice,
        uint8 durationInYear
    ) external {
        (bytes32 nameHash, bool isValid, uint256 cost, bool exist) = evalueRootPrice(
            name,
            isCustomed,
            durationInYear
        );
        require(isValid, "not valid");
        require(
            t.transferFrom(msg.sender, address(m), cost),
            "not enough allowance"
        );
        
        m._c_allocateProfit(cost,m.AllocationRoot(), emitPaid(msg.sender, name, REGISTERROOT, cost), address(0));
        
        uint256 expire = now.add((durationInYear * 365 days));
        if (exist) {
            o._c_takeover(nameHash, msg.sender, expire);
            a._c_updateRoot(nameHash, isOpen, isCustomed, cusPrice);
        } else {
            o._c_add(nameHash, msg.sender, expire);
            a._c_addRoot(name, isOpen, isCustomed, cusPrice);
        }
    }

    function _profitSub(address rootOwner, bool isCustomed, uint256 cost, bytes32 receiptNumber)
        internal
    {   
        uint8 allocateType;
        if (rootOwner == msg.sender) {
            allocateType = m.AllocationSelfSub();
        } else if (isCustomed) {
            allocateType = m.AllocationCustomedSub();
        } else {
            allocateType = m.AllocationSub();
        }
        require(
            t.transferFrom(msg.sender, address(m), cost),
            "not enough allowance"
        );
        m._c_allocateProfit(cost, allocateType, receiptNumber, rootOwner);
    }

    function registerSub(
        bytes calldata rName,
        bytes calldata sName,
        uint8 durationInYear
    ) external {
        (bytes32 nameHash, bytes memory totalName, bytes32 rootHash, bool isValid, address rootOwner, bool isCustomed, uint256 cost, bool exist) = evalueSubPrice(
            rName,
            sName,
            durationInYear
        );
        require(isValid, "not valid");
        
        _profitSub(rootOwner, isCustomed, cost,emitPaid(msg.sender, totalName,REGISTERSUB, cost));
        
        uint256 expire = now.add((durationInYear * 365 days));
        if (exist) {
            o._c_takeover(nameHash, msg.sender, expire);
        } else {
            o._c_add(nameHash, msg.sender, expire);
            a._c_addSub(totalName, rootHash);
        }
    }

    function recharge(bytes calldata name, uint8 durationInYear) external {
        bytes32 nameHash = a.Hash(name);
        address owner = o.ownerOf(nameHash);
        require(owner != address(0), "not exist");
        (, bytes32 rHash) = a.Sub(nameHash);
        uint256 cost;
        if (rHash == bytes32(0)) {
            (, bool isRare) = r.classifyRoot(name,RARE_TYPE_LENGTH);
            if (isRare) {
                cost = AROOT_GAS.mul(durationInYear);
            } else {
                cost = BROOT_GAS.mul(durationInYear);
            }
            m._c_allocateProfit(cost,m.AllocationRoot(), emitPaid(msg.sender, name, RECHARGE, cost), address(0));
        } else {
            address rootOwner = o.ownerOf(rHash);
            (, , bool isCustomed, uint256 customedPrice) = a.Root(rHash);
            if (o.isValid(rHash, rootOwner)) {
                cost = customedPrice.mul(durationInYear);
            } else {
                cost = SUB_GAS.mul(durationInYear);
            }
            
            _profitSub(rootOwner, isCustomed, cost,emitPaid(msg.sender,name,RECHARGE,cost));
            
        }
        require(
            t.transferFrom(msg.sender, address(m), cost),
            "not enough allowance"
        );
        o._c_extend(nameHash, durationInYear * 365 days);
    }

    function openCustomedPrice(bytes32 nameHash, uint256 price)
        external
        Owner(nameHash)
    {
        require(price > SUB_GAS, "can't set price lower than default");
        require(
            t.transferFrom(msg.sender, address(m), CUSTOMED_PRICE_GAS),
            "not enough allowance"
        );
        (bytes memory name, , , ) = a.Root(nameHash);
        m._c_allocateProfit(CUSTOMED_PRICE_GAS,m.AllocationRoot(), emitPaid(msg.sender, name, OPENCUSTOMEDPRICE, CUSTOMED_PRICE_GAS), address(0));
        a._c_updateRoot(nameHash, true, true, price);
    }

    function closeCustomedPrice(bytes32 nameHash) external Owner(nameHash) {
        (, bool isOpen, , uint256 price) = a.Root(nameHash);
        a._c_updateRoot(nameHash, isOpen, false, price);
    }

    function openToPublic(bytes32 nameHash) external Owner(nameHash) {
        (, , bool isCustomed, uint256 price) = a.Root(nameHash);
        a._c_updateRoot(nameHash, true, isCustomed, price);
    }

    function closeToPublic(bytes32 nameHash) external Owner(nameHash) {
        (, , bool isCustomed, uint256 price) = a.Root(nameHash);
        a._c_updateRoot(nameHash, false, isCustomed, price);
    }

    function setRecord(
        bytes32 nameHash,
        bytes4 ipv4,
        bytes16 ipv6,
        bytes calldata bca,
        bytes calldata opData,
        string calldata aliasName
    ) external Owner(nameHash) {
        d._c_update(nameHash, ipv4, ipv6, bca, opData, aliasName);
    }

}
