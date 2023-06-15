const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { MerkleTree } = require("merkletreejs");
const documentStoreABI = require("../artifacts/contracts/DocumentStore.sol/DocumentStore.json").abi;

const INS_NAME = "BKCLabs";
const INS_EMAIL = "bkclabs@gmail.com";
const INS_LEGAL_REFERENCE = "";
const INS_INTENT_DECLARATION = "";
const INS_HOST = "";
const INS_EXPIRED_TIME = "1749064098";

const DOCUMENT_01 = "0x91a32d675b238f38dbb0d0ff41a9862ef9a77d74f1584e7929bc285a6c68049d";
const DOCUMENT_02 = "0x74168a2bdcceebd01b84aeff1d9b1e29a1b5980e4e1a5c057ae9f123d6bc2a30";
const DOCUMENT_03 = "0x4e076a71f8826023c76fe48f2d9709fe0bc7a018f4f0195c64f74b9f058da787";
const DOCUMENT_04 = "0x264c5c6832b6b9a81359da49975ce4e88ef2a45f7fd23f4d7b2f2f4fe6e5978d";
const DOCUMENT_05 = "0x2f0e2bc1bc05727fc4b36e38d54ee23f6b2f5023d13eebf72d19d93f4dc3b594";
const DOCUMENT_06 = "0x1b5822a9a6d774e64f9eb03a6a44d3bbf46ff93d301ff305a89998a6b44cc2a2";
const DOCUMENT_07 = "0x8cf87b43efad6af512a4d918b794926ff05d0c6f937bb03ebfde0b3a56b7d3e1";
const DOCUMENT_08 = "0x648ae67e132c8937fcf59d28369c9f96024c28be82023e13769d0c243a497199";
const DOCUMENT_09 = "0xe63fcd2d0e3fe5d3d18dbd2d240ad7f9a0d3d55b9748e58856de789c1c6c1d14";
const DOCUMENT_10 = "0xb24d80944f3f83b9b9d6e0d5bcde99ee6c71e08edc38a4de7275049dc7f62b68";
const DOCUMENTS_TEST = [
    DOCUMENT_01, 
    DOCUMENT_02, 
    DOCUMENT_03, 
    DOCUMENT_04, 
    DOCUMENT_05, 
    // DOCUMENT_06,
    // DOCUMENT_07,
    // DOCUMENT_08,
    // DOCUMENT_09,
    // DOCUMENT_10
];

const INVALID_DOCUMENT = "0x8b597ac4e7e65b7262c0c9b7333fb6a4c9d3018f46a2537d9b8556a547baf868";

describe("Basic flow", function () {
    function generateMerkleTree(documentList) {
        const leaves = documentList.map(v => ethers.utils.keccak256(v));
        const tree = new MerkleTree(leaves, ethers.utils.keccak256, { sort: true });
        return tree;
    }

    async function deployment() {
        const OwnerManagement = await ethers.getContractFactory("OwnerManagement");
        const [owner] = await ethers.getSigners();
        const ownerManagement = await OwnerManagement.deploy();
        await ownerManagement.whitelist(owner.address);
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
        const institution = new ethers.Contract(institution_addr, documentStoreABI, owner);

        const documentList = [DOCUMENT_01, DOCUMENT_02, DOCUMENT_03, DOCUMENT_04, DOCUMENT_05, DOCUMENT_06, DOCUMENT_07, DOCUMENT_08];
        const tree = generateMerkleTree(documentList);
        
        const treeTest = generateMerkleTree(DOCUMENTS_TEST);
        console.log(treeTest.getHexRoot());
        console.log(treeTest.getHexLeaves());
        console.log(treeTest.getHexProof(ethers.utils.keccak256(DOCUMENT_01)));
        
        await institution.issue(tree.getHexRoot(), 0);
        return { ownerManagement, institution, tree, owner };
    }

    it("Should verified the leaf in the merkle tree", async function () {
        const { ownerManagement, institution, tree, owner } = await loadFixture(deployment);
        const root = tree.getHexRoot();
        const leaf = ethers.utils.keccak256(DOCUMENT_07);
        const proof = tree.getHexProof(leaf);
        const invalidLeaf = ethers.utils.keccak256(INVALID_DOCUMENT);
        expect(await institution.verify(proof, root, leaf)).to.equal(true);
        expect(await institution.verify(proof, root, invalidLeaf)).to.equal(false);
    });

    it("Should not verify the revoked leaf", async function () {
        const { ownerManagement, institution, tree, owner } = await loadFixture(deployment);
        const leaf = ethers.utils.keccak256(DOCUMENT_07);
        await institution.revoke(leaf);
        await expect(institution.verify(tree.getHexProof(leaf), tree.getHexRoot(), leaf)).to.be.reverted;
    });
});
