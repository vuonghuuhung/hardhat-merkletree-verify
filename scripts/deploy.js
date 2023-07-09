const { ethers } = require("hardhat");
const ownerManagementABI = require("../artifacts/contracts/OwnerManagement.sol/OwnerManagement.json").abi;
const documentStoreABI = require("../artifacts/contracts/DocumentStore.sol/DocumentStore.json").abi;

const INS_NAME = "BKCLabs";
const INS_EMAIL = "bkclabs@gmail.com";
const INS_LEGAL_REFERENCE = "";
const INS_INTENT_DECLARATION = "";
const INS_HOST = "";
const INS_EXPIRED_TIME = "4118783378";

async function issueNewRoot() {
    const [deployer] = await ethers.getSigners();
    const documentStore = new ethers.Contract("0x763ba6132DdC91316DE9Ad7a085aeD2308B10206", documentStoreABI, deployer);
    const tx = await documentStore.issue("0x6d646029fc85714576c27638be09e9f164709c5e3c6f1959019af9f388964387", 0);
    const receipt = await tx.wait();
    console.log(receipt);
}

async function verifyLeaf() {
    const [deployer] = await ethers.getSigners();
    const documentStore = new ethers.Contract("0x763ba6132DdC91316DE9Ad7a085aeD2308B10206", documentStoreABI, deployer);
    const root1 = "0x6d646029fc85714576c27638be09e9f164709c5e3c6f1959019af9f388964387";
    const leaf1 = "0x2c26aa61b3fa99c6b2efe8e010f559117b466061c0c459430b9e782a8fab664f";
    const proof1 = [
        "0x32f327e74615cf7e9295ec689cac8d66ab2e34c366bc757dd42b2d0595ed190f",
        "0x332a24f14286247849bcbcdbcfe278df21e630b9148a743041893ab9bdf996de",
        "0x7c770989cb2e02e5849311eb6e65647b5e87ba9457fb3f0eb91c37a19f4e45aa"
    ];
    const tx = await documentStore.verify(proof1, root1, leaf1);
    console.log(tx);
}

async function main() {
    // const [deployer] = await ethers.getSigners();

    // console.log(`Deploying contracts with the account ${deployer.address}`);
    // console.log(`Account balance: ${(await deployer.getBalance()).toString()}`);

    // const [owner] = await ethers.getSigners();
    // // const OwnerManagement = await ethers.getContractFactory("OwnerManagement");
    // // const ownerManagement = await OwnerManagement.deploy();
    // // await ownerManagement.deployed();
    // // await ownerManagement.whitelist(owner.address);
    // const ownerManagement = new ethers.Contract("0x32A5814Ef6a4C8185fff070700a1601cC640A73A", ownerManagementABI, owner);
    // const tx = await ownerManagement.deploy(
    //     INS_NAME,
    //     INS_EMAIL,
    //     INS_LEGAL_REFERENCE,
    //     INS_INTENT_DECLARATION,
    //     INS_HOST,
    //     INS_EXPIRED_TIME
    // );
    // const receipt = await tx.wait();
    // const event = receipt.events.find((e) => e.event === "DocumentStoreDeployed");
    // const institution_addr = event.args.instance;

    // console.log(`Owner management address: ${ownerManagement.address}`);
    // console.log(`institution address: ${institution_addr}`);
    // await issueNewRoot();
    await verifyLeaf();
}
/*
bsc-testnet: 
    OwnerManagement: 0xE1aad01694d1d4AAe375E7c6A3c115F7760d09a4
    Instance of Institution: 

sepolia: 
    OwnerManagement: 0x32A5814Ef6a4C8185fff070700a1601cC640A73A
    Instance of Institution: 0x763ba6132DdC91316DE9Ad7a085aeD2308B10206
*/

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });