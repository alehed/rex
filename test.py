
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
    output = subprocess.check_output(call)
    if output != expected_output + "\n":
        failures += 1
        print("[Failed] in: " + string.join(call))
        print("\tExpected: " + expected_output + "\n\tBut got: " + output)
    else:
        passes += 1
        if verbose:
            print("[Passed] in: " + string.join(call) +  "\n")

test("test-tokenizer.rkt", ["tester"], "#f")

#test("test-tokenizer.rkt", ["-t"], "")

if failures == 0:
    print("All Tests Passed")
else:
    print("Some Tests Failed. Failures: " + str(failures) + ", Passes: " + str(passes) + ".")
