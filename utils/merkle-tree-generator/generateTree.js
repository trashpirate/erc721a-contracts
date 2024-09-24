import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";
import csv from "csv-parser";

function readCSV(filename) {
    
    const results = [];
    return new Promise((resolve, reject) => {
        fs.createReadStream(filename)
        .pipe(csv())
        .on('data', (row) => {
            // Extract only the values from the row (object)
            results.push(Object.values(row));
        })
        .on('end', () => {
            resolve(results); // Array with only values, no labels
        })
        .on('error', (error) => {
                reject(error); // Reject if an error occurs
            });
     })
}

// Main Logic
async function main() {

    var args = process.argv.slice(2);
    var filename = args[0];

    try {

        // read values from csv file
        const values = await readCSV('data/'+filename);
        console.log(values)

        // generate merkle tree
        const tree = StandardMerkleTree.of(values, ["address"]);

        // show root
        console.log('Merkle Root:', tree.root);

        // write tree to file
        fs.writeFileSync("tree.json", JSON.stringify(tree.dump()));

    } catch (error) {
        console.error("An error occurred:", error.message);
    } finally {
        console.log("Execution finished.");
    }
}


// Main script execution
main();