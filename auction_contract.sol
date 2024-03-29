//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract AuctionCreator{
    Auction[] public auctions;

    function createAuction() public{
        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}

contract Auction{
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

    enum State {Started, Running, Ended, Canceled}
    State public auctionState;

    uint public highestBindingBid;
    address payable public highestBidder;

    mapping(address => uint) public bids;
    uint bidIncrement;

    constructor(address eoa){
        owner = payable(eoa);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + 3;
        ipfsHash = "";
        bidIncrement = 1000000000000000000;
    }

    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }

    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }

    function min(uint a, uint b) pure internal returns(uint){
        if(a <= b){
            return a;
        }else{
            return b;
        }
    }

    function cancelAuction() public onlyOwner{
        auctionState = State.Canceled;
    }

    function placeBid() public payable notOwner afterStart beforeEnd {
        require(auctionState == State.Running);
        require(msg.value >= 100);

        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid);

        bids[msg.sender] = currentBid;

        if(currentBid <= bids[highestBidder]){
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }else{
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
      
    }

    function finallizeAuction() public{
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0);

        address payable recipient;
        uint value;

        if(auctionState == State.Canceled){ // auction was canceled
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        }else{ // auction ended (not canceled)
            if(msg.sender == owner){ // this is the owner
                recipient = owner;
                value = highestBindingBid;           
            
            }else{ // this is a bidder
                if(msg.sender == highestBidder){
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                }else{ // this is not the owner nor the highestBidder
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        
        }

        //reset of recipient bids prevents abuse 

        bids[recipient] = 0;

        recipient.transfer(value);
    }
}