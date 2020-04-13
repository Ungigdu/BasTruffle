pragma solidity >= 0.5.0;

import "./BasToken.sol";
import "./owned.sol";

contract BasMiner is owned{
    using SafeMath for uint256;

    uint256 public constant MainNodeSize = 64;
    
    uint8 public constant AllocationRoot = 0;
    uint8 public constant AllocationSub = 1;
    uint8 public constant AllocationSelfSub = 2;
    uint8 public constant AllocationCustomedSub = 3;
    
    struct Allocation {
        uint256 toAdmin;
        uint256 toBurn;
        uint256 toMiner;
        uint256 toRootOwner;
    }

    address public Satoshi_Nakamoto;
    address public OANNAddress;
    BasToken public token;
    
    Allocation public rootSetting;
    Allocation public defaultSubSetting;
    Allocation public selfSubSetting;
    Allocation public customedSubSetting;

    address[] public MainNode;
    
    mapping(address=>uint) public balanceOf;

    constructor(address t, address team) public {
        token = BasToken(t);
        Satoshi_Nakamoto = team;
        
        rootSetting = Allocation(20, 40, 40, 0);
        emit AllocationChanged(AllocationRoot, 20, 40, 40, 0);
        
        defaultSubSetting = Allocation(10, 40, 40, 10);
        emit AllocationChanged(AllocationSub, 10, 40, 40, 10);
        
        selfSubSetting = Allocation(10,30,40,20);
        emit AllocationChanged(AllocationSelfSub, 10,30,40,20);
        
        customedSubSetting = Allocation(10, 30, 40, 15);
        emit AllocationChanged(AllocationCustomedSub, 10, 30, 40, 15);
    }

    event Receipt(bytes32 receiptNumber, uint256 amout, uint8 allocation, address from);
    event Withdraw(address drawer, uint256 amout);
    event AllocationChanged(uint8 allocateType, uint256 toAdmin, uint256 toBurn, uint256 toMiner, uint256 toRoot);
    event MinerAdd(address miner);
    event MinerRemove(address miner);
    event MinerReplace(address oldMiner, address newMiner);
    
    function GetAllMainNodeAddress() public view returns(address[] memory){
        return MainNode;
    }
    
    function _a_emergencyWithdraw(address to,uint256 no) Admin external{
        token.transfer(to, no);
    }

    function _a_changeRootSetting(uint256 admin, uint256 burn, uint256 miner) Admin external{
        require ((admin.add(burn).add(miner)) <= 100,"error sum up");
        rootSetting.toAdmin = admin;
        rootSetting.toBurn = burn;
        rootSetting.toMiner = miner;
        rootSetting.toRootOwner = 0;
        emit AllocationChanged(AllocationRoot, admin, burn, miner, 0);
    }
    
    function _a_changeDefaultSubSetting(uint256 admin, uint256 burn, uint256 miner, uint256 root) Admin external{
        require ((admin.add(burn).add(miner).add(root)) <= 100,"error sum up");
        defaultSubSetting.toAdmin = admin;
        defaultSubSetting.toBurn = burn;
        defaultSubSetting.toMiner = miner;
        defaultSubSetting.toRootOwner = root;
        emit AllocationChanged(AllocationSub, admin, burn, miner, root);
    }
    
    function _a_changeSelfSubSetting(uint256 admin, uint256 burn, uint256 miner, uint256 root) Admin external {
        require ((admin.add(burn).add(miner).add(root)) <= 100,"error sum up");
        selfSubSetting.toAdmin = admin;
        selfSubSetting.toBurn = burn;
        selfSubSetting.toMiner = miner;
        selfSubSetting.toRootOwner = root;
        emit AllocationChanged(AllocationSelfSub, admin, burn, miner, root);
    }
    
    function _a_changeCustomedSubSetting(uint256 admin, uint256 burn, uint256 miner, uint256 root) Admin external{
        require ((admin.add(burn).add(miner).add(root)) <= 100,"error sum up");
        customedSubSetting.toAdmin = admin;
        customedSubSetting.toBurn = burn;
        customedSubSetting.toMiner = miner;
        customedSubSetting.toRootOwner = root;
        emit AllocationChanged(AllocationCustomedSub, admin, burn, miner, root);
    }

    function _a_addMiner(address m) Admin external{
        MainNode.push(m);
        require(MainNode.length <= MainNodeSize,"nodes is full");
        emit MinerAdd(m);
    }

    function _a_replaceMiner(address oldM, address newM) Admin external{
        require(MainNode.length > 0,"nodes empty");

        for (uint256 i = 0; i < MainNode.length; i++){
            if (MainNode[i] == oldM){
                MainNode[i] = newM;
                break;
            }
        }
        emit MinerReplace(oldM, newM);
    }

    function _a_removeMiner(address miner) Admin external{
        require(MainNode.length > 0,"nodes empty");
        for (uint256 i = 0; i < MainNode.length; i++){
            if (MainNode[i] == miner){
                MainNode[i] = MainNode[MainNode.length - 1];
                delete MainNode[MainNode.length - 1];
                break;
            }
        }
        emit MinerRemove(miner);
    }

    function withdraw() external {
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0,"balance is 0");
        token.transfer(msg.sender, balance);
        balanceOf[msg.sender] = 0;
        
        if (msg.sender == Satoshi_Nakamoto){
            token.burn(balanceOf[address(0)]);
            balanceOf[address(0)] = 0;
        }
        
        emit Withdraw(msg.sender, balance);
    }


    function _c_allocateProfit(uint256 cost, uint8 allocateType, bytes32 receiptNumber, address rootOwner) ContractCaller external {
        require(cost > 0 , "cost is 0");
        
        uint256 burnSum;
        uint256 minerSum;
        uint256 rootSum;
        Allocation memory setting;
        
        
        if (allocateType==AllocationRoot){
            setting = rootSetting;
        }else if (allocateType == AllocationSub){
            setting = defaultSubSetting;
        }else if (allocateType == AllocationSelfSub){
            setting = selfSubSetting;
        }else if (allocateType == AllocationCustomedSub){
            setting = customedSubSetting;
        }else{
            revert("undefined allocate type");    
        }
        
        if (setting.toBurn > 0){
            burnSum = cost.mul(setting.toBurn).div(100);
            balanceOf[address(0)] = balanceOf[address(0)].add(burnSum);
        }

        if (setting.toMiner > 0 && MainNode.length > 0){
            minerSum = cost.mul(setting.toMiner).div(100);
            _splitToMiner(minerSum);
        }

        if (setting.toRootOwner > 0){
            rootSum = cost.mul(setting.toRootOwner).div(100);
            balanceOf[rootOwner] = balanceOf[rootOwner].add(rootSum);
        }
        
        balanceOf[Satoshi_Nakamoto] = balanceOf[Satoshi_Nakamoto].add(cost - burnSum - minerSum - rootSum);
        
        emit Receipt(receiptNumber, cost, allocateType, msg.sender);
    } 
    
    function _splitToMiner(uint256 sum) internal{

        uint256 one_porift = sum.div(MainNode.length);
        for (uint256 i = 0; i < MainNode.length; i++){
            address miner_address = MainNode[i];
            balanceOf[miner_address] = balanceOf[miner_address].add(one_porift);
        }
    }
    
}