import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";

// Main Logic
function main() {
    try {
        // (1)
        const tree = StandardMerkleTree.load(JSON.parse(fs.readFileSync("tree.json", "utf8")));

        // (2)
        for (const [i, v] of tree.entries()) {
            if (v[0] === '0x1111111111111111111111111111111111111111') {
                // (3)
                const proof = tree.getProof(i);
                console.log('Value:', v);
                console.log('Proof:', proof);
            }
        }
    } catch (error) {
        console.error("An error occurred:", error.message);
    } finally {
        console.log("Execution finished.");
    }
}


// Main script execution
main();