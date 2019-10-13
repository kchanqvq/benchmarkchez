"* The Computer Language Benchmarks Game
    http://shootout.alioth.debian.org/
    unoptimized program contributed long ago by Isaac Gouy *"!

Smalltalk.Core defineClass: #BenchmarksGame
	superclass: #{Core.Object}
	indexedType: #none
	private: false
	instanceVariableNames: ''
	classInstanceVariableNames: ''
	imports: ''
	category: ''!


!Core.BenchmarksGame class methodsFor: 'private'!

substringFrequencies: aString for: aLength using: aDictionary
   | m |
   m := aString size - aLength + 1.
   1 to: m do: [:i | | fragment |
      fragment := aString copyFrom: i to: i + aLength - 1.

      aDictionary at: fragment put: 
         (aDictionary at: fragment ifAbsent: [0]) + 1 
   ].
   ^aDictionary!


readFasta: sequenceName from: input
   | prefix newline buffer description line char |
   prefix := '>',sequenceName.
   newline := Character cr.

   "* find start of particular fasta sequence *"
   [(input atEnd) or: [
         (input peek = $>)
            ifTrue: [((line := input upTo: newline)
               indexOfSubCollection: prefix startingAt: 1) = 1]
            ifFalse: [input skipThrough: newline. false]]
      ] whileFalse.

   "* line-by-line read - it would be a lot faster to block read *"
   description := line.
   buffer := ReadWriteStream on: (String new: 1028).
   [(input atEnd) or: [(char := input peek) = $>]] whileFalse: [
      (char = $;)
         ifTrue: [input upTo: newline]
         ifFalse: [buffer nextPutAll: (input upTo: newline)]
      ].
   ^Association key: description value: buffer contents !


knucleotideFrom: input to: output
   | sequence writeFrequencies writeCount |

   sequence := (self readFasta: 'THREE' from: input) value asUppercase.

   writeFrequencies :=
      [:k | | frequencies count |
      frequencies := SortedCollection sortBlock: [:a :b|
         (a value = b value) ifTrue: [b key < a key] ifFalse: [b value < a value]].

      count := 0.0.
      (self substringFrequencies: sequence for: k using: Dictionary new)
         associationsDo: [:each|
            frequencies add: each. count := count + each value].

      frequencies do: [:each | | percentage |
         percentage := (each value / count) * 100.0.
         output 
            nextPutAll: each key; nextPutAll: ' ';
            print: percentage digits: 3; nl]]. 

   writeCount := [:nucleotideFragment | | frequencies count |
      frequencies := self substringFrequencies: sequence 
         for: nucleotideFragment size
         using: Dictionary new.
      count := frequencies at: nucleotideFragment ifAbsent: [0].
      output print: count; tab; nextPutAll: nucleotideFragment; nl].

   writeFrequencies value: 1. output nl.
   writeFrequencies value: 2. output nl.

   writeCount value: 'GGT'.
   writeCount value: 'GGTA'.
   writeCount value: 'GGTATT'.
   writeCount value: 'GGTATTTTAATT'.
   writeCount value: 'GGTATTTTAATTTATAGT'! !


!Core.BenchmarksGame class methodsFor: 'initialize-release'!

do: n
   self knucleotideFrom: Stdin to: Stdout.
   ^''! !


!Core.Stream methodsFor: 'benchmarks game'!

tab
   self nextPut: Character tab!

nl
   self nextPut: Character lf!

print: number digits: decimalPlaces
   self nextPutAll: 
      ((number asFixedPoint: decimalPlaces) printString copyWithout: $s)! !


