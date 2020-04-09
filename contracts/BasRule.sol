pragma solidity >=0.5.0;

contract  BasRule{
    
    function validChar(bytes1 c) public pure returns (bool) {
        return
            (c >= 0x30 && c <= 0x39) ||
            (c >= 0x61 && c <= 0x7a) ||
            c == 0x2d ||
            c == 0x5f;
    }

    function classifyRoot(bytes memory name, uint256 rareLength) public pure returns (bool, bool) {
        if (name.length == 0 || name.length >= 64) {
            return (false, false);
        }
        bool isRare = true;
        for (uint256 i = 0; i < name.length; i++) {
            if (!validChar(name[i])) {
                return (false, false);
            }
            if (isRare) {
                isRare = !(i > rareLength - 1 ||
                    name[i] == 0x2d ||
                    name[i] == 0x5f);
            }
        }
        return (true, isRare);
    }
    
    function classifyRootS(string memory name, uint256 rareLength) public pure returns (bool,bool) {
        return classifyRoot(bytes(name), rareLength);
    } 

    function verifySub(bytes memory name, uint256 rootLength) public pure returns (bool) {
        uint256 remain = 256 - rootLength;
        if(name[0]==0x2E || name[name.length-1]==0x2E || name.length >= remain){
            return false;
        }
        uint256 segementLength = 0;
        bool meetDot = false;
        for (uint256 i = 0; i < name.length; i++) {
            if(validChar(name[i])){ //not dot
                segementLength += 1;
                meetDot = false;
                if(segementLength >= 64){
                    return false;
                }
            }else if(name[i] == 0x2E){   //dot
                if(meetDot){
                    return false;
                }
                meetDot = true;
                segementLength = 0;
            }else{
                return false;
            }
        }
        return true;
    }
    
    function verifySubS(string memory name, uint256 rootLength) public pure returns (bool){
        return verifySub(bytes(name),rootLength);
    }
}
