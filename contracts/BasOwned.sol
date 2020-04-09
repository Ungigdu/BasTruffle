pragma solidity >=0.5.0;

import "./BasOwnership.sol";

contract BasOwned {
    BasOwnership public o;

    constructor(address _o) public {
        o = BasOwnership(_o);
    }

    modifier Admin {
        require(msg.sender == o.admin(), "admin only");
        _;
    }

    modifier ContractCaller {
        require(msg.sender == o.contractCaller(), "contract caller only");
        _;
    }
    
    modifier Allowed(bytes32 nameHash) {
        require(o.isValid(nameHash, msg.sender), "not owned");
        require(o.allowance(msg.sender,nameHash)==address(this), "not allowed");
        _;
    }

    modifier Owner(bytes32 nameHash) {
        require(o.isValid(nameHash, msg.sender), "owner only");
        _;
    }

    modifier Wild(bytes32 nameHash) {
        require(o.isWild(nameHash), "not Wild");
        _;
    }

    modifier Exist(bytes32 nameHash) {
        require(o.exist(nameHash), "not exist");
        _;
    }

    modifier NotExist(bytes32 nameHash) {
        require(!o.exist(nameHash), "exist");
        _;
    }

    modifier Expired(bytes32 nameHash) {
        require(o.expired(nameHash), "not expired");
        _;
    }

    modifier Valid(bytes32 nameHash, address check) {
        require(o.isValid(nameHash, check), "not valid");
        _;
    }
}
