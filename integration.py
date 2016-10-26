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

test("test-tokenizer-1.rkt", ["-t"], "(rex (implicit-expression (limited-expression (transition (character h))) (limited-expression (transition (character e))) (limited-expression (transition (character l))) (limited-expression (transition (character l))) (limited-expression (transition (character o))) (limited-expression (transition (character h))) (limited-expression (transition (character i)))) : (explicit-expression (node-line (node-identifier 1) (transition (character 2)) - > (node-identifier a l p h a) (transition (character 4)) - > (node-identifier a l p h a)) , (node-line (node-identifier b e t a) (transition (character 3)) - > (node-identifier b e t a))))")

test("test-parser-1.rkt", ["10001111", "0001", "10", "1111"], "#t #t #f #t")

test("test-basic-string.rkt", ["banana", "", "a", "bananas"], "#t #f #f #f")

if failures == 0:
    print("All Tests Passed (" + str(passes) + ").")
else:
    print("Some Tests Failed. Failures: " + str(failures) + ", Passes: " + str(passes) + ".")
