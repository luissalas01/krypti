pragma solidity ^0.7.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract KriptyGob is Ownable {

    string public constant name = "Kripty Governance contract";

    function supportShortVotes() public pure returns (uint) { return 10000000; }
    //function supportVotes() public pure returns (uint) { return 10000000000; }

    function proposalShortThreshold() public pure returns (uint) { return 500000; }
    //function proposalThreshold() public pure returns (uint) { return 500000000;

    function votingDelay() public pure returns (uint) { return 86400; } //1 days in sec
    function votingPeriod() public pure returns (uint) { return 259200; } //3 days in sec

    KriptyInterface public Kripty;

    uint public proposalCount;

    struct Proposal {
        uint id;
        address proposer;
        uint startDate;
        uint endDate;
        uint proVotes;
        uint againsVotes;
        bool canceled;
        bool executed;
        string description;
        mapping (address => Receipt) receipts;
        address[] keys;
    }

    struct Receipt {
        bool hasVoted;
        bool proVote;
        uint votes;
    }

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Expired,
        Executed
    }

    mapping (uint => Proposal) public proposals;
    mapping (address => uint) public lastestProposalIds;

    event ProposalCreated(uint id, address proposer, uint startBlock, uint endBlock, string description);
    event Vote(address voter, uint proposalId, bool proVote, uint votes);
    event ProposalCanceled(uint id);
    event ProposalExecuted(uint id);

    constructor(address kripty_) public {
        Kripty = KriptyInterface(kripty_);
    }

    function propose(string memory description_) public returns (uint) {
        require(Kripty.balanceOf(msg.sender) >= proposalShortThreshold(), "Proposer votes below proposal threshold");

        uint lastestProposalId = lastestProposalIds[msg.sender];
        if (lastestProposalId != 0) {
            ProposalState proposalState = state(lastestProposalId);
            require(proposalState != ProposalState.Active, "Found an active proposal from you");
            require(proposalState != ProposalState.Pending, "Found a pending proposal from you");
        }
        
        uint startDate = block.timestamp + votingDelay();
        uint endDate = startDate + votingPeriod();
        proposalCount++;

        proposals[proposalCount].id = proposalCount;
        proposals[proposalCount].proposer = msg.sender;
        proposals[proposalCount].startDate = startDate;
        proposals[proposalCount].endDate = endDate;
        proposals[proposalCount].proVotes = 0;
        proposals[proposalCount].againsVotes = 0;
        proposals[proposalCount].canceled = false;
        proposals[proposalCount].executed = false;
        proposals[proposalCount].description = description_;

        lastestProposalIds[proposals[proposalCount].proposer] = proposals[proposalCount].id;
        Kripty._burn(msg.sender, proposalShortThreshold());

        emit ProposalCreated(proposals[proposalCount].id, msg.sender, startDate, endDate, description_);
        return proposals[proposalCount].id;
    }

    function execute(uint proposalId) public payable onlyOwner() {
        //TODO: agregar require de estado vs supportShortVotes
        require(state(proposalId) != ProposalState.Defeated || state(proposalId) != ProposalState.Canceled, "Votos no suficientes para ejecutar esta propuesta");
        Proposal storage proposal = proposals[proposalId];

        proposal.executed = true;

        for(uint i = 0; i < proposal.keys.length ; i++){
            Kripty.freezeAccount(proposal.keys[i] , false);
        }

        emit ProposalExecuted(proposalId);
    }

    function cancel(uint proposalId) public onlyOwner() {
        require(state(proposalId) != ProposalState.Executed || state(proposalId) != ProposalState.Succeeded, "No se puede cancelar una propuesta que ya fue ejecutada");

        Proposal storage proposal = proposals[proposalId];
        proposal.canceled = true;

        for(uint i = 0; i < proposal.keys.length; i++){
            Kripty.freezeAccount(proposal.keys[i] , false);
        }

        Kripty._mint(proposal.proposer , (proposalShortThreshold()*90)/100);

        emit ProposalCanceled(proposalId);
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.timestamp <= proposal.startDate) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endDate) {
            return ProposalState.Active;
        } else if (proposal.proVotes <= proposal.againsVotes || proposal.proVotes < supportShortVotes()) {
            return ProposalState.Defeated;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.endDate){
            return ProposalState.Expired;
        } else {
            return ProposalState.Succeeded;
        }
    }

    function vote(address voter, uint proposalId, bool support) public {
        require(state(proposalId) == ProposalState.Active || state(proposalId) == ProposalState.Pending, "Voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false , "voter already voted");
        
        uint votes = Kripty.balanceOf(voter);

        if (support) {
            proposal.proVotes += votes;
        } else {
            proposal.againsVotes += votes;
        }
        proposal.keys.push(voter);

        receipt.hasVoted = true;
        receipt.proVote = support;
        receipt.votes = votes;

        Kripty.freezeAccount(voter, true);

        emit Vote(voter, proposalId, support, votes);

    }
 
}

interface KriptyInterface {
        function balanceOf(address account) external view returns (uint);
        function freezeAccount(address target, bool freeze) external;
        function _burn(address account, uint amount) external;
        function _mint(address account, uint amount) external;
}
