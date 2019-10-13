# The Computer Language Benchmarks Game
# https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
#
# Contributed by Lutfullah Tomak
# based on C gcc implementation

const IM = 139968
const IA = 3877
const IC = 29573

const last_genrandom = Ref(42)
function gen_random(max::AbstractFloat) 
    last = (last_genrandom[] * IA + IC) % IM
    last_genrandom[] = last
    return max * last / IM
end

mutable struct Aminoacids
    c::UInt8
    p::Float64
end

# Weighted selection from alphabet 

function makeCumulative(genelist::Vector{Aminoacids},
                        count::Integer) 
    cp = 0.0
    for i = 1:count
        cp += genelist[i].p
        genelist[i].p = cp
    end
end

function selectRandom(genelist::Vector{Aminoacids},
                      count::Integer)
    r = gen_random(1.0)

    if (r < genelist[1].p) 
        return genelist[1].c
    end

    lo = 1
    hi = count

    while (hi > lo+1)
        i = (hi + lo) >> 1
        if (r < genelist[i].p)
            hi = i
        else
            lo = i
        end
    end
    return genelist[hi].c
end

# Generate and write FASTA format

const LINE_LENGTH = 60

function makeRandomFasta(id::String, desc::String,
                         genelist::Vector{Aminoacids},
                         count::Integer, n::Integer)

    write(stdout,'>', id, ' ', desc,'\n')
    pick = Vector{UInt8}(undef,LINE_LENGTH+1)
    for todo = n:(-LINE_LENGTH):1
        if (todo < LINE_LENGTH)
            m = todo
        else 
            m = LINE_LENGTH
        end
        for i = 1:m
            pick[i] = selectRandom(genelist, count)
        end
        pick[m+1] = '\n'
        write(stdout, @view pick[1:(m+1)])
    end
    return nothing
end

function makeRepeatFasta(id::String, desc::String,
                          s::Vector{UInt8}, n::Integer)
    k = 0
    kn = length(s)
    ss = copy(s)
    write(stdout,'>', id, ' ', desc,'\n')

    for todo = n:(-LINE_LENGTH):1
        if (todo < LINE_LENGTH)
            m = todo
        else
            m = LINE_LENGTH
        end
        while (m >= kn - k)
            write(stdout, @view s[(k+1):kn])
            m -= kn - k
            k = 0
        end
        ss[k + m + 1] = '\n'
        write(stdout, @view ss[(k+1):(k+m+1)])
        ss[k + m + 1] = s[m + k + 1]
        k += m
    end
    return nothing
end

#* Main -- define alphabets, make 3 fragments

const iub = [
    Aminoacids( 'a', 0.27 ),
    Aminoacids( 'c', 0.12 ),
    Aminoacids( 'g', 0.12 ),
    Aminoacids( 't', 0.27 ),
    
    Aminoacids( 'B', 0.02 ),
    Aminoacids( 'D', 0.02 ),
    Aminoacids( 'H', 0.02 ),
    Aminoacids( 'K', 0.02 ),
    Aminoacids( 'M', 0.02 ),
    Aminoacids( 'N', 0.02 ),
    Aminoacids( 'R', 0.02 ),
    Aminoacids( 'S', 0.02 ),
    Aminoacids( 'V', 0.02 ),
    Aminoacids( 'W', 0.02 ),
    Aminoacids( 'Y', 0.02 )
]

const IUB_LEN  = length(iub)

const homosapiens = [
    Aminoacids( 'a', 0.3029549426680 ),
    Aminoacids( 'c', 0.1979883004921 ),
    Aminoacids( 'g', 0.1975473066391 ),
    Aminoacids( 't', 0.3015094502008 ),
]

const HOMOSAPIENS_LEN = length(homosapiens)

const alustring =
   "GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG"*
   "GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA"*
   "CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT"*
   "ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA"*
   "GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG"*
   "AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC"*
   "AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA"
   
const alu = unsafe_wrap(Vector{UInt8},pointer(alustring),
                        length(alustring),own=true)

function main(n)

    makeCumulative(iub, IUB_LEN)
    makeCumulative(homosapiens, HOMOSAPIENS_LEN)
    makeRepeatFasta("ONE", "Homo sapiens alu", alu, n*2)
    makeRandomFasta("TWO", "IUB ambiguity codes", iub, IUB_LEN, n*3)
    makeRandomFasta("THREE", "Homo sapiens frequency", homosapiens,
                    HOMOSAPIENS_LEN, n*5)

    return nothing
end

n = parse(Int, ARGS[1])
main(n)
