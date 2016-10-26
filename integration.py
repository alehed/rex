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

# Basic functionality tests

test("test-basic-string.rkt", ["banana", "", "a", "bananas"], "#t #f #f #f")

test("test-wildcards.rkt", ["bana na", "banafana", "banannaaaaa", "bbbanafna", "bbanafna", "1234banagna5678"], "#t #f #t #t #f #t")

test("test-explicit-only.rkt", ["asdf", "", "142"], "#t #t #f")

test("test-explicit-naming.rkt", ["ananananas", "anananaas"], "#t #f")

test("test-ranges.rkt", ["password9", "passworg1", "passwort!", "passwortN"], "#t #f #f #t")

test("test-special-characters.rkt", ["Hello World!", "HelloWorld!"], "#t #f")


# Advanced functionality tests

test("test-parser-1.rkt", ["10001111", "0001", "10", "1111"], "#t #t #f #t")

test("test-parser-2.rkt", ["-n"], "((0 (((a a) 1)) -1 #f) (1 (((b b) 2)) -1 #f) (2 (((c c) 3)) -1 #f) (3 (((f f) 1) ((d d) 1) ((e e) 1) ((g g) 4)) -1 #f) (4 () -1 #t))")



if failures == 0:
    print("All Tests Passed (" + str(passes) + ").")
else:
    print("Some Tests Failed. Failures: " + str(failures) + ", Passes: " + str(passes) + ".")
