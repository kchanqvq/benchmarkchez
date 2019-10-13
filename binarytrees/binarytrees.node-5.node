/* The Computer Language Benchmarks Game
   https://salsa.debian.org/benchmarksgame-team/benchmarksgame/

   contributed by Léo Sarrazin
   multi thread by Andrey Filatkin
*/

const { Worker, isMainThread, parentPort } = require('worker_threads');
const os = require('os');

if (isMainThread) {
    mainThread();
} else {
    workerThread();
}

async function mainThread() {
    const maxDepth = Math.max(6, parseInt(process.argv[2]));

    const stretchDepth = maxDepth + 1;
    const check = itemCheck(bottomUpTree(stretchDepth));
    console.log(`stretch tree of depth ${stretchDepth}\t check: ${check}`);

    const longLivedTree = bottomUpTree(maxDepth);

    const tasks = [];
    let index = 0;
    for (let depth = 4; depth <= maxDepth; depth += 2) {
        const iterations = 1 << maxDepth - depth + 4;
        tasks.push({index, iterations, depth});
        index++;
    }

    const results = [];
    await threadReduce(tasks, null, ({index, result}) => {
        results[index] = result;
    });
    for (let i = 0; i < results.length; i++) {
        console.log(results[i]);
    }

    console.log(`long lived tree of depth ${maxDepth}\t check: ${itemCheck(longLivedTree)}`);
}

function workerThread() {
    parentPort.on('message', message => {
        const name = message.name;

        if (name === 'work') {
            const data = message.data;
            parentPort.postMessage({
                name: 'result',
                data: {
                    index: data.index,
                    result: work(data.iterations, data.depth)
                },
            });
        } else if (name === 'exit') {
            process.exit();
        }
    });
    parentPort.postMessage({name: 'ready'});
}

function threadReduce(tasks, workerData, reducer) {
    return new Promise(resolve => {
        const size = os.cpus().length;
        const workers = new Set();
        let ind = 0;

        for (let i = 0; i < size; i++) {
            const worker = new Worker(__filename, {workerData});

            worker.on('message', message => {
                const name = message.name;

                if (name === 'result') {
                    reducer(message.data);
                }
                if (name === 'ready' || name === 'result') {
                    if (ind < tasks.length) {
                        const data = tasks[ind];
                        ind++;
                        worker.postMessage({name: 'work', data});
                    } else {
                        worker.postMessage({name: 'exit'});
                    }
                }
            });
            worker.on('exit', () => {
                workers.delete(worker);
                if (workers.size === 0) {
                    resolve();
                }
            });

            workers.add(worker);
        }
    });
}

function work(iterations, depth) {
    let check = 0;
    for (let i = 1; i <= iterations; i++) {
        check += itemCheck(bottomUpTree(depth));
    }
    return `${iterations}\t trees of depth ${depth}\t check: ${check}`;
}

function TreeNode(left, right) {
    return {left, right};
}

function itemCheck(node) {
    if (node.left === null) {
        return 1;
    }
    return 1 + itemCheck(node.left) + itemCheck(node.right);
}

function bottomUpTree(depth) {
    return depth > 0
        ? new TreeNode(bottomUpTree(depth - 1),  bottomUpTree(depth - 1))
        : new TreeNode(null, null);
}
