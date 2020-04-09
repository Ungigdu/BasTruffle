pragma solidity >=0.5.0;

import "./BasOwned.sol";

contract BasAsset is BasOwned {
    constructor(address _o) public BasOwned(_o) {}

    struct SubItem {
        bytes totalName;
        bytes32 rootHash;
    }

    struct RootItem {
        bytes rootName;
        bool openToPublic;
        bool isCustomed;
        uint256 customedPrice;
    }

    event RootChanged(bytes32 nameHash);
    event SubChanged(bytes32 nameHash);

    mapping(bytes32 => RootItem) public Root;
    mapping(bytes32 => SubItem) public Sub;

    function rootExist(bytes32 nameHash) public view returns (bool) {
        return Root[nameHash].rootName.length > 0;
    }

    function subExist(bytes32 nameHash) public view returns (bool) {
        return Sub[nameHash].totalName.length > 0;
    }

    modifier RootChange(bytes32 nameHash) {
        _;
        emit RootChanged(nameHash);
    }

    function Hash(bytes memory name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(name));
    }

    function TotalNameHash(bytes memory sName, bytes memory rName)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(sName, ".", rName));
    }

    function _a_updateRoot(
        bytes calldata rootName,
        bool openToPublic,
        bool isCustomed,
        uint256 customedPrice
    ) external Admin {
        bytes32 nameHash = Hash(rootName);
        Root[nameHash] = RootItem(
            rootName,
            openToPublic,
            isCustomed,
            customedPrice
        );
        emit RootChanged(nameHash);
    }

    function _c_addRoot(
        bytes calldata rootName,
        bool openToPublic,
        bool isCustomed,
        uint256 customedPrice
    ) external ContractCaller {
        bytes32 nameHash = Hash(rootName);
        require(!rootExist(nameHash), "root exist");
        Root[nameHash] = RootItem(
            rootName,
            openToPublic,
            isCustomed,
            customedPrice
        );
        emit RootChanged(nameHash);
    }

    function _c_updateRoot(
        bytes32 nameHash,
        bool openToPublic,
        bool isCustomed,
        uint256 customedPrice
    ) external ContractCaller {
        require(rootExist(nameHash), "root not exist");
        Root[nameHash] = RootItem(
            Root[nameHash].rootName,
            openToPublic,
            isCustomed,
            customedPrice
        );
        emit RootChanged(nameHash);
    }

    function _a_updateSub(bytes calldata totalName, bytes32 rootHash)
        external
        Admin
    {
        bytes32 nameHash = Hash(totalName);
        Sub[nameHash] = SubItem(totalName, rootHash);
        emit SubChanged(nameHash);
    }

    function _c_addSub(bytes calldata totalName, bytes32 rootHash)
        external
        ContractCaller
    {
        bytes32 nameHash = Hash(totalName);
        require(!subExist(nameHash), "sub exist");
        Sub[nameHash] = SubItem(totalName, rootHash);
        emit SubChanged(nameHash);
    }

}
