const { ethers } = require("hardhat");
const ownerManagementABI = require("../artifacts/contracts/OwnerManagement.sol/OwnerManagement.json").abi;

const INS_NAME = "BKCLabs";
const INS_EMAIL = "bkclabs@gmail.com";
const INS_LEGAL_REFERENCE = "";
const INS_INTENT_DECLARATION = "";
const INS_HOST = "";
const INS_EXPIRED_TIME = "1749064098";

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log(`Deploying contracts with the account ${deployer.address}`);
    console.log(`Account balance: ${(await deployer.getBalance()).toString()}`);

    const [owner] = await ethers.getSigners();
    // const OwnerManagement = await ethers.getContractFactory("OwnerManagement");
    // const ownerManagement = await OwnerManagement.deploy();
    // await ownerManagement.deployed();
    // await ownerManagement.whitelist(owner.address);
    const ownerManagement = new ethers.Contract("0xea306cB611a271Ee3947Ec0363207E5e5D36fC10", ownerManagementABI, owner);
    const tx = await ownerManagement.deploy(
        INS_NAME,
        INS_EMAIL,
        INS_LEGAL_REFERENCE,
        INS_INTENT_DECLARATION,
        INS_HOST,
        INS_EXPIRED_TIME
    );
    const receipt = await tx.wait();
    const event = receipt.events.find((e) => e.event === "DocumentStoreDeployed");
    const institution_addr = event.args.instance;

    console.log(`Owner management address: ${ownerManagement.address}`);
    console.log(`institution address: ${institution_addr}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });