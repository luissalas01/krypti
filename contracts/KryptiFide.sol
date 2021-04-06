pragma solidity ^0.7.0;

import "./Krypti.sol";

contract KriptyFide {
    
    KriptyInterfaceFide public Krypti;

    constructor(address Krypti_) public {
        Krypti = KriptyInterfaceFide(Krypti_);
    }

    function init(address) public{
        
    }

}

interface KriptyInterfaceFide {
    function transfer(address recipient, uint amount) external;
}