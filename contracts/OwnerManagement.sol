//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import "./DocumentStore.sol";
import "./IDocumentStoreInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnerManagement is Ownable {
    address manager; // the owner of contract, owner of b4e
    address[] public institutions; // list of owner of organizations use b4e
    string[] public nameList; // name of organizations

    struct info {
        address contractAddress; // the address of DocumentStore
        string name;
        string email;
        string legalReference;
        string intentDeclaration;
        string host;
        uint256 expiredTime;
        bool contractIsExpired;
    }

    mapping(address => info) public instInfo;
    /// Check whether the institution is added or not
    mapping(address => bool) public addressWhitelisted;
    /// Check whether the address is whitelisted;
    mapping(address => bool) public addressWhitelistedBefore;
    /// Check whether the address has been whitelisted before;
    mapping(address => mapping(uint256 => bool)) public expiredTimeCheck;
    /// Check the registered expired time of the address;

    event DocumentStoreDeployed(
        address indexed instance,
        address indexed creator
    );
    event AddressWhitelisted(address indexed _address);

    function addInstitution() internal {
        address _institution = institutions[institutions.length - 1];
        instInfo[_institution].name = IDocumentStoreInterface(_institution)
            .getName();
        instInfo[_institution].email = IDocumentStoreInterface(_institution)
            .getEmail();
        instInfo[_institution].contractAddress = _institution;
        instInfo[_institution].legalReference = IDocumentStoreInterface(
            _institution
        ).getLegalReference();
        instInfo[_institution].intentDeclaration = IDocumentStoreInterface(
            _institution
        ).getIntentDeclaration();
        instInfo[_institution].host = IDocumentStoreInterface(_institution)
            .getHost();
        instInfo[_institution].expiredTime = IDocumentStoreInterface(
            _institution
        ).getExpiredTime();
        nameList.push(instInfo[_institution].name);
    }

    function whitelist(address _address) public onlyOwner {
        require(
            addressWhitelistedBefore[_address] == false,
            "Error: address has been whitelisted before"
        );
        addressWhitelisted[_address] = true;
        addressWhitelistedBefore[_address] = false;
        emit AddressWhitelisted(_address);
    }

    function deploy(
        string memory _name,
        string memory _email,
        string memory _legalReference,
        string memory _intentDeclaration,
        string memory _host,
        uint256 _time
    ) public onlyWhitelisted returns (address) {
        DocumentStore instance = new DocumentStore();
        instance.initialize(
            _name,
            _email,
            _legalReference,
            _intentDeclaration,
            _host,
            _time,
            msg.sender,
            address(this)
        );
        institutions.push(address(instance));
        addInstitution();
        addressWhitelisted[msg.sender] = false;
        emit DocumentStoreDeployed(address(instance), msg.sender);
        return address(instance);
    }

    function getAddressByName(
        string memory _name
    ) external view returns (address _address) {
        for (uint256 i; i < institutions.length; i++) {
            if (
                keccak256(abi.encodePacked(instInfo[institutions[i]].name)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                _address = institutions[i];
            }
        }
    }

    function getInstitutions() external view returns (string[] memory) {
        return nameList;
    }

    function setName(address _contract, string memory _name) external {
        require(msg.sender == _contract);
        instInfo[_contract].name = _name;
    }

    function setEmail(address _contract, string memory _email) external {
        require(msg.sender == _contract);
        instInfo[_contract].email = _email;
    }

    function setLegalReference(
        address _contract,
        string memory _legalReference
    ) external {
        require(msg.sender == _contract);
        instInfo[_contract].legalReference = _legalReference;
    }

    function setIntentDeclaration(
        address _contract,
        string memory _intentDeclaration
    ) external {
        require(msg.sender == _contract);
        instInfo[_contract].intentDeclaration = _intentDeclaration;
    }

    function setHost(address _contract, string memory _host) external {
        require(msg.sender == _contract);
        instInfo[_contract].host = _host;
    }

    function setExpiredTime(
        address _contract,
        uint256 _time
    ) external expiredTimeTrue(_contract, _time) {
        require(msg.sender == _contract, "Error: wrong caller");
        instInfo[_contract].expiredTime = _time;
    }

    function approveExpiredTime(
        address _contract,
        uint256 _time
    ) external onlyOwner {
        require(
            _time > instInfo[_contract].expiredTime,
            "Error: expired time has passed"
        );
        expiredTimeCheck[_contract][_time] = true;
    }

    modifier expiredTimeTrue(address _contract, uint256 _time) {
        require(
            expiredTimeCheck[_contract][_time] == true,
            "Error: new expired time is not registered"
        );
        _;
    }

    modifier onlyWhitelisted() {
        require(
            addressWhitelisted[msg.sender],
            "Error: address is not whitelisted"
        );
        _;
    }
}
