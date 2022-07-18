//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract A{
    address public ownerA;
    constructor() {
        ownerA = msg.sender;
    }
}

contract Creator{
    address public ownerCreator;
    A[] public deployedA;

    constructor(){
        ownerCreator = msg.sender;
    }

    function deployA() public{
        A new_A_address = new A();
        deployedA.push(new_A_address);

    }
}