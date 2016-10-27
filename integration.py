#!/usr/local/bin/python

import sys
import subprocess
import string

failures = 0
passes   = 0

verbose = False
if len(sys.argv) > 1:
    verbose = True

def test(expression_file, the_input, expected_output):
    global failures, passes
    call = ["racket", expression_file]
    call.extend(the_input)
    output = string.rstrip(subprocess.check_output(call))
    if output != expected_output:
        failures += 1
        print("[Failed] in: " + string.join(call))
        print("\tExpected: " + expected_output + "\n\tBut got: " + output)
    else:
        passes += 1
        if verbose:
            print("[Passed] in: " + string.join(call) +  "\n")

# Tokenizer tests

test("test-tokenizer-1.rkt", ["-t"], "(rex (implicit-expression (limited-expression (transition (character h))) (limited-expression (transition (character e))) (limited-expression (transition (character l))) (limited-expression (transition (character l))) (limited-expression (transition (character o))) (limited-expression (transition (character h))) (limited-expression (transition (character i)))) : (explicit-expression (node-line (node-identifier 1) (transition (character 2)) - > (node-identifier a l p h a) (transition (character 4)) - > (node-identifier a l p h a)) , (node-line (node-identifier b e t a) (transition (character 3)) - > (node-identifier b e t a))))")

test("test-new-all.rkt", ["-t"], "(rex (implicit-expression (limited-expression (transition (character a))) (limited-expression (loop { (limited-expression (sub-expression ( (limited-expression (transition (character b))) (or |) (limited-expression (transition (character c))) ))) })) (limited-expression (transition (character d)))))")

# Basic functionality tests

test("test-basic-string.rkt", ["banana", "", "a", "bananas"], "#t #f #f #f")

test("test-wildcards.rkt", ["bana na", "banafana", "banannaaaaa", "bbbanafna", "bbanafna", "1234banagna5678"], "#t #f #t #t #f #t")

test("test-explicit-only.rkt", ["asdf", "", "142"], "#t #t #f")

test("test-explicit-naming.rkt", ["ananananas", "anananaas"], "#t #f")

test("test-ranges.rkt", ["password9", "passworg1", "passwort!", "passwortN"], "#t #f #f #t")

test("test-special-characters.rkt", ["Hello World!", "HelloWorld!"], "#t #f")

test("test-basic-branch.rkt", ["abd", "acd", "aed", "aad"], "#t #t #f #f")

# Advanced functionality tests

test("test-parser-1.rkt", ["10001111", "0001", "10", "1111"], "#t #t #f #t")

test("test-parser-2.rkt", ["-n"], "((0 (((a a) 1)) -1 #f) (1 (((b b) 2)) -1 #f) (2 (((c c) 3)) -1 #f) (3 (((f f) 1) ((d d) 1) ((e e) 1) ((g g) 4)) -1 #f) (4 () -1 #t))")

test("test-nested-parens.rkt", ["-n"], "((0 (((b b) 1)) -1 #f) (1 () -1 #t))")

test("test-multi-branch.rkt", ["-n"], "((0 (((b b) 4) ((a a) 1)) -1 #f) (1 (((b b) 2)) -1 #f) (2 (((c c) 3)) -1 #f) (3 () -1 #t) (4 (((c c) 5)) -1 #f) (5 (((d d) 6)) -1 #f) (6 (((g g) 9) ((e e) 7)) -1 #f) (7 (((f f) 8)) -1 #f) (8 () -1 #t) (9 (((h h) 10)) -1 #f) (10 () -1 #t))")

test("test-new-all.rkt", ["abcbcccbbbbd", "acbccbcccbbd", "abcbbccbb", "ad"], "#t #t #f #f")

test("test-cycles-multi.rkt", ["cabababbcdccd", "dad", "cacc", "cca", "acc"], "#t #t #t #f #f")

# Tests for Branches

test("test-three-branch.rkt", ["a", "b", "c", "", "d", "ab"], "#t #t #t #f #f #f")

test("test-epsilon.rkt", ["a", "ab", "ag", "aa", "ba"], "#t #t #t #f #f")

test("test-branch-sequence.rkt", ["ac", "ad", "bc", "bd", "cd", "da"], "#t #t #t #t #f #f")

# Tests for Loops

test("test-cycles-1.rkt", ["-n"], "((0 (((a a) 1)) -1 #f) (1 (((a a) 1)) -1 #t))")

test("test-cycles-2.rkt", ["abbc", "abbbbbbc", "abc", "abbbc", "ac"], "#t #t #f #f #f")

test("test-cycles-3.rkt", ["abcbc", "abc", "acc"], "#t #t #f")

test("test-cycles-4.rkt", ["a", "b", "", "aaaaaaa", "bb", "aaabbaaba"], "#t #t #f #t #t #f")


if failures == 0:
    print("All Tests Passed (" + str(passes) + ").")
else:
    print("Some Tests Failed. Failures: " + str(failures) + ", Passes: " + str(passes) + ".")
