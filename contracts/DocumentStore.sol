//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IDocumentStoreInterface.sol";

import "hardhat/console.sol";

contract DocumentStore is OwnableUpgradeable {
    string public name;
    string public email;
    string public legalReference;
    string public intentDeclaration;
    string public host;
    uint256 public expiredTime;

    address ownerManager;
    address[] public publishers;
    /// uint256 constant YEAR_IN_SECONDS = 31536000;

    /// A mapping of the document hash to the block number that was issued
    mapping(bytes32 => uint256) public documentIssued;
    /// A mapping of the hash of the claim being revoked to the revocation block number
    mapping(bytes32 => uint256) public documentRevoked;
    /// A mapping of the hash of the document to the expiration date
    mapping(bytes32 => uint256) public documentExpiration;
    /// A mapping of the hash of the document to the publisher
    mapping(bytes32 => address) public documentPublisher;

    event DocumentIssued(bytes32 indexed document);
    event DocumentRevoked(bytes32 indexed document);
    event PublisherChanged(
        address indexed documentStore,
        address[] currentPublishers
    );
    event ContractExpired(address indexed thisContract, uint256 time);
    event ContractInfoChanged(
        string _name,
        string _email,
        string _legalReference,
        string _intentDeclaration,
        string _host,
        uint256 _time
    );

    function initialize(
        string memory _name,
        string memory _email,
        string memory _legalReference,
        string memory _intentDeclaration,
        string memory _host,
        uint256 _time,
        address _owner,
        address _ownerManager
    ) public initializer {
        require(_time > block.timestamp, "Error: expired date has passed");
        super.__Ownable_init();
        super.transferOwnership(_owner);
        publishers.push(_owner);
        name = _name;
        email = _email;
        legalReference = _legalReference;
        intentDeclaration = _intentDeclaration;
        host = _host;
        ownerManager = _ownerManager;
        expiredTime = _time;
    }

    function getExpiredTime() external view returns (uint256) {
        return expiredTime;
    }

    function getName() external view returns (string memory) {
        return name;
    }

    function getEmail() external view returns (string memory) {
        return email;
    }

    function getLegalReference() external view returns (string memory) {
        return legalReference;
    }

    function getIntentDeclaration() external view returns (string memory) {
        return intentDeclaration;
    }

    function getHost() external view returns (string memory) {
        return host;
    }

    function getPublishers() external view returns (address[] memory) {
        return publishers;
    }

    function setName(
        string memory _name
    ) external onlyOwner contractNotExpired {
        name = _name;
        IDocumentStoreInterface(ownerManager).setName(address(this), _name);
        emit ContractInfoChanged(
            name,
            email,
            legalReference,
            intentDeclaration,
            host,
            expiredTime
        );
    }

    function setEmail(
        string memory _email
    ) external onlyOwner contractNotExpired {
        email = _email;
        IDocumentStoreInterface(ownerManager).setEmail(address(this), _email);
        emit ContractInfoChanged(
            name,
            email,
            legalReference,
            intentDeclaration,
            host,
            expiredTime
        );
    }

    function setLegalReference(
        string memory _legalReference
    ) external onlyOwner contractNotExpired {
        legalReference = _legalReference;
        IDocumentStoreInterface(ownerManager).setLegalReference(
            address(this),
            _legalReference
        );
        emit ContractInfoChanged(
            name,
            email,
            legalReference,
            intentDeclaration,
            host,
            expiredTime
        );
    }

    function setIntentDeclaration(
        string memory _intentDeclaration
    ) external onlyOwner contractNotExpired {
        intentDeclaration = _intentDeclaration;
        IDocumentStoreInterface(ownerManager).setIntentDeclaration(
            address(this),
            _intentDeclaration
        );
        emit ContractInfoChanged(
            name,
            email,
            legalReference,
            intentDeclaration,
            host,
            expiredTime
        );
    }

    function setHost(
        string memory _host
    ) external onlyOwner contractNotExpired {
        host = _host;
        IDocumentStoreInterface(ownerManager).setHost(address(this), _host);
        emit ContractInfoChanged(
            name,
            email,
            legalReference,
            intentDeclaration,
            host,
            expiredTime
        );
    }

    function setExpiredTime(uint256 _time) external onlyOwner {
        IDocumentStoreInterface(ownerManager).setExpiredTime(
            address(this),
            _time
        );
        expiredTime = _time;
        emit ContractInfoChanged(
            name,
            email,
            legalReference,
            intentDeclaration,
            host,
            expiredTime
        );
    }

    function removeAllPublishers() external onlyOwner contractNotExpired {
        while (publishers.length > 0) {
            publishers.pop();
        }
        emit PublisherChanged(address(this), publishers);
    }

    function addPublishers(
        address[] memory _newPublishers
    ) external onlyOwner contractNotExpired {
        while (publishers.length > 0) {
            publishers.pop();
        }
        for (uint256 i; i < _newPublishers.length; i++) {
            if (publisherCheck(_newPublishers[i])) continue;
            publishers.push(_newPublishers[i]);
        }
        emit PublisherChanged(address(this), publishers);
    }

    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    )
        public
        view
        onlyIssued(root)
        onlyNotRevoked(root)
        contractNotExpired
        returns (bool)
    {
        require(!isExpired(root));
        require(!isRevoked(leaf));
        return processProof(proof, leaf) == root;
    }

    function processProof(
        bytes32[] memory proof,
        bytes32 leaf
    ) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(
        bytes32 a,
        bytes32 b
    ) internal pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

    function testHashFunc(bytes32 a) external pure returns (bytes32) {
        return keccak256(abi.encode(a));
    }

    function issue(
        bytes32 document,
        uint256 _expiredTime
    ) public onlyPublisher onlyNotIssued(document) contractNotExpired {
        documentIssued[document] = block.number;
        documentExpiration[document] = _expiredTime;
        documentPublisher[document] = msg.sender;
        emit DocumentIssued(document);
    }

    function bulkIssue(
        bytes32[] memory documents,
        uint256[] memory _expiredTime
    ) external {
        for (uint256 i = 0; i < documents.length; i++) {
            issue(documents[i], _expiredTime[i]);
        }
    }

    function getIssuedBlock(
        bytes32 document
    ) external view onlyIssued(document) returns (uint256) {
        return documentIssued[document];
    }

    function isIssued(bytes32 document) public view returns (bool) {
        return (documentIssued[document] != 0);
    }

    function isIssuedBefore(
        bytes32 document,
        uint256 blockNumber
    ) public view returns (bool) {
        return (documentIssued[document] != 0 &&
            documentIssued[document] <= blockNumber);
    }

    function revoke(
        bytes32 document
    ) public onlyPublisher onlyNotRevoked(document) contractNotExpired {
        documentRevoked[document] = block.number;
        emit DocumentRevoked(document);
    }

    function bulkRevoke(bytes32[] memory documents) external {
        for (uint256 i = 0; i < documents.length; i++) {
            revoke(documents[i]);
        }
    }

    function isRevoked(bytes32 document) public view returns (bool) {
        return documentRevoked[document] != 0;
    }

    function isRevokedBefore(
        bytes32 document,
        uint256 blockNumber
    ) public view returns (bool) {
        return (documentRevoked[document] <= blockNumber &&
            documentRevoked[document] != 0);
    }

    function getExpirationDate(
        bytes32 document
    ) external view onlyIssued(document) returns (uint256) {
        return documentExpiration[document];
    }

    function isExpired(
        bytes32 document
    ) public view onlyIssued(document) returns (bool) {
        return documentExpiration[document] == 0 ? false : (documentExpiration[document] < block.timestamp);
    }

    function publisherCheck(address _address) public view returns (bool) {
        bool check = false;
        for (uint256 i; i < publishers.length; i++) {
            if (publishers[i] == _address) {
                check = true;
                break;
            }
        }
        return check;
    }

    modifier onlyExpired(bytes32 document) {
        require(isExpired(document), "Error: Document is not expired");
        _;
    }

    modifier onlyIssued(bytes32 document) {
        require(
            isIssued(document),
            "Error: Only issued document hashes can be revoked"
        );
        _;
    }

    modifier onlyNotIssued(bytes32 document) {
        require(
            !isIssued(document),
            "Error: Only hashes that have not been issued can be issued"
        );
        _;
    }

    modifier onlyNotRevoked(bytes32 claim) {
        require(!isRevoked(claim), "Error: Hash has been revoked previously");
        _;
    }

    modifier onlyPublisher() {
        require(
            publisherCheck(msg.sender) == true,
            "Error: Only Publisher can revoke/issue documents"
        );
        _;
    }

    modifier onlyVerified(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) {
        require(verify(proof, root, leaf), "Error: Leaf is not verified");
        _;
    }

    modifier contractNotExpired() {
        require(expiredTime > block.timestamp);
        _;
    }
}
