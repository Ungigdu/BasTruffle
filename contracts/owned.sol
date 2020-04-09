pragma solidity >= 0.5.0;

contract owned {
    address public admin;
    address public contractCaller;

    constructor() public {
        admin = msg.sender;
    }

    modifier Admin {
        require(msg.sender == admin, "admin only");
        _;
    }

    function _a_changeAdmin(address newOwner) external Admin {
        admin = newOwner;
    }
    
    function _a_changeContract(address conAddr) external Admin {
        contractCaller = conAddr;
    }
    
    modifier ContractCaller {
        require(msg.sender == contractCaller, "contract caller only");
        _;
    }
}