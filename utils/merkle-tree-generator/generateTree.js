import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";

// Main Logic
function main() {
    try {
        // (1)
        const values = [
            ["0x1111111111111111111111111111111111111111"],
            ["0x2222222222222222222222222222222222222222"]
        ];

        // (2)
        const tree = StandardMerkleTree.of(values, ["address"]);

        // (3)
        console.log('Merkle Root:', tree.root);

        // (4)
        fs.writeFileSync("tree.json", JSON.stringify(tree.dump()));
    } catch (error) {
        console.error("An error occurred:", error.message);
    } finally {
        console.log("Execution finished.");
    }
}


// Main script execution
main();