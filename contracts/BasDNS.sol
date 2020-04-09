pragma solidity >=0.5.0;

import "./BasOwned.sol";

contract BasDNS is BasOwned {
    constructor(address _o) public BasOwned(_o) {}

    event DNSChanged(bytes32 nameHash);

    struct DNSRecord {
        bytes4 ipv4;
        bytes16 ipv6;
        bytes bca;
        bytes opData;
        string aliasName;
    }

    mapping(bytes32 => DNSRecord) public DNS;

    modifier DNSChange(bytes32 nameHash) {
        _;
        emit DNSChanged(nameHash);
    }

    function _a_update(
        bytes32 nameHash,
        bytes4 ipv4,
        bytes16 ipv6,
        bytes calldata bca,
        bytes calldata opData,
        string calldata aliasName
    ) external Admin DNSChange(nameHash) {
        DNS[nameHash] = DNSRecord(ipv4, ipv6, bca, opData, aliasName);
    }

    function _c_update(
        bytes32 nameHash,
        bytes4 ipv4,
        bytes16 ipv6,
        bytes calldata bca,
        bytes calldata opData,
        string calldata aliasName
    ) external ContractCaller DNSChange(nameHash) {
        DNS[nameHash] = DNSRecord(ipv4, ipv6, bca, opData, aliasName);
    }

    function query(bytes32 nameHash)
        external
        view
        returns (
            bytes4 ipv4,
            bytes16 ipv6,
            bytes memory bca,
            bytes memory opData,
            string memory aliasName
        )
    {
        DNSRecord memory record = DNS[nameHash];
        ipv4 = record.ipv4;
        ipv6 = record.ipv6;
        bca = record.bca;
        opData = record.opData;
        aliasName = record.aliasName;
    }

    function _c_setIP(bytes32 nameHash, bytes4 ipv4, bytes16 ipv6)
        external
        ContractCaller
        DNSChange(nameHash)
    {
        DNS[nameHash].ipv4 = ipv4;
        DNS[nameHash].ipv6 = ipv6;
    }

    function _c_setBCAddress(bytes32 nameHash, bytes calldata bcAddress)
        external
        ContractCaller
        DNSChange(nameHash)
    {
        DNS[nameHash].bca = bcAddress;
    }

    function _c_setOpData(bytes32 nameHash, bytes calldata opData)
        external
        ContractCaller
        DNSChange(nameHash)
    {
        DNS[nameHash].opData = opData;
    }

    function _c_setAlias(bytes32 nameHash, string calldata aName)
        external
        ContractCaller
        DNSChange(nameHash)
    {
        DNS[nameHash].aliasName = aName;
    }

    function _c_clearRecord(bytes32 nameHash)
        external
        ContractCaller
        DNSChange(nameHash)
    {
        delete DNS[nameHash];
    }
}
