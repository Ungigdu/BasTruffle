pragma solidity >= 0.5.0;

contract BasContact {

    struct Contact{
        string phone;
        string email;
        string url;
        string location;
    }

    mapping(address=>Contact) public OwnerContact;

    constructor() public{}
    
    function SetContact(string calldata email,
                    string calldata url,
                    string calldata phone,
                    string calldata location)  external{
        Contact storage item = OwnerContact[msg.sender];

        item.email = email;
        item.url = url;
        item.phone = phone;
        item.location = location;
    }

    function RemoveContact() external{
        delete OwnerContact[msg.sender];
    }

    function SetEmail(string calldata email) external{
        OwnerContact[msg.sender].email = email;
    }

    function SetURL(string calldata url) external{
        OwnerContact[msg.sender].url = url;
    }

    function SetPhone(string calldata phone) external{
        OwnerContact[msg.sender].phone = phone;
    }

    function SetLocation(string calldata location) external{
        OwnerContact[msg.sender].location = location;
    }
}