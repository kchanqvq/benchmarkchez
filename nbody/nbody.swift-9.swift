/// The Computer Language Benchmarks Game
/// https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
///
/// contributed by Mark C. Lewis
/// modified slightly by Chad Whipkey
/// converted from java to c++,added sse support, by Branimir Maksimovic
/// converted from c++ to c, by Alexey Medvedchikov
/// converted from c to Rust by Frank Rehberger
/// converted from Rust to Swift by T Roughton
///
/// As the code of `gcc #4` this code requires hardware supporting
/// the CPU feature SSE2, implementing SIMD operations.
///
///

import Foundation

fileprivate extension Double {
    static let solarMass = 4.0 * .pi * .pi
    static let daysPerYear = 365.24
}

struct Body {
    var x : SIMD3<Double>
    var velocityAndMass : SIMD4<Double>
    
    var v : SIMD3<Double> {
        get {
            return SIMD3(self.velocityAndMass.x, self.velocityAndMass.y, self.velocityAndMass.z)
        }
        set {
            self.velocityAndMass.x = newValue.x
            self.velocityAndMass.y = newValue.y
            self.velocityAndMass.z = newValue.z
        }
    }
    
    var mass : Double {
        get {
            return self.velocityAndMass.w
        }
        set {
            self.velocityAndMass.w = newValue
        }
    }
    
    init(x: SIMD3<Double>, v velocity: SIMD3<Double>, mass: Double) {
        self.x = x
        self.velocityAndMass = SIMD4(velocity.x, velocity.y, velocity.z, mass)
    }
}

struct Delta {
    var dx : SIMD3<Double> = SIMD3(repeating: 0)
}
/// Calculating the offset momentum
func offsetMomentum(bodies: inout [Body]) {
    for i in bodies.indices {
        bodies[0].v -= bodies[i].v * bodies[i].mass / .solarMass;
    }
}

/// Calculating the energy of the N body system
func bodiesEnergy(bodies: [Body]) -> Double {
    var dx = SIMD3(repeating: 0.0)
    var e = 0.0;
    
    for i in bodies.indices {
        e += bodies[i].mass
            * ((bodies[i].v[0] * bodies[i].v[0])
                + (bodies[i].v[1] * bodies[i].v[1])
                + (bodies[i].v[2] * bodies[i].v[2]))
            / 2.0;
        
        for j in (i + 1)..<bodies.count {
            dx = bodies[i].x - bodies[j].x;
            let distance = ((dx[0] * dx[0]) + (dx[1] * dx[1]) + (dx[2] * dx[2])).squareRoot()
            e -= (bodies[i].mass * bodies[j].mass) / distance;
        }
    }
    
    return e
}

struct BodiesAdvance {
    var r = [Delta](repeating: Delta(), count: 1000)
    var mag = [Double](repeating: 0.0, count: 1000)
    
    /// Calculating advance of bodies within time dt, using the buffers `r` and `mag`
    mutating func bodiesAdvance(bodies: inout [Body], dt: Double) {
        let N = ((bodies.count - 1) * bodies.count) / 2
        
        // Use a tuple since an array isn't currently stack-allocated
        var dx = (SIMD2(repeating: 0.0), SIMD2(repeating: 0.0), SIMD2(repeating: 0.0))
        
        var k = 0;
        for i in 0..<(bodies.count - 1) {
            for j in (i + 1)..<bodies.count {
                self.r[k].dx = bodies[i].x - bodies[j].x;
                k += 1;
            }
        }
        
        // enumerate in +2 steps
        for i_2 in 0..<(N / 2) {
            let i = i_2 * 2;
            
            do {
                dx.0.x = self.r[i].dx[0]
                dx.0.y = self.r[i + 1].dx[0]
                
                dx.1.x = self.r[i].dx[1]
                dx.1.y = self.r[i + 1].dx[1]
                
                dx.2.x = self.r[i].dx[2]
                dx.2.y = self.r[i + 1].dx[2]
            }
            
            let dSquared = dx.0 * dx.0 + dx.1 * dx.1 + dx.2 * dx.2
            var distance = SIMD2(repeating: 1.0) / dSquared.squareRoot() // _mm_cvtps_pd(_mm_rsqrt_ps(_mm_cvtpd_ps(dSquared)))
            
            // repeat 2 times
            for _ in 0..<2 {
                distance = distance * SIMD2(repeating: 1.5)
                    - ((SIMD2(repeating: 0.5) * dSquared) * distance)
                    * (distance * distance)
            }
            
            let dMag = SIMD2(repeating: dt) / (dSquared) * distance
            
            self.mag[i] = dMag.x
            self.mag[i + 1] = dMag.y
        }
        
        k = 0
        for i in 0..<(bodies.count - 1) {
            for j in (i + 1)..<bodies.count {
                bodies[i].v -= (self.r[k].dx * bodies[j].mass) * self.mag[k];
                    
                bodies[j].v += (self.r[k].dx * bodies[i].mass) * self.mag[k];
                k += 1;
            }
        }
        
        for i in bodies.indices {
            bodies[i].x += dt * bodies[i].v;
        }
    }
    
}

func main() {
    let nCycles = CommandLine.arguments.dropFirst()
                    .first.flatMap { Int($0) } ?? 1000
    
    var bodies : [Body] = [
        // Sun
        Body(
            x: [0.0, 0.0, 0.0],
            v: [0.0, 0.0, 0.0],
            mass: .solarMass
        ),
        // Jupiter
        Body(
            x: [
                4.84143144246472090e+00,
                -1.16032004402742839e+00,
                -1.03622044471123109e-01,
            ],
            v: [
                1.66007664274403694e-03 * .daysPerYear,
                7.69901118419740425e-03 * .daysPerYear,
                -6.90460016972063023e-05 * .daysPerYear,
            ],
            mass: 9.54791938424326609e-04 * .solarMass
        ),
        // Saturn
        Body(
            x: [
                8.34336671824457987e+00,
                4.12479856412430479e+00,
                -4.03523417114321381e-01,
            ],
            v: [
                -2.76742510726862411e-03 * .daysPerYear,
                4.99852801234917238e-03 * .daysPerYear,
                2.30417297573763929e-05 * .daysPerYear,
            ],
            mass: 2.85885980666130812e-04 * .solarMass
        ),
        // Uranus
        Body(
            x: [
                1.28943695621391310e+01,
                -1.51111514016986312e+01,
                -2.23307578892655734e-01,
            ],
            v: [
                2.96460137564761618e-03 * .daysPerYear,
                2.37847173959480950e-03 * .daysPerYear,
                -2.96589568540237556e-05 * .daysPerYear,
            ],
            mass: 4.36624404335156298e-05 * .solarMass
        ),
        // Neptune
        Body(
            x: [
                1.53796971148509165e+01,
                -2.59193146099879641e+01,
                1.79258772950371181e-01,
            ],
            v: [
                2.68067772490389322e-03 * .daysPerYear,
                1.62824170038242295e-03 * .daysPerYear,
                -9.51592254519715870e-05 * .daysPerYear,
            ],
            mass: 5.15138902046611451e-05 * .solarMass
        ),
    ];
    var sim = BodiesAdvance();
    
    offsetMomentum(bodies: &bodies);
    
    print(String(format: "%.9f", bodiesEnergy(bodies: bodies)));
    
    for _ in 0..<nCycles {
        sim.bodiesAdvance(bodies: &bodies, dt: 0.01);
    }
    
    print(String(format: "%.9f", bodiesEnergy(bodies: bodies)))
}

main()
