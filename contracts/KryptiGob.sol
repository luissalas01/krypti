pragma solidity ^0.7.0;

contract KryptiGob {

    string public constant name = "Kripty Governance contract";

    function supportVotes() public pure returns (uint) { return 100000; }

    function proposalThreshold() public pure returns (uint) { return 10000; }
    
    function votingDelay() public pure returns (uint) { return 1; } // 1 block

    function votingPeriod() public pure returns (uint) { return 17280; } //3 days in blocks

    KryptiInterface public Krypti;

    uint public proposalCount;

    struct Proposal {
        uint id;
        address proposer;
        uint startBlock;
        uint endBlock;
        uint proVotes;
        uint againsVotes;
        bool canceled;
        bool executed;
        string description;
        mapping (address => Receipt) receipts;
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

    constructor(address krypti_) public {
        Krypti = KryptiInterface(krypti_);
    }

    function propose(string memory description_) public returns (uint) {
        require(Krypti.balanceOf(msg.sender) > proposalThreshold(), "Proposer votes below proposal threshold");

        uint lastestProposalId = lastestProposalIds[msg.sender];
        if (lastestProposalId != 0) {
            ProposalState proposalState = state(lastestProposalId);
            require(proposalState != ProposalState.Active, "Found an active proposal from you");
            require(proposalState != ProposalState.Pending, "Found a pending proposal from you");

            uint startBlock = block.number + votingDelay();
            uint endBlock = startBlock + votingPeriod();

            proposals[proposalCount].id = proposalCount;
            proposals[proposalCount].proposer = msg.sender;
            proposals[proposalCount].startBlock = startBlock;
            proposals[proposalCount].endBlock = endBlock;
            proposals[proposalCount].proVotes = 0;
            proposals[proposalCount].againsVotes = 0;
            proposals[proposalCount].canceled = false;
            proposals[proposalCount].executed = false;
            proposals[proposalCount].description = description_;

            lastestProposalIds[proposals[proposalCount].proposer] = proposals[proposalCount].id;
            proposalCount++;

            emit ProposalCreated(proposals[proposalCount - 1].id, msg.sender, startBlock, endBlock, description_);
            return proposals[proposalCount - 1].id;
        }
    }

    function execute(uint proposalId) public payable {
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;

        for(uint i = 0; i<)

        emit ProposalExecuted(proposalId);
    }

    function cancel(uint proposalId) public {
        //ProposalState state = 
        require(state(proposalId) != ProposalState.Executed, "No se puede cancelar una propuesta que ya fue ejecutada");

        Proposal storage proposal = proposals[proposalId];
        proposal.canceled = true;

        emit ProposalCanceled(proposalId);
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.proVotes <= proposal.againsVotes || proposal.proVotes < supportVotes()) {
            return ProposalState.Defeated;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        //} else if (block.timestamp >= ) TODO: retornar expired
        } else {
            return ProposalState.Succeeded;
        }
    }

    function vote(address voter, uint proposalId, bool support) public {
        require(state(proposalId) == ProposalState.Active, "Voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false , "voter already voted");
        
        uint votes = Krypti.balanceOf(voter);

        if (support) {
            proposal.proVotes = votes;
        } else {
            proposal.againsVotes = votes;
        }

        receipt.hasVoted = true;
        receipt.proVote = support;
        receipt.votes = votes;

        Krypti.freezeAccount(voter, true);

        emit Vote(voter, proposalId, support, votes);

    }
 
}

interface KryptiInterface {
        function balanceOf(address account) external view returns (uint);
        function freezeAccount(address target, bool freeze) external;
}