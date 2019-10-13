// The Computer Language Benchmarks Game
// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
//
// Based on C# version by Isaac Gouy, The Anh Tran, Alan McGovern
// Contributed by Don Syme
// Small optimisations by Anthony Lloyd
// Modified to use Array.Parallel and struct tuples by Phillip Carter

#nowarn "9"

open Microsoft.FSharp.NativeInterop

let approximate n1 u tmp v rbegin rend (barrier:System.Threading.Barrier) =
    let inline multiplyAv v Av A =
        for i = rbegin to rend do
            let mutable sum = A i 0 * NativePtr.read v
            for j = 1 to n1 do
                sum <- sum + A i j * NativePtr.get<float> v j
            NativePtr.set Av i sum

    let inline multiplyatAv v tmp atAv =
        let inline A i j = 1.0 / float((i + j) * (i + j + 1) / 2 + i + 1)
        multiplyAv v tmp A
        barrier.SignalAndWait()
        let inline At i j = A j i
        multiplyAv tmp atAv At
        barrier.SignalAndWait()

    for __ = 0 to 9 do
        multiplyatAv u tmp v
        multiplyatAv v tmp u

    let vbegin = NativePtr.get v rbegin
    let mutable vv = vbegin * vbegin
    let mutable vBv = vbegin * NativePtr.get u rbegin
    for i = rbegin+1 to rend do
        let vi = NativePtr.get v i
        vv <- vv + vi * vi
        vBv <- vBv + vi * NativePtr.get u i
    struct(vBv, vv)

[<EntryPoint>]
let main args =
    let n = try int args.[0] with _ -> 2500
    let u = fixed &(Array.create n 1.0).[0]
    let tmp = NativePtr.stackalloc n
    let v = NativePtr.stackalloc n
    let nthread = System.Environment.ProcessorCount
    let barrier = new System.Threading.Barrier(nthread)
    let chunk = n / nthread
    let aps =
        Array.Parallel.init nthread (fun i ->
            let r1 = i * chunk
            let r2 = if (i < (nthread - 1)) then r1 + chunk - 1 else n-1
            approximate (n-1) u tmp v r1 r2 barrier)
    let one = aps |> Array.sumBy (fun struct(x, _) -> x)
    let two = aps |> Array.sumBy (fun struct(_, y) -> y)
    sqrt(one / two).ToString("F9")
    |> stdout.WriteLine
    exit 0