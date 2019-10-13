/*  The Computer Language Benchmarks Game
    https://salsa.debian.org/benchmarksgame-team/benchmarksgame/

    contributed by Joe Farro
    parts taken from solution contributed by
    Jos Hirth which was modified by 10iii
    modified by Roman Pletnev
    multi thread by Andrey Filatkin
*/

const { Worker, isMainThread, parentPort } = require('worker_threads');
const os = require('os');

const smap = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,84,86,71,72,0,
    0,67,68,0,0,77,0,75,78,0,0,0,89,83,65,65,66,87,0,82,
    0,0,0,0,0,0,0,84,86,71,72,0,0,67,68,0,0,77,0,75,78,0,
    0,0,89,83,65,65,66,87,0,82];

const lineLen = 60;
const fullLineLen = lineLen + 1;
const caret = '>'.charCodeAt(0);
const endLine = '\n'.charCodeAt(0);

if (isMainThread) {
    mainThread();
} else {
    workerThread();
}

async function mainThread() {
    const titleBuf = Buffer.allocUnsafe(lineLen);
    let titleBufPos = 0;
    let titleBufPartial = false;

    let dataArray = new SharedArrayBuffer(1 << 20);
    let dataBuf = Buffer.from(dataArray);
    let dataBufPos = 0;

    for await (let chunk of process.stdin) {
        await onChunk(chunk);
    }

    await onSection();

    async function onChunk(chunk) {
        const len = chunk.length;
        let i = 0;
        if (titleBufPartial) {
            const endI = chunk.indexOf(endLine, i);
            toTitleBuf(chunk, i, endI + 1);
            titleBufPartial = false;
            i += endI + 1;
        }
        const caretI = chunk.indexOf(caret, i);
        if (caretI === -1) {
            toBuf(chunk, i, len);
        } else {
            toBuf(chunk, i, caretI);
            i = caretI;
            await onSection();

            const endI = chunk.indexOf(endLine, i);
            if (endI !== -1) {
                toTitleBuf(chunk, i, endI + 1);
                return onChunk(chunk.subarray(endI + 1));
            } else {
                toTitleBuf(chunk, i, len);
                titleBufPartial = true;
            }
        }
    }

    function toTitleBuf(buffer, from, to) {
        buffer.copy(titleBuf, titleBufPos, from, to);
        titleBufPos += to - from;
    }

    function toBuf(buffer, from, to) {
        if (from === to) {
            return;
        }

        const len = to - from;
        if (dataBufPos + len > dataBuf.length) {
            const newArr = new SharedArrayBuffer(dataBuf.length * 2);
            const newBuf = Buffer.from(newArr);
            dataBuf.copy(newBuf, 0, 0, dataBufPos);
            dataArray = newArr;
            dataBuf = newBuf;
        }
        buffer.copy(dataBuf, dataBufPos, from, to);
        dataBufPos += len;
    }

    async function onSection() {
        if (titleBufPos === 0) {
            return;
        }

        const outputArray = new SharedArrayBuffer(dataBufPos);

        await processData(outputArray);

        process.stdout.write(titleBuf.subarray(0, titleBufPos));
        process.stdout.write(new Uint8Array(outputArray));
        titleBufPos = 0;
        dataBufPos = 0;
    }

    function processData(outputArray) {
        return new Promise(resolve => {
            const cpus = os.cpus().length;
            const remainder = dataBufPos % (cpus * fullLineLen);
            const chunk = (dataBufPos - remainder) / cpus;
            const isShift = dataBufPos % fullLineLen !== 0;
            let from = dataBufPos;
            let to = 0;

            let wait = 0;
            for (let i = 0; i < cpus; i++) {
                let inputSize = chunk;
                let outputSize = chunk;
                if (isShift) {
                    if (i === 0) {
                        inputSize += 1;
                    }
                    if (i === cpus - 1) {
                        inputSize -= 1;
                    }
                }
                if (i === cpus - 1) {
                    inputSize += remainder;
                    outputSize += remainder;
                }

                const worker = new Worker(__filename);
                worker.postMessage({data: {dataArray, outputArray, from, to, inputSize, outputSize}});
                worker.on('exit', () => {
                    wait--;
                    if (wait === 0) {
                        resolve();
                    }
                });
                wait++;

                from -= inputSize;
                to += outputSize;
            }
        });
    }
}

function workerThread() {
    parentPort.on('message', message => {
        writeBuf(message.data);
        process.exit();
    });

    function writeBuf({dataArray, outputArray, from, to, inputSize, outputSize}) {
        const input = new Uint8Array(dataArray, from - inputSize, inputSize);
        const output = new Uint8Array(outputArray, to, outputSize);

        let i = inputSize - 1;
        let o = 0;
        let n = 0;
        while (i >= 0) {
            let char = input[i--];
            if (char === endLine) {
                char = input[i--];
            }
            output[o++] = smap[char];
            n++;
            if (n === 60) {
                output[o++] = endLine;
                n = 0;
            }
        }
        output[outputSize - 1] = endLine;
    }
}
