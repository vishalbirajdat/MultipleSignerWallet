// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MultipleSignerWallet {
    uint256 public totalSigners;
    address public owner;
    mapping(address => bool) public WalletSigners;
    uint256 private randNonce = 0;
    uint256[] public AllTransactionIDs;
    uint256 public walletAmount;

    event FundAdded(address indexed fundProvider, uint256 indexed amount);
    event NewSigner(address signer, uint256 time);
    event SignerTransactionCreated(
        address indexed signer,
        uint256 id,
        address indexed receiver,
        uint256 amount,
        uint256 indexed time
    );
    event CompletedTransaction(uint256 indexed id, uint256 time);

    struct transactionDetail {
        bool exist;
        address creator;
        address receiver;
        uint256 amount;
        uint256 totalSigner;
        uint256 id;
        mapping(address => bool) signers;
        uint256 trueSigners;
        bool completed;
    }

    mapping(uint256 => transactionDetail) public TransactionDetails;

    constructor() {
        owner = msg.sender;
    }

    modifier isAdmin() {
        require(owner == msg.sender);
        _;
    }

    function AddAmountInWallet() public payable {
        walletAmount += msg.value;
        emit FundAdded(msg.sender, msg.value);
    }

    function AddSigner(address _adr) public isAdmin {
        require(WalletSigners[_adr] != true, "You have already Signer");
        WalletSigners[_adr] = true;
        totalSigners++;
        emit NewSigner(_adr, block.timestamp);
    }

    function ChangeAdmin(address _adr) public isAdmin {
        owner = _adr;
    }

    function CreateTransaction(address _receiver, uint256 _amount) public {
        address senderAdr = msg.sender;
        require(
            WalletSigners[senderAdr] == true,
            "You are not Signer contact to admin"
        );
        uint256 NewrandNonce = randNonce + 1;
        uint256 id = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, senderAdr, NewrandNonce)
            )
        );
        transactionDetail storage trx = TransactionDetails[id];
        trx.exist = true;
        trx.id = id;
        trx.receiver = _receiver;
        trx.amount = _amount;
        trx.creator = senderAdr;
        trx.completed = false;
        AllTransactionIDs.push(id);
        randNonce = NewrandNonce;

        emit SignerTransactionCreated(
            msg.sender,
            id,
            _receiver,
            _amount,
            block.timestamp
        );
    }

    function SignTransaction(uint256 _id, bool _vote) public {
        require(
            WalletSigners[msg.sender] == true,
            "You are not Signer contact to admin"
        );
        require(
            TransactionDetails[_id].exist == true,
            "you have entered wrong Id "
        );
        require(
            TransactionDetails[_id].signers[msg.sender] != true,
            "you have already signed "
        );
        require(
            TransactionDetails[_id].completed != true,
            "Transaction is already done"
        );
        transactionDetail storage trx = TransactionDetails[_id];
        if (_vote) {
            trx.trueSigners++;
        }
        trx.signers[msg.sender] = true;
        trx.totalSigner++;
    }

    function ChangeSignTransaction(uint256 _id, bool _vote) public {
        require(
            TransactionDetails[_id].exist == true,
            "you have entered wrong Id"
        );
        require(
            TransactionDetails[_id].completed != true,
            "Transaction is already done"
        );
        require(
            TransactionDetails[_id].signers[msg.sender] == true,
            "you have need first signTransaction "
        );
        transactionDetail storage trx = TransactionDetails[_id];
        if (_vote) {
            trx.trueSigners++;
        } else {
            trx.trueSigners--;
        }
    }

    function CheckTransactionStatus(uint256 _id) private view returns (bool) {
        require(
            TransactionDetails[_id].exist == true,
            "you have entered wrong Id"
        );
        transactionDetail storage trx = TransactionDetails[_id];
        uint256 prc = (100 * trx.trueSigners) / totalSigners;
        if (prc >= 60) {
            return true;
        }
        return false;
    }

    function CheckTotalTransaction() public view returns (uint256) {
        require(
            WalletSigners[msg.sender] == true,
            "You are not Signer contact to admin"
        );
        return AllTransactionIDs.length;
    }

    function getLastTransactionId() public view returns (uint256) {
        require(
            WalletSigners[msg.sender] == true,
            "You are not Signer contact to admin"
        );
        if (AllTransactionIDs.length > 0) {
            return AllTransactionIDs[AllTransactionIDs.length - 1];
        } else {
            return 0;
        }
    }

    function CompleteTransaction(uint256 _id) public payable {
        require(
            WalletSigners[msg.sender] == true,
            "You are not Signer contact to admin"
        );
        require(
            TransactionDetails[_id].exist == true,
            "you have entered wrong Id"
        );
        require(
            walletAmount >= TransactionDetails[_id].amount,
            "Add Fund in wallet"
        );
        require(CheckTransactionStatus(_id) == true, "Need More Signers");
        require(
            TransactionDetails[_id].completed == false,
            "you have already amount transfered"
        );
        transactionDetail storage trx = TransactionDetails[_id];
        payable(trx.receiver).transfer(trx.amount);
        walletAmount -= trx.amount;
        trx.completed = true;

        emit CompletedTransaction(_id, block.timestamp);
    }
}
